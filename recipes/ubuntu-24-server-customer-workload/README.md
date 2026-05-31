# ubuntu-24-server-customer-workload (DAS recipe)

FluxCore-**free** GPU node template for Flux Edge (and future customer GPU
workloads). Class: `customer-workload-server` (DAS Template Standard §1 +
Appendix C).

## What it bakes

- Ubuntu 24.04 LTS (same cloud image as `ubuntu-24-server-base`)
- NVIDIA driver series **570** (`nvidia-driver-570-server`)
- CUDA toolkit **12-8** (confirm the exact apt coordinate against the live
  FluxCore install guide — phase doc Open decision #2)
- `qemu-guest-agent` (guest-agent IP discovery + the cloud-init readiness barrier)
- the platform ansible key via cloud-init (so the worker can SSH in to install
  FluxCore live post-clone)

## What it deliberately does NOT bake

- **FluxCore** — installed live, per-VM, post-clone by the `flux_edge_install`
  role (NEVER-CLONE-AFTER-FLUXCORE). Appendix C §C.6's `no_vendor_agent_unit_files`
  conformance check fails the build if any `fluxcore|synaptron|browser-session`
  unit file is present.
- K3s / Calico / Tailscale — `customer-workload-server` is NOT a
  platform-substrate-server (Appendix C).

## Consumer

`DeployFluxEdgeNodeWorkflow` (skyy-command) clones this template per the DAS
Template Consumption Standard §3, retags net0 to VLAN 155, attaches the
dedicated GPU via PCIe passthrough, then installs FluxCore live.

## Bake playbook

`das_ubuntu_24_server_customer_workload.yml` (mdc-ansible-collections) — staged
alongside this recipe in the Flux Edge Phase 1 companion artifacts.
