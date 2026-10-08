# Docman-project

Hello-world Terraform pipeline: every push to `main` runs GitHub Actions, which
authenticates to AWS via OIDC and applies the Terraform in [`terraform/`](terraform/).
The result is an S3 bucket containing `hello-world.txt`.

## How it works

```
git push main ──▶ GitHub Actions ──(OIDC)──▶ AWS IAM role ──▶ terraform apply
                                                               │
                                       s3://docman-hello-world-<account>/hello-world.txt
```

| Piece | Where |
|---|---|
| Terraform code | [`terraform/`](terraform/) |
| Workflow | [`.github/workflows/terraform.yml`](.github/workflows/terraform.yml) |
| Remote state | `s3://docman-project-tfstate-<account>/hello-world/terraform.tfstate` |
| AWS auth | IAM role `github-actions-docman-project`, trusted for `repo:obaf/Docman-project:*` |

Pull requests run `plan` only; pushes to `main` (and manual **Run workflow**) also `apply`.

## One-time AWS setup

1. GitHub OIDC identity provider `token.actions.githubusercontent.com` in IAM.
2. IAM role `github-actions-docman-project` with a trust policy for that provider,
   limited to this repo, and S3 permissions for the hello-world and state buckets.
3. S3 bucket for Terraform state (versioning on, public access blocked).
4. GitHub repo secret `AWS_ROLE_ARN` = the role's ARN.

## Run locally

```sh
cd terraform
terraform init
terraform plan
```

Uses whatever AWS credentials are in your environment (`aws sts get-caller-identity` to check).
