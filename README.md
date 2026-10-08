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

---

# Oracle Database Free on EC2

[`oracle-ec2/`](oracle-ec2/) builds one EC2 instance running **Oracle AI Database 26ai Free**
(the free edition, formerly "23ai Free") with the classic **SCOTT** schema (`EMP`, `DEPT`).

| | |
|---|---|
| OS | AlmaLinux 9 (RHEL 9-compatible; Oracle supports RHEL 9) |
| Size | `t3.small` — 2 GB RAM, Oracle's minimum; AWS lists it as free-tier-eligible in us-east-1 |
| Disk | 30 GB gp3, encrypted (free tier covers 30 GB) |
| Access | SSH key written to `~/.ssh/docman-oracle.pem`; ports 22 and 1521 open **only to your IP** |
| Database | CDB `FREE`, PDB `FREEPDB1`, listener on 1521 |
| Users | `scott` / `Tiger1234` (variable `scott_password`); SYS password in `terraform output -raw sys_password` |

The install runs unattended at first boot and takes about **20 minutes** on a `t3.small`
(1.5 GB RPM download, then database creation).

## Build it

```sh
cd oracle-ec2
terraform init
terraform apply
```

## Connect

1. **Log in to the server** (command is also in `terraform output ssh_command`):

   ```sh
   ssh -i ~/.ssh/docman-oracle.pem ec2-user@<public_ip>
   ```

2. **Wait for the install to finish** — done when this file exists:

   ```sh
   ls /var/log/oracle-setup.done          # exists = ready
   sudo tail -f /var/log/oracle-setup.log # or watch it work
   ```

3. **Connect to the database** as SCOTT (`sqlplus` is on the PATH for every login):

   ```sh
   sqlplus scott/Tiger1234@localhost/FREEPDB1
   ```

4. **Run the query**:

   ```sql
   SELECT COUNT(*) FROM emp;   -- 14
   SELECT COUNT(*) FROM dept;  --  4
   ```

Admin access: `sudo su - oracle` then `sqlplus / as sysdba` (no password, OS authentication).
From your own machine with an Oracle client: `terraform output remote_connect_string`.

## Tear it down

```sh
terraform destroy
```

Nothing here is free forever: the instance bills by the hour once free-tier hours run out
(`t3.small` ≈ $0.50/day in us-east-1). Destroy it when you are done.
