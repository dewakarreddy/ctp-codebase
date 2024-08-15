package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/gcp"
  "github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/stretchr/testify/assert"
)

func TestTerraformGCP(t *testing.T) {
  t.Parallel()

  terraformOptions := &terraform.Options{
    // The path to where your Terraform code is located
    TerraformDir: "../",

    // Variables to pass to our Terraform code using -var options
    Vars: map[string]interface{}{
      "project_id": "YOUR_PROJECT_ID",
    },
  }

  // Clean up resources with "terraform destroy" at the end of the test
  defer terraform.Destroy(t, terraformOptions)

  // Run "terraform init" and "terraform apply". Fail the test if there are any errors.
  terraform.InitAndApply(t, terraformOptions)

  // Example of verifying VPC
  vpcName := terraform.Output(t, terraformOptions, "vpc_network_name")
  assert.Equal(t, "my-vpc", vpcName)

  // Example of verifying Subnet
  subnetName := terraform.Output(t, terraformOptions, "subnet_name")
  assert.Equal(t, "my-subnet", subnetName)

  // Add more checks as necessary
}
