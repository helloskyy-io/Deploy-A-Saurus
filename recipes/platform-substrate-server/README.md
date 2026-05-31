# Platform-Substrate Server — K3s Node Substrate (derived)

## Purpose

A minimal Ubuntu 24.04 LTS substrate for VMs that will have platform
orchestration (K3s + Calico + Tailscale) installed post-clone via Ansible. The
template is deliberately **not** self-contained — it is the floor the platform
builds on. See DAS Template Standard Appendix A for the binding class definition.

This recipe is the `platform-substrate-server` class **extracted** out of the
old, mis-named `ubuntu-24-server-base` (which conflated the universal base with
this class by baking K3s prerequisites). Per DAS Template Standard §1 historical
note + §5.4, the base was stripped to `universal-base` and the K3s prerequisites
were lifted into this additive derived template.

## Derive model

This is a **derived** template (DAS Template Standard §5.4). `install_method:
derive`, `derive_from: ubuntu-24-server-base@<version>`. Stage 1 clones the
published universal base and applies only the K3s-prerequisite delta — no raw
cloud-image fetch, no re-hardening, no guest-agent dance. The §2 universals
(cloud-init NoCloud, qemu-guest-agent, growpart, root + ansible key, swap-off,
hardening, no-operator-users) are inherited from the parent.

**Lineage (binding, §5.4):** the parent is version-pinned. When
`ubuntu-24-server-base` publishes a new version, bump `derive_from` here and
rebuild (§5.2 rebuild trigger). Stage 1 fails loud with
`DERIVE_PARENT_VERSION_MISMATCH` if the pin does not match the published parent.

## The delta (this template's binding additions)

Per DAS Template Standard §A.9's build-model note, the binding additions beyond
the §2 universals are exactly:

1. `tailscaled` binary installed, systemd unit NOT enabled (platform runs
   `tailscale up` post-clone; the template never joins a tailnet).
2. CNI kernel modules `br_netfilter` + `overlay` loaded at boot
   (`/etc/modules-load.d/k3s.conf`).
3. K3s sysctls `net.bridge.bridge-nf-call-iptables=1` and
   `net.ipv4.ip_forward=1` (`/etc/sysctl.d/99-k3s.conf`).

The build steps live in the Ansible playbook
`das_platform_substrate_server.yml` in
`mdc-ansible-collections/skyy_net/common/playbooks/`.

## Conformance

Stage 2 runs the full §A.6 post-boot check against the test clone via the
conformance role's `tasks/platform-substrate-server.yml`. Per §6.4 (layered
conformance), running the child's class check against the derived artifact
proves BOTH that the §2 universals survived the delta AND that the K3s delta is
correct. The assertion list is translated 1:1 into `tests/automated.yaml`.

Failure mode per Template Standard §6.3: any assertion failure surfaces as a
Stage 2 `ActivityResult` error with `error_code: <assertion-name>` and `details:`
containing stdout plus expected-vs-observed. Operator-debuggable.

## Consumer / artifact / VMID resolution

Consumer: `ClusterProvisionWorkflow` (Cluster 1 + Cluster 2 K3s nodes). Per the
DAS Template Consumption Standard §1, the consumer resolves this template's
published VMID from `<desired-state>/vm/golden_templates/platform-substrate-server.yaml`
(VMID authority) — never a hardcoded constant. Artifact: `rbd:ssd-pool-rbd/platform-substrate-server-v<version>`,
registered in `<desired-state>/common/das-versions.yaml` under
`vm_templates.platform-substrate-server`.

## Template Credentials

A platform-substrate template ships with **no operator users** (inherited from
the universal base). The platform authenticates as `root` via the ansible key —
no `das-template`-style placeholder user (Template Standard §2.4, §A.2).
