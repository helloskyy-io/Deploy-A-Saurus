# Human Test Checklist: Ubuntu 24 Server — Customer Workload (GPU-less base)

Customer-workload-server is a **GPU-less** base (two-stage model, DAS Template
Standard §C.4.1 / §C.6.1): the §2 universals are baked; the NVIDIA driver + CUDA
are **built at deploy**, exact-pinned per-VM from desired state. Most bake
conformance is machine-checkable via `tests/automated.yaml` (Appendix C §C.6);
this checklist covers the operator sanity checks automation can't easily assert.
The GPU checks are POST-DEPLOY (on a built clone with a passed-through GPU), not
bake-time.

## Stage 1: Configuration Test (bake — GPU-less base)

After Ansible has run against the build VM:

- [ ] SSH into the build VM as `root` using the platform ansible key succeeds
- [ ] No `ubuntu` user exists (`id ubuntu` returns "no such user")
- [ ] `journalctl -b -p err` shows no unexpected errors from cloud-init or systemd
- [ ] **No GPU stack baked** — `nvidia-smi` is NOT installed
      (`command -v nvidia-smi` returns nothing) and `dpkg -l | grep -E 'nvidia|cuda'`
      is empty. The driver/CUDA are deploy-time, never baked (§C.3 / §C.8).
- [ ] **No vendor agent present** — `systemctl list-unit-files | grep -iE 'fluxcore|synaptron|browser-session'`
      returns nothing (NEVER-CLONE-AFTER-INSTALL: vendor agents install live per-VM
      post-clone, never baked into the template)

## Stage 2: Image Test (bake artifact)

After baking (qm template + rbd snapshot + clone to fresh VM):

- [ ] Fresh clone boots and acquires a DHCP address on the expected VLAN
- [ ] Proxmox `qm agent <vmid> network-get-interfaces` returns the clone's IPv4
- [ ] SSH as `root` with the platform ansible key works on the clone
- [ ] Machine-id is fresh and differs from the template's (clones must not share machine-id)
- [ ] Clone still carries NO baked GPU stack (the GPU comes at deploy, below)

## Post-Deploy: GPU stack (built at deploy, NOT bake)

After the deploy-time build runs `install_nvidia_driver` against a clone with a
GPU passed through (the reconcile=deploy workflow; the `requires_post_deploy:
true` assertions in `automated.yaml` run here, not at bake):

- [ ] `nvidia-smi --query-gpu=driver_version --format=csv,noheader` reports the
      **EXACT** build declared in the VM's desired-state file
      (`settings.nvidia_driver`, e.g. `570.158.01`) — NOT a floated `570.211.01`
      or `580.x` (the reconciler's `verify_host_driver` STOPs on a mismatch)
- [ ] `nvcc -V` reports the CUDA release matching `settings.cuda`
- [ ] `modinfo nvidia` and `modinfo nvidia_uvm` both report a `version:` line
- [ ] On a VM with a GPU passed through: `nvidia-smi` returns the GPU's name +
      memory (the deploy-time HARDWARE check — the consuming workflow's
      responsibility, verified here once manually per template version)

## Final Signoff

- [ ] All bake-time automated assertions in `tests/automated.yaml` pass (the
      §2-universal block; the `requires_post_deploy` GPU assertions are SKIPPED at
      bake and verified post-deploy)
- [ ] Template is registered in `<desired-state>/common/das-versions.yaml` under
      `vm_templates.ubuntu-24-server-customer-workload` with an immutable
      `version:` and `recipe_commit:`
- [ ] Operator ready to flip the consuming desired-state template's published
      VMID to this GPU-less template version (DAS Template Standard §C.7)
