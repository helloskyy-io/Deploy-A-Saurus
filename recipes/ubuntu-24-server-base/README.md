# Ubuntu 24 Server Base — Universal Base Template

## Purpose

The **universal base** template (DAS Template Standard §1, §5.4): a minimal
Ubuntu 24.04 LTS image that satisfies **only** the §2 Universal Requirements and
carries **zero** class-specific content. It is the `derive` parent for every
server class (`platform-substrate-server`, `customer-workload-server`).

A base-level fix (CVE, Ubuntu point-release, cloud-init contract change,
guest-agent injection) is made **here, in exactly one place**, and flows to all
descendants via one base rebuild + descendant rebuilds (§5.4 acceptance test).

> **Historical note (DAS Template Standard §1).** This recipe previously
> conflated the universal base with the `platform-substrate-server` class by
> baking K3s prerequisites (br_netfilter/overlay, K3s sysctls, tailscaled). Phase
> 7 stripped those into the additive derived `platform-substrate-server` recipe;
> what remains here is the §2-only universal base. Stripping the K3s prereqs is a
> breaking content change, so the re-modeled base publishes at **v2.0.0**.

## Build Steps

This recipe is declarative; the build steps live in the Ansible playbook
`das_ubuntu_24_server_base.yml` in
`mdc-ansible-collections/skyy_net/common/playbooks/`. It implements the §2
universal steps ONLY — delete the default `ubuntu` user, enable root SSH + bake
the platform ansible key, install qemu-guest-agent (enabled) + curl, disable
swap, pin cloud-init to NoCloud, confirm DHCP-only, cleanup + machine-id reset.
The K3s-prerequisite steps moved to the derived
`platform-substrate-server` recipe's `das_platform_substrate_server.yml`.

## Conformance

Stage 2 runs the §2-universal assertions against the test clone via the
conformance role's `tasks/universal-base.yml` in `mdc-ansible-collections`. The
assertion list is translated 1:1 into `tests/automated.yaml` in this directory.

Failure mode per Template Standard §6.3: any assertion failure surfaces as a
Stage 2 `ActivityResult` error with `error_code: <assertion-name>` and `details:`
containing stdout plus expected-vs-observed. Operator-debuggable.

## Base Image Provenance

Source URL and pinned checksum live in `recipe.yaml` under `base:` (single
source of truth). `install_method: cloud-image` — the universal base is the one
`cloud-image` root (§5.1); every other server class derives from it. Refresh
trigger: Template Standard §5.2.

## Template Credentials

The universal base ships with **no operator users**. The cloud image's default
`ubuntu` user is deleted at build time; root SSH is enabled and the platform
ansible pubkey is baked into `/root/.ssh/authorized_keys`. The platform
authenticates as `root` via the ansible key — no `das-template`-style
placeholder user (Template Standard §2.4).

## Derived templates

- `platform-substrate-server` — `derive(this) + K3s prerequisites`
  (br_netfilter/overlay, K3s sysctls, tailscaled). Consumer:
  `ClusterProvisionWorkflow`.
- `customer-workload-server` — `derive(this) + NVIDIA driver/CUDA` (Flux Edge;
  PM2-owned re-model, gates on this corrected base).

## Grandfathering Note

`mint-workstation` is currently grandfathered against the DAS Template Standard
pending the Appendix B workstation-profile backfill (Template Standard §B.3).
