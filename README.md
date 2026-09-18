# CIS Benchmark Level 1 Hardening — Chef + Terraform

Sample project implementing CIS Level 1 hardening for on-premises Windows and
Linux servers, using Chef Infra for remediation, Chef InSpec for compliance
verification, Terraform for on-prem provisioning (vSphere), and GitHub
Actions for CI/CD.

Full written guide (design decisions, rationale, command references,
runbooks): see `CIS_Level1_Chef_Terraform_Implementation_Guide.docx`
delivered alongside this project.

## Repository structure

```
.
├── .github/workflows/       CI (every PR) and deploy (merge to main) pipelines
├── chef/
│   ├── cookbooks/
│   │   ├── cis_level1/      CIS Level 1 hardening cookbook (Linux + Windows)
│   │   └── serverbuild/     Example EXISTING build cookbook — kept separate
│   │                        from cis_level1 on purpose; see docs/cis_project.md
│   ├── data_bags/
│   │   └── cis_exceptions/  Exception list (which nodes are exempt from a
│   │                        control, why, who approved it, review date)
│   ├── environments/        dev / production attribute overrides
│   └── roles/
├── terraform/
│   ├── modules/onprem_server/   Reusable vSphere VM + Chef bootstrap module
│   └── environments/production/ Environment-specific Terraform root
├── packer/                  Golden-image templates (optional pre-baked hardening)
└── docs/                    Project-specific supplementary notes
```

## Why `cis_level1` and `serverbuild` are separate cookbooks

CIS controls change on a different cadence than application build logic, are
reviewed by a different owner (security vs. platform team), and need to run
strictly *after* the build cookbook finishes. Keeping them as two cookbooks —
both included in the same run list — makes that ordering explicit:

```ruby
run_list "recipe[serverbuild]", "recipe[cis_level1]"
```

See section 2.3 of the full guide for the complete rationale.

## Quick start

```bash
# One-time local setup
curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-workstation

# Lint + test the CIS cookbook locally
cd chef/cookbooks/cis_level1
cookstyle .
kitchen test

# Upload to your Chef Server
berks install && berks upload
knife cookbook upload cis_level1

# Provision an on-prem server and bootstrap Chef via Terraform
cd ../../../terraform/environments/production
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## CI/CD

- `.github/workflows/ci.yml` — runs on every pull request: cookstyle lint,
  Test Kitchen converge + verify, `terraform validate`.
- `.github/workflows/deploy.yml` — runs on merge to `main`: uploads the
  cookbook to the Chef Server, applies Terraform, and runs an InSpec
  compliance check against the fleet.

## License

Internal project template — adapt freely for your organization.
