AWS Disaster Recovery (DR) Simulation – RDS Multi‑AZ Failover & RTO Measurement

Overview
--------

`aws-dr-simulation` is a hands-on, infrastructure-as-code project that simulates a multi-AZ disaster recovery (DR) scenario on AWS. The repository demonstrates creating a small production-like environment using Terraform, deploying an application to Amazon ECS, and provisioning an Amazon RDS PostgreSQL database with Multi-AZ configuration. The goal is to validate recovery procedures, measure RTO/RPO, and provide runnable scripts and runbooks that recruiters or technical reviewers can evaluate.

Repository layout
-----------------

- `app/` : Simple Flask application used for simulation and health-checks.
- `scripts/` : Helper scripts to simulate failures and measure recovery time.
- `runbooks/` : Human-readable runbooks and initial assumptions for DR exercises.
- `*.tf` : Terraform configuration files (networking, IAM, ECS, RDS, ALB, etc.).
- `terraform.tfvars` : Variable overrides used during deployments.

Key features
------------

- Full Terraform-based AWS deployment, modularized across files for clarity.
- ECS service with a Dockerized Flask app and an Application Load Balancer.
- Amazon RDS PostgreSQL instance configured for Multi-AZ for high availability.
- Networking with private subnets for the database and public subnets for the ALB.
- Scripts to simulate AZ failure and measure recovery time (`scripts/`).

Prerequisites
-------------

- Local tools:
	- Terraform >= 1.0
	- AWS CLI configured with a profile that has permissions to create VPCs, ECS, RDS, IAM, ALB, and related resources.
	- Docker (for building the app image locally if testing locally)

- AWS account with sufficient service quotas (EC2, RDS, ECR, ECS).

Setup and deployment (step-by-step)
---------------------------------

1. Configure your AWS credentials and choose an AWS profile:

```powershell
aws configure --profile your-profile
```

2. Review and edit variables in `terraform.tfvars` to match your environment (region, environment name, DB username, etc.).

3. Initialize Terraform in the repository root:

```powershell
terraform init
```

4. Validate the plan and preview resources to be created:

```powershell
terraform plan -out tfplan
terraform show -json tfplan | less
```

5. Apply the Terraform plan to create resources:

```powershell
terraform apply "tfplan"
```

Notes about the RDS password
---------------------------

- The RDS master password is generated using the `random_password` resource in `database.tf` by default. RDS has password character restrictions: only printable ASCII characters are allowed, excluding `/`, `@`, `"`, and space. If you prefer to supply your own password, set `special = false` in the `random_password` resource or provide a secure password through `terraform.tfvars` (taking care not to commit secrets to source control).

Common Terraform commands during iteration
----------------------------------------

- Show the generated random password (for debugging only; be cautious with secrets):

```powershell
terraform state show random_password.db
```

- Force regeneration of the password resource and re-apply (useful after changing the allowed special characters):

```powershell
terraform apply -replace=random_password.db
terraform apply
```

Application details
-------------------

- The sample application in `app/` is a small Flask app that exposes a health endpoint used by the ALB and scripts. The `Dockerfile` in `app/` builds the container used by the ECS task definition.

- To run the application locally for testing, build and run the container:

```powershell
docker build -t dr-sim-app ./app
docker run -p 5000:5000 dr-sim-app
```

Disaster recovery simulations and scripts
----------------------------------------

- `scripts/simulate-az-failure.sh` — automates failure simulation steps (e.g., stops instances, manipulates routing) to emulate an AZ outage. Review the script before running; it may perform destructive actions.
- `scripts/measure-rto.sh` — measures the Recovery Time Objective by timing the restoration of the service and database connectivity.

Runbooks and assumptions
------------------------

- See `runbooks/initial-assumptions.md` for assumptions made about account limits, network setup, and expected behavior.
- The runbooks contain step-by-step manual procedures you would follow during an actual DR event; these are intentionally explicit for auditability and interview discussion.

Security and best practices
---------------------------

- Do not commit secrets: never check in `terraform.tfvars` containing passwords or sensitive values.
- Use encrypted secrets stores (AWS Secrets Manager or Terraform Cloud variables) for production workflows.
- Restrict IAM permissions to least privilege for the profile you use to deploy.
- Enable multi-AZ and automated backups for RDS to reduce RTO and RPO.

Testing and verification
------------------------

- After deployment, verify the following:
	- ALB health checks are passing and target group shows running tasks.
	- ECS tasks are in `RUNNING` state.
	- RDS instance is `Available` and `Multi-AZ` is `True` in the AWS Console.
	- Application responds on the ALB DNS name with a 200 status at `/health`.

Cleanup
-------

To tear down resources created by Terraform (be careful — this will delete data):

```powershell
terraform destroy
```

What to highlight for recruiters
-------------------------------

- Design decisions: explain why Multi-AZ RDS, private subnets for DB, and ALB + ECS for the app were chosen.
- Infrastructure-as-code: the full environment is reproducible with Terraform.
- Observability: scripts and runbooks for measuring RTO/RPO and simulating failures.
- Security awareness: password generation constraints, least-privilege considerations, and avoidance of committing secrets.

Next steps and extensions
-------------------------

- Add automated CI/CD for Terraform and Docker image builds (GitHub Actions or similar).
- Integrate AWS Secrets Manager for DB credentials and update Terraform to reference secrets.
- Add CloudWatch alarms and SNS notifications for automated alerting during DR tests.

Contact / Questions
-------------------

If you want changes to this document or a tailored walkthrough for an interview, open an issue or request specific edits.

The README was generated and placed at the repo root. Review it and tell me if you'd like a shorter executive summary or a more technical appendix.

