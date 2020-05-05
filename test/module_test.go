package test

import (
	"testing"
	"crypto/tls"
	"time"
	"strings"
	"strconv"

	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func Test(t *testing.T) {
	t.Parallel()

	fixtureFolder := "./fixture"

	// At the end of the test, clean up any resources that were created
	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		terraform.Destroy(t, terraformOptions)
	})

	// Deploy the example
	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := configureTerraformOptions(t, fixtureFolder)

		// Save the options so later test stages can use them
		test_structure.SaveTerraformOptions(t, fixtureFolder, terraformOptions)

		// This will init and apply the resources and fail the test if there are any errors
		terraform.InitAndApply(t, terraformOptions)
	})

	// Check the VPC and networking
	test_structure.RunTestStage(t, "validate_vpc", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		// AWS
		awsRegion := terraform.Output(t, terraformOptions, "aws_region") 
		awsAvailabilityZones := terraform.OutputList(t, terraformOptions, "aws_availability_zones") 
	
		vpcId := terraform.Output(t, terraformOptions, "vpc_id")
		vpc := aws.GetVpcById(t, vpcId, awsRegion)
		require.Equal(t, vpc.Id, vpcId)

		// Subnets
		subnets := aws.GetSubnetsForVpc(t, vpcId, awsRegion)
		//dynamic_subnets should create 1 private and 1 public subnet for each availability zone.
		require.Equal(t, len(awsAvailabilityZones) * 2, len(subnets))

		// public subnet
		publicSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
		require.Equal(t, len(awsAvailabilityZones), len(publicSubnetIds))
		for _, subnetId := range publicSubnetIds {
			// Verify if the network that is supposed to be public is really public
			assert.True(t, aws.IsPublicSubnet(t, subnetId, awsRegion))
		}

		// private subnet
		privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
		require.Equal(t, len(awsAvailabilityZones), len(privateSubnetIds))
		for _, subnetId := range privateSubnetIds {
			// Verify if the network that is supposed to be private is really private
			assert.False(t, aws.IsPublicSubnet(t, subnetId, awsRegion))
		}

	})

	// Check the S3 bucket for challenge storage
	test_structure.RunTestStage(t, "validate_s3", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		// S3 bucket
		s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")
		s3BucketRegion := terraform.Output(t, terraformOptions, "s3_bucket_region")

		aws.AssertS3BucketExists(t, s3BucketRegion, s3BucketName)
	})

	// Check the ElastiCache
	test_structure.RunTestStage(t, "validate_elasticache", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		elastiCacheId := terraform.Output(t, terraformOptions, "elasticache_cluster_id")
		require.Equal(t, "ctfd-cache-cluster", elastiCacheId)
	})

	// Check the RDS
	test_structure.RunTestStage(t, "validate_rds", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		awsRegion := terraform.Output(t, terraformOptions, "aws_region") 
		
		//rdsEndpointAddress := terraform.Output(t, terraformOptions, "rds_endpoint_address")
		rdsInstanceEndpointAddress := terraform.Output(t, terraformOptions, "rds_instance_endpoint")
		
		//rdsPassword := terraform.Output(t, terraformOptions, "rds_password")
		dbInstanceId := terraform.Output(t, terraformOptions, "rds_instance_id") 
		rdsPort := terraform.Output(t, terraformOptions, "rds_port") 

		rdsRetrievedAddress := aws.GetAddressOfRdsInstance(t, dbInstanceId, awsRegion)
		rdsRetrievedPort := aws.GetPortOfRdsInstance(t, dbInstanceId, awsRegion)

		assert.Equal(t, rdsRetrievedAddress, rdsInstanceEndpointAddress)
		rdsPortInt, err := strconv.ParseInt(rdsPort, 10, 64)
		if err == nil {
			assert.Equal(t, rdsRetrievedPort, rdsPortInt)
		} else {
			t.Errorf("Error converting RDS port to int: %v\n", err)
		}
	})

	// Check the Frontend
	test_structure.RunTestStage(t, "validate_frontend", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		// Frontend
		albDnsName := terraform.Output(t, terraformOptions, "lb_dns_name")

		// It can take a minute or so for the Instance to boot up, so retry a few times
		maxRetries := 30
		timeBetweenRetries := 5 * time.Second

		// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
		tlsConfig := tls.Config{}

		// Specify the text the EC2 Instance will return when we make HTTP requests to it.
		instanceText := "CTFd"
	
		// Verify that we get back a 200 OK that contains instanceText
		http_helper.HttpGetWithRetryWithCustomValidation(t, "http://" + albDnsName, &tlsConfig, maxRetries, timeBetweenRetries, func(statusCode int, body string) bool {
			return (statusCode == 200 || statusCode == 302) && strings.Contains(body, instanceText)
		})
	})
}

func configureTerraformOptions(t *testing.T, fixtureFolder string) *terraform.Options {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: fixtureFolder,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{},
	}

	return terraformOptions
}
