# CIS Level 1 Project Notes

This file is the short, living project doc referenced from the README.
The full reference (rationale, command references, runbooks, control
mapping tables) lives in the delivered
`CIS_Level1_Chef_Terraform_Implementation_Guide.docx`.

## Existing server-build scripts — decision

Kept as a **separate cookbook** (`chef/cookbooks/serverbuild/`, a placeholder
in this sample repo) rather than merged into `cis_level1`. Both are included
in the same run list, build first, hardening second:

```
run_list "recipe[serverbuild]", "recipe[cis_level1]"
```

See section 2.3 of the full guide for the complete rationale (release
cadence, ownership, reusability, ordering safety).

## Open items

- [ ] Replace `chef/cookbooks/serverbuild/` with the organization's real
      build cookbook (or point existing roles at it instead of this
      placeholder).
- [ ] Fill in real vSphere connection details in `packer/*.pkr.hcl` and
      `terraform/environments/production/terraform.tfvars` (never commit
      the real `.tfvars`).
- [ ] Seed the Chef Server with the `cis_exceptions` data bag before the
      first production run:
      `knife data bag create cis_exceptions && knife data bag from file cis_exceptions ssh_root_login.json`
- [ ] Add Windows platform coverage to Test Kitchen once a Windows box/AMI
      is available for CI.
