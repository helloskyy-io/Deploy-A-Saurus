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
- **Stage 2 — built at deploy (per-VM):** the exact-pinned NVIDIA driver + CUDA,
  installed into the running clone by the `install_nvidia_driver` role
  (registered as a `runtime.post_deploy_role` below), reconciled on Day-2 by the
  same workflow.

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

| `post_deploy_var` | ← per-VM desired-state field | role-internal var (executor maps to) |
|---|---|---|
| `nvidia_driver` | `settings.nvidia_driver` (EXACT build, e.g. `570.158.01`) | `nvidia_driver_version` |
| `cuda` | `settings.cuda` (e.g. `12-8`) | (CUDA toolkit role/step) |

The executor MUST format-validate these as **untrusted input** (build-version
string, apt coordinate — not arbitrary text) before the install runs. The
`install_nvidia_driver` role installs the **exact pinned build** (NVIDIA CUDA
repo → `nvidia-driver-<series>` + apt pin 1001 + `apt-mark hold`; NEVER the
floating `-server` metapackage); the pin source is `settings.nvidia_driver`, NOT
a recipe constant. See the recipe's `runtime:` block comment for the full contract.

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

## Companion changes (mdc-ansible-collections, NOT this recipe PR)

The recipe leads; these executor-side changes land alongside the re-bake:

- `das_ubuntu_24_server_customer_workload.yml` re-modeled GPU-less (strip the
  NVIDIA/CUDA bake tasks).
- `conformance/tasks/customer-workload-server.yml` updated — relocate the GPU
  assertions out of the bake gate; assert the full §2-universal block.
