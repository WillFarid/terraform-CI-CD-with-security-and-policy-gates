# bootstrap

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.70 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.apply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.apply_iam](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.apply_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.plan_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.apply_power_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.plan_read_only](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.apply_iam](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.apply_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.plan_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trust_apply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trust_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | GitHub user or organization that owns the repository. | `string` | `"WillFarid"` | no |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | GitHub repository whose workflows may assume the roles. | `string` | `"terraform-CI-CD-with-security-and-policy-gates"` | no |
| <a name="input_mock_mode"></a> [mock\_mode](#input\_mock\_mode) | true = fake credentials and no calls to AWS (offline plan). false for a real deployment. | `bool` | `true` | no |
| <a name="input_project"></a> [project](#input\_project) | Project prefix. Must match the project name used by the environments, because the IAM permissions are scoped to resources starting with it. | `string` | `"three-tier"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region. | `string` | `"us-east-1"` | no |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Name of the S3 bucket that holds the Terraform state of dev and prod. | `string` | `"REPLACE-ME-tfstate-bucket"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_apply_role_arns"></a> [apply\_role\_arns](#output\_apply\_role\_arns) | Roles for terraform apply, keyed by environment. Store each as the variable AWS\_APPLY\_ROLE\_ARN inside the matching GitHub Environment. |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | ARN of the GitHub OIDC identity provider. |
| <a name="output_plan_role_arn"></a> [plan\_role\_arn](#output\_plan\_role\_arn) | Role for terraform plan. Store as the repository variable AWS\_PLAN\_ROLE\_ARN. |
<!-- END_TF_DOCS -->
