# Ubuntu 24 Server Base — Platform-Substrate Template

## Purpose

A minimal Ubuntu 24.04 LTS substrate for VMs that will have platform orchestration (K3s + Calico + Tailscale) installed post-clone via Ansible. The template is deliberately **not** self-contained — it is the floor the platform builds on. See DAS Template Standard Appendix A for the binding class definition.

Consumer, artifact location, and current-version swap path: see Template Standard §A.7–A.8.

## Build Steps

The 10 canonical build steps (cloud image → conformant template) are defined in DAS Template Standard §A.9. This recipe is declarative; the build steps themselves live in the Ansible playbook `das_ubuntu_24_server_base.yml` in `mdc-ansible-collections/skyy_net/common/playbooks/`. That playbook is a **follow-on dispatch** — it is not authored in this PR.

## Conformance

Stage 2 runs the 10 machine-checkable assertions from DAS Template Standard §A.6 against the test clone. The assertion list is translated 1:1 into `tests/automated.yaml` in this directory.

The executing harness is an Ansible role at `mdc-ansible-collections/conformance/platform-substrate-server/` — also a **follow-on dispatch**, not in this PR.

Failure mode per Template Standard §6.3: any assertion failure surfaces as a Stage 2 `ActivityResult` error with `error_code: <assertion-name>` and `details:` containing stdout plus expected-vs-observed. Operator-debuggable.

## Base Image Provenance

Source URL and pinned checksum live in `recipe.yaml` under `base:` (single source of truth). Refresh trigger: Template Standard §5.2.

## Template Credentials

Unlike workstation templates, a platform-substrate template ships with **no operator users**. The cloud image's default `ubuntu` user is deleted at build time; root SSH is enabled and the platform ansible pubkey is baked into `/root/.ssh/authorized_keys`. The platform authenticates as `root` via the ansible key — no `das-template`-style placeholder user is used or needed (Template Standard §2.4, §A.2).

## Grandfathering Note

`mint-workstation` is currently the only other DAS template. It is **grandfathered** against the DAS Template Standard pending the Appendix B workstation-profile backfill (Template Standard §B.3). This recipe is the first to be authored against the binding Appendix A profile.

## Follow-On Dependencies

Before this recipe can build, land in `das-versions.yaml`, or be cloned as a platform substrate, the following work items must ship:

1. **`skyy-command`** — extend the DAS recipe validator to accept the new schema fields introduced here: `template_class` (top-level), `base.install_method: cloud-image`, `base.source_url`, `base.source_checksum`. See PR description for validation specifics.
2. **`mdc-ansible-collections`** — implement the `das_ubuntu_24_server_base.yml` playbook (Template Standard §A.9's 10 build steps) and the `conformance/platform-substrate-server/` role (Template Standard §A.6's 10 assertions).

Without (1), Stage 1 validation rejects this recipe. Without (2), Stage 1 cannot run Ansible against the build VM and Stage 2 cannot assert conformance.
