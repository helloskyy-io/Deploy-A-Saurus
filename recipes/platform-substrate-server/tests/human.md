# Human Test Checklist: Platform-Substrate Server

Platform-substrate templates have a thin human-test surface — most conformance is
machine-checkable via `tests/automated.yaml` (DAS Template Standard §A.6). This
checklist covers the operator sanity checks that automation can't easily assert.

This is a **derived** template (DAS Template Standard §5.4): it is built by
cloning the published `ubuntu-24-server-base` universal base and applying only
the K3s-prerequisite delta. The §2 universals are inherited from the parent, not
re-applied — but §6.4 layered conformance still asserts they survived the delta.

## Stage 1: Configuration Test (the delta)

After the delta Ansible (`das_platform_substrate_server.yml`) has run against
the cloned build VM:

- [ ] SSH into the build VM as `root` using the platform ansible key succeeds
      (inherited from the parent — proves the clone carried the baked key)
- [ ] `lsmod | grep -E 'br_netfilter|overlay'` shows both modules loaded (delta)
- [ ] `sysctl -n net.bridge.bridge-nf-call-iptables` and `sysctl -n net.ipv4.ip_forward`
      both return `1` (delta)
- [ ] `systemctl is-enabled tailscaled` returns `disabled` — installed, NOT enabled (delta)
- [ ] No `ubuntu` user exists (`id ubuntu` returns "no such user") — inherited
- [ ] `journalctl -b -p err` shows no unexpected errors from cloud-init or systemd

### §A.2 hard requirements not covered by §A.6 automation

These are Template Standard §A.2 class-specific MUSTs that §A.6 does not assert.
Until §A.6 is extended (upstream standard gap), verify manually:

- [ ] `curl --version` returns 0 (§A.2 "curl installed" — inherited from base)
- [ ] `grep -c '^[^#]*requiretty' /etc/sudoers /etc/sudoers.d/* 2>/dev/null` returns
      0 (§A.2 "sudoers allows root without TTY" — inherited)
- [ ] `grep -rhE '^\s*addresses:' /etc/netplan/` returns nothing (§A.2 "single NIC
      DHCP only — no static config in /etc/netplan/*.yaml" — inherited)

## Stage 2: Image Test

After baking (qm template + rbd snapshot + clone to fresh VM):

- [ ] Fresh clone boots and acquires a DHCP address on the expected VLAN
- [ ] Proxmox `qm agent <vmid> network-get-interfaces` returns the clone's IPv4
- [ ] SSH as `root` with the platform ansible key works on the clone
- [ ] Machine-id is fresh and differs from the template's (clones must not share machine-id)
- [ ] A subsequent K3s install via `mdc-ansible-collections` playbooks succeeds on the clone

## Final Signoff

- [ ] All automated assertions in `tests/automated.yaml` pass
- [ ] The pinned parent `derive_from: ubuntu-24-server-base@<version>` matches the
      currently-published universal base version (§5.4 lineage; Stage 1 fails loud
      with `DERIVE_PARENT_VERSION_MISMATCH` if it doesn't)
- [ ] Template is registered in `<desired-state>/common/das-versions.yaml` under
      `vm_templates.platform-substrate-server` with an immutable `version:` and `recipe_commit:`
- [ ] Operator authored `<desired-state>/vm/golden_templates/platform-substrate-server.yaml`
      with the published VMID + version (the consumer's VMID authority per the
      Consumption Standard §1)
- [ ] Operator ready to re-point `golden_template_recipe` on `k3s-1.yaml` / `k3s-2.yaml`
      desired-state templates from `ubuntu-24-server-base` to `platform-substrate-server`
      (DAS Template Standard §A.8 — done AFTER this template publishes)
