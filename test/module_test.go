package test

import (
	"testing"
	"crypto/tls"
	"time"
	"strings"
	"strconv"

	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	dns_helper "github.com/gruntwork-io/terratest/modules/dns-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	aws_sdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/rds"
)

func TestAws(t *testing.T) {
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
		awsRegion := terraformOptions.Vars["aws_region"].(string)
		
		vpcId := terraform.Output(t, terraformOptions, "vpc_id")
		vpc := aws.GetVpcById(t, vpcId, awsRegion)
		require.Equal(t, vpc.Id, vpcId)

		// Subnets
		subnets := aws.GetSubnetsForVpc(t, vpcId, awsRegion)
		//dynamic_subnets should create 1 private and 1 public subnet for each availability zone.
		require.Equal(t, 3 * 2, len(subnets))

		// public subnet
		publicSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
		require.Equal(t, 3, len(publicSubnetIds))
		for _, subnetId := range publicSubnetIds {
			// Verify if the network that is supposed to be public is really public
			assert.True(t, aws.IsPublicSubnet(t, subnetId, awsRegion))
		}

		// private subnet
		privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
		require.Equal(t, 3, len(privateSubnetIds))
		for _, subnetId := range privateSubnetIds {
			// Verify if the network that is supposed to be private is really private
			assert.False(t, aws.IsPublicSubnet(t, subnetId, awsRegion))
		}

	})

	// Check the S3 bucket for challenge and log storage
	test_structure.RunTestStage(t, "validate_s3", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		awsRegion := terraformOptions.Vars["aws_region"].(string)

		// challenge bucket
		s3ChallengeBucketName := terraform.Output(t, terraformOptions, "challenge_bucket_id")
		aws.AssertS3BucketExists(t, awsRegion, s3ChallengeBucketName)
		// log bucket
		s3LogBucketName := terraform.Output(t, terraformOptions, "log_bucket_id")
		aws.AssertS3BucketExists(t, awsRegion, s3LogBucketName)

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

		awsRegion := terraformOptions.Vars["aws_region"].(string)
		
		rdsEndpointAddress := terraform.Output(t, terraformOptions, "rds_endpoint_address")
		rdsPort := terraform.Output(t, terraformOptions, "rds_port") 
		rdsId := terraform.Output(t, terraformOptions, "rds_id")

		rdsClient := aws.NewRdsClient(t, awsRegion)
		input := rds.DescribeDBClustersInput{DBClusterIdentifier: aws_sdk.String(rdsId)}
		dbClusters, err := rdsClient.DescribeDBClusters(&input)
		if err != nil {
			t.Errorf("Error getting rds info: %v\n", err)
		}
		rdsRetrievedEndpointAddress := aws_sdk.StringValue(dbClusters.DBClusters[0].Endpoint)
		assert.Equal(t, rdsRetrievedEndpointAddress, rdsEndpointAddress)

		rdsRetrievedPort := *dbClusters.DBClusters[0].Port
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
		
		// It can take a 10 minutes or so for the DNS to propagate, so retry a few times
		dnsQuery := dns_helper.DNSQuery{"A", albDnsName}
		maxRetries := 60
		timeBetweenRetries := 10 * time.Second
		_, err := dns_helper.DNSLookupAuthoritativeAllWithRetryE(t, dnsQuery, nil, maxRetries, timeBetweenRetries)
		if err != nil {
			t.Errorf("DNS for %s not propagated in time. Error: %v\n", albDnsName, err)
		}

		// Once DNS is propagated the service should be responsive, so we don't need to retry as much
		maxRetries = 5
		timeBetweenRetries = 5 * time.Second

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

func TestK3s(t *testing.T) {
	t.Parallel()

	fixtureFolder := "./k3s_fixture"

	// At the end of the test, clean up any resources that were created	
	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		terraform.Destroy(t, terraformOptions)
	})

	// Deploy the example
	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := configureTerraformOptionsK3s(t, fixtureFolder)

		// Save the options so later test stages can use them
		test_structure.SaveTerraformOptions(t, fixtureFolder, terraformOptions)

		// This will init and apply the resources and fail the test if there are any errors
		terraform.InitAndApply(t, terraformOptions)
	})


	// Check the Frontend
	test_structure.RunTestStage(t, "validate_frontend", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		// Frontend
		ctfdConnectionString := terraform.Output(t, terraformOptions, "ctfd_connection_string")

		maxRetries := 10
		timeBetweenRetries := 1 * time.Second

		// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
		tlsConfig := tls.Config{}

		// Specify the text the EC2 Instance will return when we make HTTP requests to it.
		instanceText := "CTFd"
	
		// Verify that we get back a 200 OK that contains instanceText
		http_helper.HttpGetWithRetryWithCustomValidation(t, ctfdConnectionString, &tlsConfig, maxRetries, timeBetweenRetries, func(statusCode int, body string) bool {
			return (statusCode == 200 || statusCode == 302) && strings.Contains(body, instanceText)
		})
	})
}

func configureTerraformOptions(t *testing.T, fixtureFolder string) *terraform.Options {

	// Pick a random AWS region to test in. This helps ensure your code works in all regions.
	//awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: fixtureFolder,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"aws_region":    "us-east-1",
  		},
	}
	return terraformOptions
}


func configureTerraformOptionsK3s(t *testing.T, fixtureFolder string) *terraform.Options {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: fixtureFolder,
	}
	return terraformOptions
}