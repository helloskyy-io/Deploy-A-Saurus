# Human Test Checklist: Ubuntu 24 Server — Customer Workload (GPU)

Customer-workload-server templates carry the universal cloud-init/guest-agent
requirements plus a GPU software stack (NVIDIA driver 570 + CUDA 12-8). Most
conformance is machine-checkable via `tests/automated.yaml` (Template Standard
Appendix C §C.6); this checklist covers the operator sanity checks automation
can't easily assert.

## Stage 1: Configuration Test

After Ansible has run against the build VM:

- [ ] SSH into the build VM as `root` using the platform ansible key succeeds
- [ ] No `ubuntu` user exists (`id ubuntu` returns "no such user")
- [ ] `journalctl -b -p err` shows no unexpected errors from cloud-init or systemd
- [ ] `nvidia-smi --version` reports DRIVER version 570.x (software present; a GPU
      need not be passed through to the build host)
- [ ] `nvcc -V` reports CUDA release 12.8
- [ ] **No FluxCore present** — `systemctl list-unit-files | grep -i fluxcore`
      returns nothing (NEVER-CLONE-AFTER-FLUXCORE: the agent is installed live
      per-VM post-clone, never baked into the template)

## Stage 2: Image Test

After baking (qm template + rbd snapshot + clone to fresh VM):

- [ ] Fresh clone boots and acquires a DHCP address on the expected VLAN (155)
- [ ] Proxmox `qm agent <vmid> network-get-interfaces` returns the clone's IPv4
- [ ] SSH as `root` with the platform ansible key works on the clone
- [ ] Machine-id is fresh and differs from the template's (clones must not share machine-id)
- [ ] On a VM with a GPU passed through (PCIe passthrough): `nvidia-smi` returns the
      GPU's name + memory (the deploy-time HARDWARE check the bake-time harness
      cannot perform — this is the consuming Flux Edge workflow's responsibility,
      verified here once manually per template version)

## Final Signoff

- [ ] All automated assertions in `tests/automated.yaml` pass
- [ ] Template is registered in `<desired-state>/common/das-versions.yaml` under
      `vm_templates.ubuntu-24-server-customer-workload` with an immutable
      `version:` and `recipe_commit:`
- [ ] Operator ready to flip the consuming desired-state template's
      `golden_template_vmid` to this template version (DAS Template Standard §A.8)
