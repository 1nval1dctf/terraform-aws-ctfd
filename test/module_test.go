package test

import (
	"bufio"
	"crypto/tls"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	dns_helper "github.com/gruntwork-io/terratest/modules/dns-helper"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func FrontendTest(t *testing.T, ctfdConnectionString string, instanceText string) {

	maxRetries := 10
	timeBetweenRetries := 10 * time.Second

	// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
	tlsConfig := tls.Config{}

	// Verify that we get back a 200 OK that contains instanceText
	http_helper.HttpGetWithRetryWithCustomValidation(t, ctfdConnectionString, &tlsConfig, maxRetries, timeBetweenRetries, func(statusCode int, body string) bool {
		return (statusCode == 200) && strings.Contains(body, instanceText)
	})
}

func Setup(t *testing.T, ctfdConnectionString string) {
	postUrl := ctfdConnectionString + "/setup"
	ctfName := "Random CTF Name"

	jar, err := cookiejar.New(nil)
	client := &http.Client{Jar: jar}
	resp, err := client.Get(postUrl)
	require.Nil(t, err, err)
	require.Equal(t, resp.StatusCode, 200)

	scanner := bufio.NewScanner(resp.Body)
	csrfNone := ""
	for scanner.Scan() {
		vars := strings.Split(strings.Trim(scanner.Text(), "\t ,"), ":")
		if strings.Contains(vars[0], "'csrfNonce'") {
			csrfNone = strings.Trim(vars[1], " \"")
		}

	}

	values := make(url.Values)
	values.Set("ctf_name", ctfName)
	values.Set("user_mode", "teams")
	values.Set("name", "admin")
	values.Set("email", "admin@test.com")
	values.Set("password", "admin")
	values.Set("nonce", csrfNone)

	// Submit form
	resp, err = client.PostForm(postUrl, values)
	require.Nil(t, err, err)
	require.Equal(t, resp.StatusCode, 200)

	// Now check the setup has completed and we dont get redirected to /setup.
	FrontendTest(t, ctfdConnectionString, ctfName)
}

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
		require.Equal(t, 3*2, len(subnets))

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

	})

	// Check the Frontend
	test_structure.RunTestStage(t, "validate_frontend", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		// Frontend
		albDnsName := terraform.Output(t, terraformOptions, "lb_dns_name")
		ctfdConnectionString := terraform.Output(t, terraformOptions, "ctfd_connection_string")

		// It can take a 10 minutes or so for the DNS to propagate, so retry a few times
		dnsQuery := dns_helper.DNSQuery{"A", albDnsName}
		maxRetries := 60
		timeBetweenRetries := 10 * time.Second
		_, err := dns_helper.DNSLookupAuthoritativeAllWithRetryE(t, dnsQuery, nil, maxRetries, timeBetweenRetries)
		if err != nil {
			t.Errorf("DNS for %s not propagated in time. Error: %v\n", albDnsName, err)
		}

		FrontendTest(t, ctfdConnectionString, "setup-form")
		Setup(t, ctfdConnectionString)
	})

}

func TestDocker(t *testing.T) {
	t.Parallel()

	fixtureFolder := "./docker_fixture"

	// At the end of the test, clean up any resources that were created
	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		terraform.Destroy(t, terraformOptions)
	})

	// Deploy the example
	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := configureTerraformOptionsDocker(t, fixtureFolder)

		// Save the options so later test stages can use them
		test_structure.SaveTerraformOptions(t, fixtureFolder, terraformOptions)

		// This will init and apply the resources and fail the test if there are any errors
		terraform.InitAndApply(t, terraformOptions)
	})

	// Check the Frontend
	test_structure.RunTestStage(t, "validate_frontend", func() {
		// This doesn't work in CI, but in that case we know the value anyway
		//terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		//ctfdConnectionString := terraform.Output(t, terraformOptions, "ctfd_connection_string")
		ctfdConnectionString := "http://127.0.0.1:8080"

		FrontendTest(t, ctfdConnectionString, "setup-form")
		Setup(t, ctfdConnectionString)
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
			"aws_region": "us-east-1",
		},
	}
	return terraformOptions
}

func configureTerraformOptionsDocker(t *testing.T, fixtureFolder string) *terraform.Options {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: fixtureFolder,
	}
	return terraformOptions
}
