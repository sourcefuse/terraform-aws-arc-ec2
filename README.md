# [terraform-aws-arc-cicd](https://github.com/sourcefuse/terraform-aws-arc-cicd)

<a href="https://github.com/sourcefuse/terraform-aws-arc-cicd/releases/latest"><img src="https://img.shields.io/github/release/sourcefuse/terraform-aws-arc-cicd.svg?style=for-the-badge" alt="Latest Release"/></a> <a href="https://github.com/sourcefuse/terraform-aws-arc-cicd/commits"><img src="https://img.shields.io/github/last-commit/sourcefuse/terraform-aws-arc-cicd.svg?style=for-the-badge" alt="Last Updated"/></a> ![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white) ![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)


[![Quality gate](https://sonarcloud.io/api/project_badges/quality_gate?project=sourcefuse_terraform-aws-arc-cicd&token=b697edbb45222daad2f3184fdb06b908aec00460)](https://sonarcloud.io/summary/new_code?id=sourcefuse_terraform-aws-arc-cicd)

[![Known Vulnerabilities](https://github.com/sourcefuse/terraform-aws-arc-cicd/actions/workflows/snyk.yaml/badge.svg)](https://github.com/sourcefuse/terraform-aws-arc-cicd/actions/workflows/snyk.yaml)
## Overview

For more information about this repository and its usage, please see [Terraform AWS ARC GitHub CICD Module Usage Guide](https://github.com/sourcefuse/terraform-aws-arc-cicd/blob/main/docs/module-usage-guide/README.md).

## Introduction

SourceFuse's AWS Reference Architecture (ARC) Terraform module automates the creation of AWS CodePipeline and CodeBuild projects, facilitating the build and deployment of both application code and Terraform modules. By defining reusable CodeBuild projects, it ensures consistent and efficient build processes that can be shared across multiple CodePipelines. This approach promotes standardization and reduces redundancy in the CI/CD pipeline configuration.

### Prerequisites
Before using this module, ensure you have the following:

- AWS credentials configured.
- Terraform installed.
- A working knowledge of Terraform.

## Getting Started

1. **Define the Module**

Initially, it's essential to define a Terraform module, which is organized as a distinct directory encompassing Terraform configuration files. Within this module directory, input variables and output values must be defined in the variables.tf and outputs.tf files, respectively. The following illustrates an example directory structure:



```plaintext
billing/
|-- main.tf
|-- variables.tf
|-- outputs.tf
```


2. **Define Input Variables**

Inside the `variables.tf` or in `*.tfvars` file, you should define values for the variables that the module requires.

3. **Use the Module in Your Main Configuration**
In your main Terraform configuration file (e.g., main.tf), you can use the module. Specify the source of the module, and version, For Example

```hcl
module "pipelines" {
  source = "sourcefuse/arc-cicd/aws"

  artifacts_bucket    = local.artifacts_bucket
  codestar_connection = local.codestar_connection

  role_data          = local.role_data
  codebuild_projects = local.codebuild_projects
  codepipelines      = local.codepipeline_data
  chatbot_data       = local.chatbot_data

  tags = module.tags.tags
}
```

4. **Output Values**

Inside the `outputs.tf` file of the module, you can define output values that can be referenced in the main configuration. For example:

```hcl
output "chatbot_sns_arns" {
  description = "SNS topics created by AWS Chatbot"
  value       = module.example.chatbot_sns_arns
}


```

5. **.tfvars**

Inside the `.tfvars` file of the module, you can provide desired values that can be referenced in the main configuration. For example:

Edit the [locals.tf](./examples/application/locals.tf) file and provide desired values.  

`artifacts_bucket` -  S3 Bucket name where artifacts are stored

`codestar_connection` - Codestar connection for authenticating to Github

`role_data` - Details about Roles to be created for Codepipeline and Codebuild projects

`codebuild_projects` -  List of Codebuild projects to be created

`codepipelines` - Codepipelines to be created

`chatbot_data` - local.chatbot_data


```hcl
locals {

  environment_role = {
    dev = "arn:aws:iam::xxxx:role/example-dev-cicd-role"
  }

  branch_map = {
    dev = {
      terraform = "dev"
    }
    poc = {
      terraform = "stg"
    }
  }

  prefix              = "${var.namespace}-${var.environment}"
  codestar_connection = "Github-Connection"
  artifacts_bucket    = "${local.prefix}-pipeline-artifacts"

  policies = [{
    policy_document = data.aws_iam_policy_document.pipeline.json
    policy_name     = "pipeline-policy-to-reject"
  }]

  chatbot_data = {
    name                     = "${var.namespace}-slack"
    slack_channel_id         = "C0xxxxxxx5"
    slack_workspace_id       = "T0xxxxxxRT"
    managed_policy_arns      = ["arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"]
    guardrail_policies       = ["arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"]
    role_polices             = local.policies
    enable_slack_integration = true
  }

  notification_event_and_type = {
    event_type_ids = [
      "codepipeline-pipeline-pipeline-execution-failed",
      "codepipeline-pipeline-pipeline-execution-canceled",
      "codepipeline-pipeline-pipeline-execution-started",
      "codepipeline-pipeline-pipeline-execution-resumed",
      "codepipeline-pipeline-pipeline-execution-succeeded",
      "codepipeline-pipeline-pipeline-execution-superseded",
      "codepipeline-pipeline-manual-approval-failed",
      "codepipeline-pipeline-manual-approval-needed"
    ]
    targets = [{
      address = "arn:aws:chatbot::${data.aws_caller_identity.current.account_id}:chat-configuration/slack-channel/${var.namespace}-slack" // it should match chatbot_data.name
      type    = "AWSChatbotSlack"                                                                                                         // Type can be "SNS" , AWSChatbotSlack etc
    }]
  }

  // IAM roles has to be created before creating Codebuild project and Codepipeline
  role_data = {
    "${local.prefix}-codepipeline-role" = {
      pipeline_service                    = "codepipeline"
      assume_role_arns                    = []
      github_secret_arn                   = null
      terraform_state_s3_bucket           = null
      dynamodb_lock_table                 = null
      additional_iam_policy_doc_json_list = []
    },
    "${local.prefix}-codebuild-terraform" = {
      pipeline_service                    = "codebuild"
      assume_role_arns                    = [local.environment_role[var.environment], "arn:aws:iam::1111xxxx1111:role/example-management-mrr-role"]
      github_secret_arn                   = null
      terraform_state_s3_bucket           = "example-shared-services-terraform-state"
      dynamodb_lock_table                 = "example-shared-services-terraform-state-lock"
      additional_iam_policy_doc_json_list = []
    }
  }

  // Codebuild projects have to be created before creating Codepipelines
  codebuild_projects = {
    "${local.prefix}-terraform-plan" = {
      description       = "Codebuild project for Terraform Plan"
      build_type        = "Terraform"
      terraform_version = "terraform-1.8.3-1.x86_64"
      buildspec_file    = null
      role_data = {
        name = "${local.prefix}-codebuild-terraform"
      }
      artifacts_bucket    = local.artifacts_bucket
      buildspec_file_name = "buildspec-tf-apply"
    },
    "${local.prefix}-terraform-apply" = {
      description       = "Codebuild project for Terraform Apply"
      build_type        = "Terraform"
      terraform_version = "terraform-1.8.3-1.x86_64"
      buildspec_file    = null
      role_data = {
        name = "${local.prefix}-codebuild-terraform"
      }
      artifacts_bucket    = local.artifacts_bucket
      buildspec_file_name = "buildspec-tf-apply"
    }
  }


  codepipeline_data = {
    "${local.prefix}-terrafomr-module" = {
      codestar_connection       = local.codestar_connection
      artifacts_bucket          = local.artifacts_bucket
      artifact_store_s3_kms_arn = null
      auto_trigger              = false

      source_repositories = [
        {
          name              = "TF-Source"
          output_artifacts  = ["tf_source_output"]
          github_repository = "githuborg/tf-mono-infra"
          github_branch     = local.branch_map[var.environment].terraform
          auto_trigger      = false
        }
      ]


      pipeline_stages = [
        {
          stage_name       = "Terraform-Plan"
          name             = "Terraform-Plan"
          input_artifacts  = ["tf_source_output"]
          output_artifacts = ["tf_plan_output"]
          version          = "1"
          project_name     = "${local.prefix}-terraform-plan" # This has to match the Codebuild project name
          environment_variables = [
            {
              name  = "ENVIRONMENT",
              value = var.environment
            },
            {
              name  = "TF_VAR_FILE",
              value = "tfvars/${var.environment}.tfvars"
            },
            {
              name  = "WORKING_DIR",
              value = "terraform/example-module"
            },
            {
              name  = "BACKEND_CONFIG_FILE",
              value = "backend/config.shared-services.hcl"
            },
            {
              name  = "WORKSPACE",
              value = var.environment
            }
          ]
        },
        {
          stage_name = "Approval"
          name       = "Approval"
          category   = "Approval"
          provider   = "Manual"
          version    = "1"
        },
        {
          stage_name       = "Terraform-Apply"
          name             = "Terraform-Apply"
          input_artifacts  = ["tf_plan_output"]
          output_artifacts = ["tf_apply_output"]
          version          = "1"
          project_name     = "${local.prefix}-terraform-apply" # This has to match the Codebuild project name
          environment_variables = [
            {
              name  = "ENVIRONMENT",
              value = var.environment
            },
            {
              name  = "TF_VAR_FILE",
              value = "tfvars/${var.environment}.tfvars"
            },
            {
              name  = "WORKING_DIR",
              value = "terraform/example-module"
            },
            {
              name  = "BACKEND_CONFIG_FILE",
              value = "backend/config.shared-services.hcl"
            },
            {
              name  = "WORKSPACE",
              value = var.environment
            }
          ]
        }
      ]
      role_data = {
        name = "${local.prefix}-codepipeline-role"
      }
      notification_data = {
        "${local.prefix}--api-notification" = local.notification_event_and_type // "${local.prefix}--api-notification" name has to be unique for each pipeline
      }
    }
  }

}

```

## First Time Usage
***uncomment the backend block in [main.tf](./example/main.tf)***
```shell
terraform init -backend-config=config.dev.hcl
```
***If testing locally, `terraform init` should be fine***

Create a `dev` workspace
```shell
terraform workspace new dev
```

Plan Terraform
```shell
terraform plan -var-file dev.tfvars
```

Apply Terraform
```shell
terraform apply -var-file dev.tfvars
```

## Production Setup
```shell
terraform init -backend-config=config.prod.hcl
```

Create a `prod` workspace
```shell
terraform workspace new prod
```

Plan Terraform
```shell
terraform plan -var-file prod.tfvars
```

Apply Terraform
```shell
terraform apply -var-file prod.tfvars  
```

## Cleanup  
Destroy Terraform
```shell
terraform destroy -var-file dev.tfvars
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.57.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ebs_volume.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_volume_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_iam_policy_document.ec2_ebs_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_ebs_volumes"></a> [additional\_ebs\_volumes](#input\_additional\_ebs\_volumes) | (optional) `ebs_block_device` block supports the following:<br>  name - (Optional) Name of the volume<br>  delete\_on\_termination - (Optional) Whether the volume should be destroyed on instance termination. Defaults to true.<br>  device\_name - (Required) Name of the device to mount.<br>  encrypted - (Optional) Enables EBS encryption on the volume. Defaults to false. Cannot be used with snapshot\_id. Must be configured to perform drift detection.<br>  iops - (Optional) Amount of provisioned IOPS. Only valid for volume\_type of io1, io2 or gp3.<br>  kms\_key\_id - (Optional) Amazon Resource Name (ARN) of the KMS Key to use when encrypting the volume. Must be configured to perform drift detection.<br>  snapshot\_id - (Optional) Snapshot ID to mount.<br>  tags - (Optional) Map of tags to assign to the device.<br>  throughput - (Optional) Throughput to provision for a volume in mebibytes per second (MiB/s). This is only valid for volume\_type of gp3.<br>  volume\_size - (Optional) Size of the volume in gibibytes (GiB).<br>  volume\_type - (Optional) Type of volume. Valid values include standard, gp2, gp3, io1, io2, sc1, or st1. Defaults to gp2.<br><br>  Device name : https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html | <pre>map(object({<br>    name                  = optional(string, null)<br>    delete_on_termination = optional(bool, true)<br>    device_name           = string<br>    encrypted             = optional(bool, false)<br>    iops                  = optional(string, null)<br>    kms_key_id            = optional(string, null)<br>    throughput            = optional(string, null)<br>    volume_size           = number<br>    volume_type           = optional(string, "gp2")<br><br>  }))</pre> | `{}` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | The AMI ID for the EC2 instance. | `string` | n/a | yes |
| <a name="input_assign_eip"></a> [assign\_eip](#input\_assign\_eip) | (optional) Whether to assign Elastic IP address, note `associate_public_ip_address` has to be enabled | `bool` | `false` | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | Associate a public IP address with the instance. | `bool` | `false` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | (optional) (Optional) If true, the launched EC2 instance will be EBS-optimized. Note that if this is not set on an instance type that is optimized by default then this will show as disabled but if the instance type is optimized by default then there is no need to set this and there is no effect to disabling it. | `bool` | `false` | no |
| <a name="input_enable_detailed_monitoring"></a> [enable\_detailed\_monitoring](#input\_enable\_detailed\_monitoring) | (optional) Whether to enable detailed monitoring | `bool` | `false` | no |
| <a name="input_enable_stop_protection"></a> [enable\_stop\_protection](#input\_enable\_stop\_protection) | (optional)  If true, enables EC2 Instance Stop Protection. | `bool` | `false` | no |
| <a name="input_enable_termination_protection"></a> [enable\_termination\_protection](#input\_enable\_termination\_protection) | (optional) If true, enables EC2 Instance Termination Protection. | `bool` | `false` | no |
| <a name="input_instance_metadata_options"></a> [instance\_metadata\_options](#input\_instance\_metadata\_options) | The metadata\_options block supports the following:<br><br>http\_endpoint - (Optional) Whether the metadata service is available. Valid values include enabled or disabled. Defaults to enabled.<br>http\_protocol\_ipv6 - (Optional) Whether the IPv6 endpoint for the instance metadata service is enabled. Defaults to disabled.<br>http\_put\_response\_hop\_limit - (Optional) Desired HTTP PUT response hop limit for instance metadata requests. The larger the number, the further instance metadata requests can travel. Valid values are integer from 1 to 64. Defaults to 1.<br>http\_tokens - (Optional) Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2 (IMDSv2). Valid values include optional or required. Defaults to optional.<br>instance\_metadata\_tags - (Optional) Enables or disables access to instance tags from the instance metadata service. Valid values include enabled or disabled. Defaults to disabled. | <pre>object({<br>    http_endpoint               = optional(string, "enabled")<br>    http_protocol_ipv6          = optional(string, "disabled")<br>    http_put_response_hop_limit = optional(number, 1)<br>    http_tokens                 = optional(string, "required")<br>    instance_metadata_tags      = optional(string, "disabled")<br>  })</pre> | <pre>{<br>  "http_endpoint": "enabled",<br>  "http_protocol_ipv6": "disabled",<br>  "http_put_response_hop_limit": 1,<br>  "http_tokens": "required",<br>  "instance_metadata_tags": "disabled"<br>}</pre> | no |
| <a name="input_instance_profile_data"></a> [instance\_profile\_data](#input\_instance\_profile\_data) | (optional) IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile. | <pre>object({<br>    name   = optional(string, null)<br>    create = optional(bool, false)<br>    policy_documents = optional(list(object({<br>      name   = string<br>      policy = string<br>    })), [])<br>    managed_policy_arns = optional(list(string), [])<br>  })</pre> | <pre>{<br>  "create": false,<br>  "managed_policy_arns": [],<br>  "name": null,<br>  "policy_documents": []<br>}</pre> | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type for EC2 instance | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the instance | `string` | n/a | yes |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | (optional) Private IP for the instance | `string` | `null` | no |
| <a name="input_root_block_device_data"></a> [root\_block\_device\_data](#input\_root\_block\_device\_data) | The root\_block\_device block supports the following:<br><br>delete\_on\_termination - (Optional) Whether the volume should be destroyed on instance termination. Defaults to true.<br>encrypted - (Optional) Whether to enable volume encryption. Defaults to false. Must be configured to perform drift detection.<br>iops - (Optional) Amount of provisioned IOPS. Only valid for volume\_type of io1, io2 or gp3.<br>kms\_key\_id - (Optional) Amazon Resource Name (ARN) of the KMS Key to use when encrypting the volume. Must be configured to perform drift detection.<br>tags - (Optional) Map of tags to assign to the device.<br>throughput - (Optional) Throughput to provision for a volume in mebibytes per second (MiB/s). This is only valid for volume\_type of gp3.<br>volume\_size - (Optional) Size of the volume in gibibytes (GiB).<br>volume\_type - (Optional) Type of volume. Valid values include standard, gp2, gp3, io1, io2, sc1, or st1. Defaults to the volume type that the AMI uses. | <pre>object({<br>    delete_on_termination = optional(bool, true)<br>    encrypted             = optional(bool, true)<br>    iops                  = optional(string, null)<br>    kms_key_id            = optional(string, null)<br>    throughput            = optional(number, null)<br>    volume_size           = string<br>    volume_type           = string<br>  })</pre> | n/a | yes |
| <a name="input_security_group_data"></a> [security\_group\_data](#input\_security\_group\_data) | (optional) Security Group data | <pre>object({<br>    create             = optional(bool, false)<br>    name               = optional(string, null)<br>    description        = optional(string, null)<br>    security_group_ids = optional(list(string))<br>    ingress_rules = optional(list(object({<br>      description      = optional(string, null)<br>      from_port        = string<br>      to_port          = string<br>      protocol         = string<br>      cidr_blocks      = list(string)<br>      security_groups  = optional(list(string), [])<br>      ipv6_cidr_blocks = optional(list(string), [])<br>    })))<br>    egress_rules = optional(list(object({<br>      description      = optional(string, null)<br>      from_port        = string<br>      to_port          = string<br>      protocol         = string<br>      cidr_blocks      = list(string)<br>      security_groups  = optional(list(string), [])<br>      ipv6_cidr_blocks = optional(list(string), [])<br>    })))<br>  })</pre> | n/a | yes |
| <a name="input_ssh_key_pair"></a> [ssh\_key\_pair](#input\_ssh\_key\_pair) | (optional) SSH Key Pair for EC2 instance | `string` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID on which EC2 instance has to be created | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (optional) Tags for EC2 instance | `map(string)` | `{}` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | (optional) User data to provide when launching the instance. Do not pass gzip-compressed data via this argument; see user\_data\_base64 instead. Updates to this field will trigger a stop/start of the EC2 instance by default. | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID where resources will be deployed. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | Instance ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

### Git commits

while Contributing or doing git commit please specify the breaking change in your commit message whether its major,minor or patch

For Example

```sh
git commit -m "your commit message #major"
```
By specifying this , it will bump the version and if you dont specify this in your commit message then by default it will consider patch and will bump that accordingly



## Development

### Prerequisites

- [terraform](https://learn.hashicorp.com/terraform/getting-started/install#installing-terraform)
- [terraform-docs](https://github.com/segmentio/terraform-docs)
- [pre-commit](https://pre-commit.com/#install)
- [golang](https://golang.org/doc/install#install)
- [golint](https://github.com/golang/lint#installation)

### Configurations

- Configure pre-commit hooks
  ```sh
  pre-commit install
  ```

### Tests
- Tests are available in `test` directory
- Configure the dependencies
  ```sh
  cd test/
  go mod init github.com/sourcefuse/terraform-aws-refarch-<module_name>
  go get github.com/gruntwork-io/terratest/modules/terraform
  ```
- Now execute the test  
  ```sh
  go test -timeout  30m
  ```

## Authors

This project is authored by:
- SourceFuse
