# On-Prem Server Hardening — Solution Options (Windows & Linux)

This project provisions **on-premises vSphere VMs**, not cloud instances — there's
no AMI/managed-image marketplace to lean on, so "how does a new VM end up hardened"
has to be answered explicitly. Two options exist in this repo. Neither is
mandatory; the repo currently implements the first and leaves the second as an
optional path with placeholder templates.

---

## Option A — Live bootstrap (implemented, no Packer needed)

**How it works today**, per `terraform/modules/onprem_server/main.tf`:

```
Terraform clones template_uuid (a base, UNhardened OS image)
        │
        ▼
vsphere_virtual_machine created, boots, gets an IP
        │
        ▼
null_resource "chef_bootstrap" → knife bootstrap <ip> --ssh-user ... --sudo
        │
        ▼
chef-client installed + run_list 'recipe[serverbuild],recipe[cis_level1]' executed live
        │
        ▼
Node is hardened — same moment it's first reachable
```

One cookbook (`cis_level1`) is the single source of truth. Every VM gets whatever
version of the cookbook the Chef Server currently has, applied at creation time.

### Linux
Already fully wired up: `knife bootstrap` over **SSH**, using the `ssh_user` /
`ssh_key_path` variables already defined in
`terraform/modules/onprem_server/variables.tf`. Linux vSphere templates almost
always ship with SSH enabled by default, so there's no chicken-and-egg problem —
Terraform can reach the VM the moment it boots.

### Windows
**Not actually wired up yet**, even though `cis_level1` has Windows recipes
(`windows_password_policy`, `windows_rdp`, `windows_audit_policy`). The gap:
`knife bootstrap` needs **WinRM**, not SSH, to reach a Windows node — and the
current Terraform module only exposes `ssh_user` / `ssh_key_path`. Two things
would need to be added before this path works for Windows:

1. WinRM must already be enabled on the base template (Windows doesn't turn it on
   by default) — itself a security-relevant setting worth hardening *after*
   bootstrap, not before.
2. The Terraform module needs `winrm_user` / `winrm_password` variables and a
   `knife bootstrap windows winrm` command in place of the current SSH one.

### Trade-offs

| | Pros | Cons |
|---|---|---|
| Linux | Simple, already implemented, SSH just works | Brief window where the VM is unhardened between boot and the chef-client run completing |
| Windows | Same simplicity *if* built out | Same exposure window, but longer (Windows boots + WinRM handshake + a full chef-client run all take noticeably longer than Linux) — and WinRM itself has to be pre-enabled, which is a bootstrap-ordering problem Linux doesn't have |

---

## Option B — Golden image via Packer (optional, currently placeholders)

`packer/linux-hardened.pkr.hcl` and `packer/windows-hardened.pkr.hcl` both exist
but are stubs — the vCenter connection block is a comment
(`# ... vCenter connection + ISO boot config specific to your vSphere setup ...`).
The intent: run `chef-solo` with the same `serverbuild` → `cis_level1` run-list
**once, against a template**, so every VM Terraform later clones from it is already
compliant the instant it exists — no bootstrap window at all.

```
Packer boots a fresh ISO install
        │
        ▼
chef-solo provisioner runs 'recipe[serverbuild],recipe[cis_level1]'
        │
        ▼
Template is hardened, sysprepped/cleaned, saved back to vSphere
        │
        ▼
Terraform's template_uuid now points at an ALREADY-hardened image
(the null_resource/knife bootstrap step in Option A becomes optional or verify-only)
```

### Linux
Straightforward to finish: Packer's `vsphere-iso` builder talks to the new VM over
SSH during the build, same as the live-bootstrap path — no new protocol to
configure.

### Windows
More involved to finish, and this is the real reason Packer is worth considering
for Windows specifically even if you skip it for Linux:
- Needs an `Autounattend.xml` to drive the unattended Windows install.
- Needs a WinRM communicator block (temporary admin credentials during the build,
  since nothing is configured on a bare ISO boot yet).
- Windows ISO installs + updates + `chef-solo` + sysprep make Windows Packer builds
  **considerably slower** than Linux ones — expect this to be a batch/scheduled
  build, not something run on every commit.

### Trade-offs

| | Pros | Cons |
|---|---|---|
| Both OSes | Template is compliant *at rest* — zero exposure window; works even if someone clones the template outside this Terraform pipeline; hardening is testable as a versioned artifact | Extra artifact to rebuild and re-version every time `cis_level1` changes; needs its own build pipeline (not currently in `ci.yml`/`deploy.yml`) |
| Windows specifically | Sidesteps the WinRM chicken-and-egg problem — WinRM only needs to be reachable *during the Packer build*, not on every fresh clone | Slowest, most complex piece to set up correctly (unattended install file, WinRM communicator, sysprep) |
| Linux specifically | Cheap to finish — reuses the same SSH bootstrap logic Packer already knows how to do | Least necessary — Linux's live-bootstrap window is already short, so the marginal benefit is smaller |

---

## Recommendation

- **Linux: keep Option A (live bootstrap).** It's already implemented, the
  exposure window is short, and finishing Packer for Linux buys comparatively
  little.
- **Windows: Option A needs the WinRM wiring above before it works at all** —
  that's the near-term task, regardless of Packer. Once that exists, **consider
  Packer as an upgrade, not a requirement** — it removes the WinRM
  chicken-and-egg problem and the longer Windows exposure window, at the cost of
  an extra build pipeline to maintain.
- Don't feel obligated to pick one approach for both OSes — Option A for Linux and
  Option B for Windows is a reasonable split, since the trade-offs land
  differently per platform.

Neither option requires cloud infrastructure — both are designed around vSphere,
consistent with these being on-prem servers.
