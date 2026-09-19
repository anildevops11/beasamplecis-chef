# CIS Level 1 Hardening Pipeline — Runbook

Every tool in this repository, what it's for, what has to be installed or configured
before it will run, and where each one sits in the flow from a Chef recipe on your
laptop to a compliance report from the fleet.

Repo: `anildevops11/beasamplecis-chef` (branch `main`)

---

## The pipeline in four phases

| Phase | When | Tools |
|---|---|---|
| 1. Author & test | local, on your laptop | Chef Workstation, Test Kitchen, InSpec |
| 2. CI validates | every pull request | Cookstyle lint, Kitchen converge, `terraform validate` |
| 3. Build golden image *(optional)* | on demand | Packer + vSphere ISO, chef-solo |
| 4. Deploy & verify | on merge to `main` | Upload to Chef Server, `terraform apply`, InSpec on fleet |

---

## 0.0 Prerequisites & accounts

| Prerequisite | Needed for | Status |
|---|---|---|
| GitHub repo | Hosting the code, running CI/Deploy | ✅ done — pushed |
| Chef Server (hosted or self-managed) | `deploy.yml` cookbook upload, real node runs | ❌ not set up |
| vCenter / ESXi access | Terraform provisioning, Packer image builds | ❌ not set up |
| AWS S3 bucket + DynamoDB table | Terraform remote state (`backend.tf`) | ❌ not set up |
| GitHub repo secrets | `deploy.yml` credentials | ❌ none added |

You don't need all five to start — Stages 1–3 run with nothing but a laptop and free
tooling. The Chef Server, vCenter, and AWS state backend only become mandatory at
Stage 7, when `deploy.yml` tries to touch real infrastructure.

---

## 1.0 Author the cookbook — required

The hardening logic lives in `chef/cookbooks/cis_level1/recipes/*.rb` — five Linux
recipes (filesystem, ssh, password policy, auditd, sysctl) and three Windows recipes
(password policy, RDP, audit policy), selected by `node['platform_family']`.

**Chef Workstation** bundles everything you write/lint cookbooks with: `chef-client`,
`cookstyle` (linter), `berks` (dependency manager), `knife` (Chef Server client),
`kitchen`, and `inspec` — one install instead of five.

```powershell
# Windows — run in an elevated PowerShell
choco install chef-workstation -y
# or download the MSI: https://community.chef.io/tools/chef-workstation
```

**Cookstyle** — Ruby-style linter tuned for Chef resources. This is the first check
`ci.yml` runs on every pull request.

```bash
cd chef/cookbooks/cis_level1
cookstyle .
```

**Berkshelf (berks)** — resolves the cookbook's dependencies. `Berksfile` pulls
`windows`, `windows-security-policy`, and `audit` from Chef Supermarket. Run this any
time `metadata.rb` changes.

```bash
cd chef/cookbooks/cis_level1
berks install
```

---

## 2.0 Test locally, before opening a PR — required

Converge the cookbook against a throwaway VM and assert the result with InSpec — the
same two steps CI repeats afterward on its own runner.

**Test Kitchen** — `kitchen.yml` targets three platforms (`ubuntu-22.04`, `centos-9`,
`windows-2022`) via `provisioner: chef_zero` — **no real Chef Server involved**, it's a
local, throwaway Chef run. The default `driver: vagrant` needs Vagrant + VirtualBox
(heavy on Windows with Hyper-V active); swapping to the `kitchen-docker` gem avoids a
hypervisor entirely for the Linux suites.

```bash
cd chef/cookbooks/cis_level1
kitchen test --destroy=always
```

**Chef InSpec** — asserts the hardening actually took.
`test/integration/controls/linux_ssh_spec.rb` checks `MaxAuthTries`,
`PermitRootLogin`, and that `/tmp` is mounted `noexec,nosuid,nodev`. Kitchen calls
this automatically during `kitchen verify`.

---

## 3.0 Continuous integration — every pull request

Runs entirely on a GitHub-hosted runner (`.github/workflows/ci.yml`, triggers on
`pull_request` into `main`) — nothing needs to be installed locally just to see it
pass.

| Step | Command | Needs secrets? |
|---|---|---|
| Lint | `cookstyle chef/cookbooks/cis_level1` | no |
| Converge + verify | `kitchen test --destroy=always` | no |
| Terraform check | `terraform fmt -check -recursive` · `terraform init -backend=false` · `terraform validate` | no |

`-backend=false` is the detail that keeps this job secret-free — it skips talking to
the S3 state backend entirely, so CI validates Terraform's syntax without needing AWS
credentials.

---

## 4.0 Golden image build — optional path

`packer/linux-hardened.pkr.hcl` and `windows-hardened.pkr.hcl` bake `serverbuild` then
`cis_level1` into a template *before* it's cloned, via a `chef-solo` provisioner,
instead of hardening after every clone.

Not required for the Terraform path to work — `onprem_server` clones an existing
template and hardens it live via `knife bootstrap` (Stage 5). Use Packer only if you
want hardening compiled into the template itself.

```powershell
# Windows — run in an elevated PowerShell
choco install packer -y
packer init packer/linux-hardened.pkr.hcl
packer build packer/linux-hardened.pkr.hcl
```

---

## 5.0 Provision the VM — required for a real deploy

`terraform/modules/onprem_server` clones `template_uuid` into a
`vsphere_virtual_machine`, then a `null_resource` runs `knife bootstrap` over SSH
against its new IP — installing chef-client and applying
`run_list 'recipe[serverbuild],recipe[cis_level1]'` in one pass.

**Terraform** — already installed on this laptop (v1.14.9). The `hashicorp/vsphere`
provider needs a live vCenter to plan or apply against — not just for syntax checking,
which is all Stage 3 does.

```bash
cd terraform/environments/production
cp terraform.tfvars.example terraform.tfvars   # fill in real IDs — never commit this file
export TF_VAR_vsphere_password='...'
terraform init      # talks to the S3 backend — needs AWS creds too
terraform plan -out=tfplan
terraform apply tfplan
```

> **Two infra dependencies hide in this one step**: vCenter for the VM itself, *and*
> an AWS S3 bucket + DynamoDB table (`backend.tf`) for Terraform's state file and lock
> — both have to exist before `terraform init` will succeed here.

---

## 6.0 Configuration management — required for a real deploy

The Chef Server side: where the cookbook, roles, environments, and exception list
actually live once you're past local testing.

| Artifact | Path | Purpose |
|---|---|---|
| Role | `chef/roles/web_server.json` | run_list: `serverbuild` then `cis_level1`, in that order — never reversed |
| Environment | `chef/environments/production.rb` | pins `cis_level1 = 1.0.0` in production |
| Exception data bag | `chef/data_bags/cis_exceptions/` | per-control exemptions — node, reason, approver, review date |

```bash
# seed the exceptions data bag once, before the first production run
knife data bag create cis_exceptions
knife data bag from file cis_exceptions ssh_root_login.json
```

---

## 7.0 Continuous deployment — on merge to main

`.github/workflows/deploy.yml` — three sequential jobs, each depending on the last
succeeding.

| Job | Does | Reads secret |
|---|---|---|
| upload-cookbook | `berks upload` · `knife cookbook upload cis_level1` | `CHEF_KNIFE_RB`, `CHEF_CLIENT_PEM` |
| terraform-apply | `terraform init` · `terraform apply -auto-approve` | `VSPHERE_PASSWORD` |
| compliance-check | `inspec exec` against `dev-sec/cis-dil-benchmark`, uploads the JSON report as a build artifact | `FLEET_TARGET` |

**Current state, this repo:** Deploy already ran once automatically (triggered by the
push that added the implementation-guide doc) and failed at `upload-cookbook` —
expected, since none of the four secrets above are set yet. That's the correct failure
mode for a scaffold with no real Chef Server behind it.

---

## 8.0 Compliance verification

The last job in `deploy.yml` runs the public `dev-sec/cis-dil-benchmark` InSpec
profile over SSH against `FLEET_TARGET`, plus this repo's own custom controls
(`test/integration/controls/`), and archives the JSON result as a downloadable build
artifact — a compliance report per deploy, not just a pass/fail.

---

## 9.0 Secrets & config checklist

Everything `deploy.yml` is currently missing, in the order it will fail on them.

| Name | Where it's set | Value |
|---|---|---|
| `CHEF_KNIFE_RB` | GitHub → Settings → Secrets → Actions | contents of a working `knife.rb` |
| `CHEF_CLIENT_PEM` | GitHub → Settings → Secrets → Actions | the Chef client's private key |
| `VSPHERE_PASSWORD` | GitHub → Settings → Secrets → Actions | vSphere service-account password |
| `FLEET_TARGET` | GitHub → Settings → Secrets → Actions | SSH host of a node to run InSpec against |
| `terraform.tfvars` | local file, gitignored, never committed | real `resource_pool_id`, `datastore_id`, `network_id`, `template_uuid` |
| S3 bucket + DynamoDB table | AWS, referenced by `backend.tf` | `acme-terraform-state` / `terraform-locks` — rename to your own |

Set these directly on GitHub's secrets page rather than pasting credential material
into a chat session — secrets pasted into conversation history don't get cleaned up
the way a proper secret store does.

---

## 10.0 This laptop, right now

What's already on this machine versus what Stages 1–5 above assume.

| Tool | Status | Used at stage |
|---|---|---|
| Git | ✅ installed, repo pushed | 1.0 |
| Terraform | ✅ v1.14.9 installed | 5.0 |
| Chocolatey | ✅ v2.7.1 installed | installer for the rest |
| Chef Workstation | ❌ not installed | 1.0, 2.0, 6.0 |
| Docker Desktop | ❌ not installed | 2.0 (Docker driver alt) |
| Vagrant + VirtualBox | ❌ not installed | 2.0 (default driver) |
| Packer | ❌ not installed | 4.0 |
| GitHub CLI (gh) | ❌ not installed | optional — repo/secrets from terminal |
| Admin shell | ⚠️ current shell is non-elevated | needed for choco/system installs |

---

## 11.0 Running this without real vSphere or a Chef Server

Three substitutes, roughly in order of effort.

1. **chef_zero — already the default.** `kitchen.yml` already sets
   `provisioner: chef_zero`, meaning Test Kitchen never talks to a real Chef Server. A
   real server is only required for Stage 6/7 — uploading the cookbook so a *fleet* of
   nodes can pull it centrally. Nothing to set up.

2. **kitchen-docker driver.** Replaces `driver: vagrant` for the Linux suites — Docker
   Desktop instead of VirtualBox + nested virtualization, which is often the friction
   point on a Windows laptop with Hyper-V already enabled. The `windows-2022` suite
   can't run this way and stays on Vagrant, or gets tested in CI only.

3. **vcsim (govmomi vCenter simulator).** A single Go binary that fakes enough of the
   vSphere API for `terraform plan`/`apply` to succeed against the
   `hashicorp/vsphere` provider — no ESXi host, no vCenter license, no Docker even,
   once Go itself is installed.
