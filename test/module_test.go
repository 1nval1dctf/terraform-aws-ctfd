package test

import (
	"crypto/tls"
	"fmt"
	"io/ioutil"
	"os"
	"os/user"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/service/cloudwatchlogs"
	"github.com/gruntwork-io/terratest/modules/aws"
	dns_helper "github.com/gruntwork-io/terratest/modules/dns-helper"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func DBTest(t *testing.T, kubectlOptions *k8s.KubectlOptions) {
	err := k8s.KubectlApplyE(t, kubectlOptions, "test-db-job.yml")
	if err != nil {
		t.Errorf("Failed to apply db-check job. Error: %v\n", err)
	}

	k8s.WaitUntilJobSucceed(t, kubectlOptions, "db-check", 180, 1*time.Second)
	k8s.KubectlDelete(t, kubectlOptions, "test-db-job.yml")
}

func CacheTest(t *testing.T, kubectlOptions *k8s.KubectlOptions) {
	err := k8s.KubectlApplyE(t, kubectlOptions, "test-cache-job.yml")
	if err != nil {
		t.Errorf("Failed to apply cache-check job. Error: %v\n", err)
	}

	k8s.WaitUntilJobSucceed(t, kubectlOptions, "cache-check", 180, 1*time.Second)
	k8s.KubectlDelete(t, kubectlOptions, "test-cache-job.yml")
}

func CTFdServiceTest(t *testing.T, kubectlOptions *k8s.KubectlOptions) {
	_, err := k8s.GetServiceE(t, kubectlOptions, "ctfd")
	if err != nil {
		t.Errorf("Error failed to get ctfd service: %v\n", err)
	}
	ctfd_pods := k8s.ListPods(t, kubectlOptions, metav1.ListOptions{LabelSelector: "service=ctfd"})
	for key := range ctfd_pods {
		err := k8s.WaitUntilPodAvailableE(t, kubectlOptions, ctfd_pods[key].Name, 60, 1*time.Second)
		require.NoError(t, err)
	}
}

func MetricsServerTest(t *testing.T, kubectlOptionsKubeSystem *k8s.KubectlOptions) {
	_, err := k8s.GetServiceE(t, kubectlOptionsKubeSystem, "metrics-server")
	if err != nil {
		t.Errorf("Error failed to get metric-server service: %v\n", err)
	}
}

func NodeTest(t *testing.T, kubectlOptions *k8s.KubectlOptions) {
	_, err := k8s.GetReadyNodesE(t, kubectlOptions)
	if err != nil {
		t.Errorf("Error failed to get nodes: %v\n", err)
	}
}

func IngressTest(t *testing.T, kubectlOptions *k8s.KubectlOptions) {
	ingress, err := k8s.GetIngressE(t, kubectlOptions, "ctfd")
	if err == nil {
		assert.NotEqual(t, ingress, "")
	} else {
		t.Errorf("Error failed to get ingress: %v\n", err)
	}
}

func PvcTest(t *testing.T, kubectlOptions *k8s.KubectlOptions) {
	output, err := k8s.RunKubectlAndGetOutputE(t, kubectlOptions, "get", "pv")
	if err == nil {
		assert.Contains(t, output, "ctfd-logs-claim")
		assert.Contains(t, output, "ctfd-uploads-claim")
		for _, line := range strings.Split(strings.TrimSuffix(output, "\n"), "\n") {
			if strings.Contains(line, "ctfd-logs-claim") || strings.Contains(line, "ctfd-uploads-claim") {
				assert.Contains(t, line, "Bound")

			}
		}
	} else {
		t.Errorf("Error failed to get persistent volumes: %v\n", err)
	}

	output, err = k8s.RunKubectlAndGetOutputE(t, kubectlOptions, "get", "pvc", "ctfd-logs-claim")
	if err == nil {
		assert.Contains(t, output, "Bound")
	} else {
		t.Errorf("Error failed to get ctfd-logs-claim persistent volume claim: %v\n", err)
	}

	output, err = k8s.RunKubectlAndGetOutputE(t, kubectlOptions, "get", "pvc", "ctfd-uploads-claim")
	if err == nil {
		assert.Contains(t, output, "Bound")
	} else {
		t.Errorf("Error failed to get ctfd-uploads-claim persistent volume claim: %v\n", err)
	}
}

func HpaTestRetryE(t *testing.T, kubectlOptions *k8s.KubectlOptions, hpa string) {
	maxRetries := 30
	retryDuration, _ := time.ParseDuration("10s")
	_, err := retry.DoWithRetryE(t, "Get hpa", maxRetries, retryDuration,
		func() (string, error) {
			output, err := k8s.RunKubectlAndGetOutputE(t, kubectlOptions, "get", "hpa", hpa)
			if err == nil {
				// "<unknown> in TARGETS means that the hpa or metrics-server is not working correctly"
				if strings.Contains(output, "<unknown>") {
					return "failed to get target metrics", fmt.Errorf("failed to get target metrics for %v", hpa)
				} else {
					return "Retrieved metrics", nil
				}
			} else {
				return "failed to get target metrics", err
			}
		},
	)
	require.Nil(t, err, err)
}

func HpaTest(t *testing.T, kubectlOptions *k8s.KubectlOptions) {
	HpaTestRetryE(t, kubectlOptions, "ctfd")
	HpaTestRetryE(t, kubectlOptions, "ctfd-memory-scale")
}

func FrontendTest(t *testing.T, dnsName string) {

	maxRetries := 5
	timeBetweenRetries := 5 * time.Second

	// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
	tlsConfig := tls.Config{}

	// Specify the text that will be returned when we make HTTP requests to it.
	instanceText := "CTFd"

	// Verify that we get back a 200 OK that contains instanceText
	http_helper.HttpGetWithRetryWithCustomValidation(t, "http://"+dnsName, &tlsConfig, maxRetries, timeBetweenRetries, func(statusCode int, body string) bool {
		return (statusCode == 200 || statusCode == 302) && strings.Contains(body, instanceText)
	})
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
		// log bucket
		s3LogBucketName := terraform.Output(t, terraformOptions, "log_bucket_id")
		aws.AssertS3BucketExists(t, awsRegion, s3LogBucketName)

	})

	// validate services.
	test_structure.RunTestStage(t, "validate_services", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		kubeConfig := terraform.Output(t, terraformOptions, "kubeconfig")

		file, err := ioutil.TempFile(os.TempDir(), "kubeconfig-")
		require.NoError(t, err)

		if _, err = file.Write([]byte(kubeConfig)); err != nil {
			t.Errorf("Failed to write to temporary kubeconfig: %v\n", err)
		}

		kubectlOptions := &k8s.KubectlOptions{ConfigPath: file.Name(), Namespace: "default"}

		// Check the nodes
		NodeTest(t, kubectlOptions)

		// Check the pvc
		PvcTest(t, kubectlOptions)

		// Check the db is running
		DBTest(t, kubectlOptions)

		// Check redis connectivity
		CacheTest(t, kubectlOptions)

		// Check metric-server is running
		kubectlOptionsKubeSystem := &k8s.KubectlOptions{ConfigPath: file.Name(), Namespace: "kube-system"}
		MetricsServerTest(t, kubectlOptionsKubeSystem)

		// check ctfd service and pods are good.
		CTFdServiceTest(t, kubectlOptions)

		// Check the ingress
		_, err = k8s.GetServiceE(t, kubectlOptionsKubeSystem, "aws-load-balancer-webhook-service")
		if err != nil {
			t.Errorf("Error failed to get aws-load-balancer-webhook-service service: %v\n", err)
		}
		IngressTest(t, kubectlOptions)

		// check ctfd hpa is good.
		HpaTest(t, kubectlOptions)

		// check cloudwatch entries are being created
		ctfdPods := k8s.ListPods(t, kubectlOptions, metav1.ListOptions{LabelSelector: "service=ctfd"})
		logStreamPrefix := "from-fluent-bit-kube.var.log.containers." + ctfdPods[0].Name + "_default_frontend"
		logGroupName := "fluent-bit-cloudwatch"
		awsRegion := terraformOptions.Vars["aws_region"].(string)
		awsSession, err := aws.NewAuthenticatedSessionFromDefaultCredentials(awsRegion)
		if err != nil {
			t.Errorf("Error failed to authenticate to AWS: %v\n", err)
		}
		cw := cloudwatchlogs.New(awsSession)
		in := &cloudwatchlogs.DescribeLogStreamsInput{
			LogGroupName:        &logGroupName,
			LogStreamNamePrefix: &logStreamPrefix,
		}
		streams, err := cw.DescribeLogStreams(in)
		if err == nil {
			if len(streams.LogStreams) < 1 {
				t.Errorf("No log streams found: %v\n", err)
			}
			for key := range streams.LogStreams {
				strPointerValue := *streams.LogStreams[key].LogStreamName
				logs, err := aws.GetCloudWatchLogEntriesE(t, awsRegion, strPointerValue, logGroupName)
				if err != nil {
					t.Errorf("Error failed to get cloud watch entries for %s, error: %v\n", strPointerValue, err)
				} else {
					assert.Greater(t, len(logs), 0)
				}
			}
		} else {
			t.Errorf("Error failed to describe log streams: %v\n", err)
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

		FrontendTest(t, albDnsName)
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

	// Check the services
	test_structure.RunTestStage(t, "validate_services", func() {
		//terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		usr, err := user.Current()
		if err != nil {
			t.Errorf("Failed to get current user. Error: %v\n", err)
		}

		kubectlOptions := &k8s.KubectlOptions{ConfigPath: filepath.Join(usr.HomeDir, ".kube/k3s_config"), Namespace: "default"}
		kubecltOptionsKubeSystem := &k8s.KubectlOptions{ConfigPath: filepath.Join(usr.HomeDir, ".kube/k3s_config"), Namespace: "kube-system"}

		// Check the nodes
		NodeTest(t, kubectlOptions)

		// Check the metrics-server is running
		MetricsServerTest(t, kubecltOptionsKubeSystem)

		// Check the db is running
		DBTest(t, kubectlOptions)

		// Check redis connectivity
		CacheTest(t, kubectlOptions)

		// Check the pvc
		PvcTest(t, kubectlOptions)

		// Check the CTFd service is running
		CTFdServiceTest(t, kubectlOptions)

		// Check the Ingress is created
		IngressTest(t, kubectlOptions)

		// check ctfd hpa is good.
		HpaTest(t, kubectlOptions)
	})

	// Check the Frontend
	test_structure.RunTestStage(t, "validate_frontend", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		dnsName := terraform.Output(t, terraformOptions, "lb_dns_name")
		FrontendTest(t, dnsName)
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

func configureTerraformOptionsK3s(t *testing.T, fixtureFolder string) *terraform.Options {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: fixtureFolder,
	}
	return terraformOptions
}
