# Human Test Checklist: Ubuntu 24 Server Base (Universal Base)

The universal base has a thin human-test surface — most conformance is
machine-checkable via `tests/automated.yaml` (DAS Template Standard §2
universals, run by the conformance role's `tasks/universal-base.yml`). This
checklist covers the operator sanity checks that automation can't easily assert.

The universal base carries **zero class-specific content** (§5.4) — no K3s
prerequisites, no GPU stack, no vendor agents. Those live in derived templates.

## Stage 1: Configuration Test

After Ansible has run against the build VM:

- [ ] SSH into the build VM as `root` using the platform ansible key succeeds
- [ ] No `ubuntu` user exists (`id ubuntu` returns "no such user")
- [ ] `journalctl -b -p err` shows no unexpected errors from cloud-init or systemd
- [ ] Disk usage is reasonable for a minimal substrate (`df -h /` — expect well under 10G used)
- [ ] No K3s/class-specific artifacts present: `/etc/modules-load.d/k3s.conf` and
      `/etc/sysctl.d/99-k3s.conf` do NOT exist, and `tailscale` is NOT installed
      (those belong to the derived platform-substrate-server, not the base)

### §2 universals not covered by automation

These are §2 universal MUSTs the automated check does not assert. Verify manually:

- [ ] `curl --version` returns 0 (generic baseline tool kept in the base)
- [ ] `grep -c '^[^#]*requiretty' /etc/sudoers /etc/sudoers.d/* 2>/dev/null` returns
      0 (§2.4 "sudoers allows root without TTY")
- [ ] `grep -rhE '^\s*addresses:' /etc/netplan/` returns nothing (§2.3 "single NIC
      DHCP only — no static config in /etc/netplan/*.yaml")

## Stage 2: Image Test

After baking (qm template + rbd snapshot + clone to fresh VM):

- [ ] Fresh clone boots and acquires a DHCP address on the expected VLAN
- [ ] Proxmox `qm agent <vmid> network-get-interfaces` returns the clone's IPv4
- [ ] SSH as `root` with the platform ansible key works on the clone
- [ ] Machine-id is fresh and differs from the template's (clones must not share machine-id)
- [ ] A derived template (`platform-substrate-server`) builds clean by `derive`
      from this published base (the §5.4 acceptance test)

## Final Signoff

- [ ] All automated assertions in `tests/automated.yaml` pass
- [ ] Template is registered in `<desired-state>/common/das-versions.yaml` under
      `vm_templates.ubuntu-24-server-base` with an immutable `version: 2.0.0` and `recipe_commit:`
- [ ] Operator authored/updated `<desired-state>/vm/golden_templates/ubuntu-24-server-base.yaml`
      with the published VMID + `version: 2.0.0` (so `derive` children can resolve the parent)
