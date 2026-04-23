# Human Test Checklist: Ubuntu 24 Server Base

Platform-substrate templates have a thin human-test surface — most conformance is
machine-checkable via `tests/automated.yaml` (DAS Template Standard §A.6). This
checklist covers the operator sanity checks that automation can't easily assert.

## Stage 1: Configuration Test

After Ansible has run against the build VM:

- [ ] SSH into the build VM as `root` using the platform ansible key succeeds
- [ ] No `ubuntu` user exists (`id ubuntu` returns "no such user")
- [ ] `journalctl -b -p err` shows no unexpected errors from cloud-init or systemd
- [ ] Disk usage is reasonable for a minimal substrate (`df -h /` — expect well under 10G used)

## Stage 2: Image Test

After baking (qm template + rbd snapshot + clone to fresh VM):

- [ ] Fresh clone boots and acquires a DHCP address on the expected VLAN
- [ ] Proxmox `qm agent <vmid> network-get-interfaces` returns the clone's IPv4
- [ ] SSH as `root` with the platform ansible key works on the clone
- [ ] Machine-id is fresh and differs from the template's (clones must not share machine-id)
- [ ] A subsequent K3s install via `mdc-ansible-collections` playbooks succeeds on the clone

## Final Signoff

- [ ] All automated assertions in `tests/automated.yaml` pass
- [ ] Template is registered in `<desired-state>/common/das-versions.yaml` under `vm_templates.ubuntu-24-server-base` with an immutable `version:` and `recipe_commit:`
- [ ] Operator ready to flip `golden_template_vmid` on `k3s-1.yaml` / `k3s-2.yaml` desired-state templates (DAS Template Standard §A.8)
