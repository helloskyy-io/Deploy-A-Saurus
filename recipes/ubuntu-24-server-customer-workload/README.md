# ubuntu-24-server-customer-workload (DAS recipe)

**GPU-less** Linux base for GPU-bearing customer-workload VMs (Flux Edge, future
Synaptron-on-VM, customer-browser-on-VM). Class: `customer-workload-server` (DAS
Template Standard §1 + Appendix C, two-stage rewrite `7852a70`).

## Two-stage model (why this base bakes no GPU)

Per the DAS Standard Two-Stage Model and DAS Template §C.4.1 / §C.8 (*template
what is consistent, build what is dynamic*), the NVIDIA driver/CUDA is the
platform's canonical **dynamic** attribute — it varies per-VM and changes over a
VM's life. So it is **built at deploy, NOT baked**:

- **Stage 1 — baked (this template):** the GPU-less base. §2 universals + the
  class base requirements only (root SSH + ansible key + qemu-guest-agent +
  swap-off + DHCP + cloud-init NoCloud). No NVIDIA driver, no CUDA, no
  container-toolkit, no vendor agent.
- **Stage 2 — built at deploy (per-VM):** the exact-pinned NVIDIA driver
  (`install_nvidia_driver`, registered as a `runtime.post_deploy_role` below) +
  the CUDA toolkit (a separate role — see the contract section), installed into
  the running clone and reconciled on Day-2 by the same workflow.

**One generic GPU-less base serves every GPU class** (docker-internal host, Flux
Edge / mining host, k3s-2 GPU node) — there is no `-fluxedge` GPU-baked variant.
Each VM's exact driver build comes from its own desired-state file.

## What it bakes

- Ubuntu 24.04 LTS — a clean `derive` from `ubuntu-24-server-base` (universal base)
- the §2 universals, inherited from the parent (cloud-init NoCloud,
  qemu-guest-agent, growpart, root + ansible key, swap-off, hardening,
  no-operator-users), + the class base delta (§C.8)

## What it deliberately does NOT bake

- **NVIDIA driver / CUDA / container-toolkit** — these are the **deploy-time
  delta** (§C.3 / §C.4.1 / §C.8), built per-VM from desired state, exact-pinned.
  Baking them re-creates the template-per-driver-version explosion and blocks
  per-VM driver divergence (the exact failure the two-stage model fixes).
- **Vendor agents** (FluxCore, Synaptron client, customer-browser session
  manager) — installed live, per-VM, post-clone by their consuming workflow
  (NEVER-CLONE-AFTER-INSTALL). Appendix C §C.6's `no_vendor_agent_unit_files`
  conformance check fails the build if any `fluxcore|synaptron|browser-session`
  unit file is present.
- K3s / Calico / Tailscale — `customer-workload-server` is NOT a
  `platform-substrate-server` (Appendix C).

## Derive model

`install_method: derive`, `derive_from: ubuntu-24-server-base@2.0.0`. Stage 1
clones the published universal base and applies only the class base delta — no
raw cloud-image fetch. **Lineage (binding, §5.4):** the parent is version-pinned;
when `ubuntu-24-server-base` publishes a new version, bump `derive_from` here and
rebuild (§5.2). Stage 1 fails loud with `DERIVE_PARENT_VERSION_MISMATCH` if the
pin does not match the published parent.

## Deploy-time build — producer/consumer contract

The recipe declares the **mechanism** (`runtime.post_deploy_roles` +
`post_deploy_vars`); the **values** come from the per-VM desired-state file (VM
Management §2). The contract the consumer (Django Phase 7) wires against:

| `post_deploy_var` | ← per-VM desired-state field | role that consumes it | Ansible extra_var the executor passes |
|---|---|---|---|
| `nvidia_driver` | `settings.nvidia_driver` (EXACT build, e.g. `570.158.01`; NEVER the bare series) | `install_nvidia_driver` (driver only) | `nvidia_driver_version` |
| `cuda` | `settings.cuda` (e.g. `12-8`, when `settings.gpu: true`) | CUDA-toolkit role — **TBD, does not exist yet** (see prerequisite below) | _TBD with the role_ |

The executor MUST format-validate these as **untrusted input** (build-version
string `^[0-9]+\.[0-9]+\.[0-9]+$`, apt coordinate `^[0-9]+-[0-9]+$` — not
arbitrary text) before the install runs; that validation is implemented
consumer-side (Django Phase 7), not in this recipe.

`install_nvidia_driver` is **driver-only** (its own role meta) and installs the
**exact pinned build** (NVIDIA CUDA repo → `nvidia-driver-<series>` + apt pin
1001 + `apt-mark hold`; NEVER the floating `-server` metapackage); the pin source
is `settings.nvidia_driver`, NOT a recipe constant. It consumes the extra_var
`nvidia_driver_version` (it asserts that var is defined and carries no pin of its
own), so the executor maps `settings.nvidia_driver → nvidia_driver_version`.

**Prerequisite (surfaced — NOT this PR):** `settings.cuda` and the `nvcc_present`
post-deploy assertion need a **CUDA-toolkit role** (one that installs `nvcc`).
No such role exists yet in `mdc-ansible-collections` — `install_nvidia_toolkit`
there is the NVIDIA **container** toolkit (the Docker GPU runtime), NOT the CUDA
toolkit. DAS Template §C.8 names "`install_nvidia_driver` installs driver + CUDA,"
which is imprecise against the driver-only role; this is flagged for the
architecture/PM3 session. `cuda` is declared now per the §C.8/§C.6.1 contract; it
goes live once a CUDA-toolkit role is authored and added to
`runtime.post_deploy_roles`.

## Conformance

Stage 2 bake conformance verifies the **GPU-less base** — the §2 universals + the
class base requirements + the binding `no_vendor_agent_unit_files` assertion. It
carries **no GPU assertion** (§C.6.1 — nothing GPU is baked). The GPU-stack
assertions carry `requires_post_deploy: true` in `tests/automated.yaml`, so the
bake gate skips them; they run **post-deploy** against the built clone (the
reconcile workflow's `verify_host_driver` step, LCM Phase 3), after
`install_nvidia_driver` has built the exact-pinned driver. The recipe-side spec
in `tests/automated.yaml` is kept 1:1 with the conformance role's
`tasks/customer-workload-server.yml` (§6.2).

## Consumer

`DeployFluxEdgeNodeWorkflow` (skyy-command) clones this template per the DAS
Template Consumption Standard §3, retags net0 to the workload VLAN, attaches the
dedicated GPU via PCIe passthrough, runs the deploy-time GPU build, then installs
FluxCore live.

## Companion changes (mdc-ansible-collections — BLOCKING prerequisites for re-bake)

The recipe leads; these executor-side changes in `mdc-ansible-collections` are
**blocking** — DAS Stage 2 will FAIL on every GPU-less bake until they land, so
do **not** re-bake this recipe until they merge (the recipe PR is the spec; these
make the executor match it):

- **`das_ubuntu_24_server_customer_workload.yml` re-modeled GPU-less** — strip the
  NVIDIA-570 / CUDA bake tasks AND the baked apt-pin file (`/etc/apt/preferences.d/`
  nvidia pin). If left in, the baked pin fights the deploy-time
  `install_nvidia_driver` pin on any VM whose `settings.nvidia_driver` ≠ the baked
  `570.158.01` (apt resolves the two preference files by filename order).
- **`conformance/tasks/customer-workload-server.yml` updated** — (a) relocate the
  five GPU assertions out of the bake gate (they fail on a GPU-less bake clone);
  (b) **add the full §2-universal block** — the executor today only asserts
  `qemu_guest_agent_active` + the GPU stack + `no_vendor_agent_unit_files`, so it
  is missing `swap_off`, `curl_installed`, `root_ssh_via_ansible_key`,
  `sudoers_no_requiretty`, `netplan_no_static_config`,
  `cloud_init_nocloud_datasource_active`, `qemu_guest_agent_enabled`,
  `no_operator_accounts_leaked` (the §6.4 layered block this recipe's
  `automated.yaml` now specs); (c) the post-deploy driver check should use
  `--query-gpu=driver_version` (hardware-level, matching this recipe's spec), not
  the software-only `--version`.

And the downstream **operator / pipeline** step (not a code change):

- **Re-bake + golden-template publish** — rebuild the GPU-less template and
  register the new VMID in `<desired-state>/vm/golden_templates/` once the two
  companions above land.
