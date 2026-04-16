# Mint Workstation — Build Notes

Operational notes for building and maintaining the Linux Mint workstation VM template.

## Prerequisites

These must be satisfied once per golden base template — not per build — before Stage 1 of the Temporal pipeline can run end-to-end against a fresh clone.

- **qemu-guest-agent installed in the golden base template** (VMID 100002 at time of writing). Stage 1's `wait_for_build_vm_ssh` step asks Proxmox for the build VM's IPv4 address via the guest agent API; without it, the step times out and Stage 1 fails before Ansible can run.
  - Inside the running template: `sudo apt install -y qemu-guest-agent && sudo systemctl enable --now qemu-guest-agent`.
  - In Proxmox VM config for the template: set `agent: 1` (Options → QEMU Guest Agent → enabled).
  - Verify from the Proxmox host: `qm agent <vmid> network-get-interfaces` returns an interfaces list (not an error).
- **Config fields populated on Skyy-Command's `config.yaml`:** `proxmox.build_node` (e.g. `puma-server-005`) and `proxmox.golden_template_vmid` (e.g. `100002`). `template.config.yaml` documents both.
- **External Ansible collection dependencies installed on the worker:** `community.general`, `community.crypto`, `ansible.posix`. The bootstrap worker Dockerfile installs these at build time; local dev installs via `ansible-galaxy collection install -r /opt/skyy-net/mdc-ansible-collections/meta/requirements.yml`.

## Base OS

- **ISO:** Linux Mint 22.1 Cinnamon 64-bit
- **Storage:** `local` on puma-server-009
- **Manual install required:** Mint doesn't support unattended install. This is done once per major version release.

## Test VM Specs (Proxmox)

| Setting | Value |
|---|---|
| Memory | 16384 MB |
| Processors | 8 (type: host) |
| BIOS | OVMF (UEFI) |
| Display | Default |
| Machine | Default (i440fx) |
| SCSI Controller | VirtIO SCSI single |
| Hard Disk | local-lvm1, 100 GB |
| Network | vmbr0, VLAN 200, MAC address BC:24:11:24:9D:69 |
| Start at Boot | Yes |
| OS Type | Linux 6.x - 2.6 Kernel |
| Boot Order | scsi0, net0 |

## Template Credentials

These are the placeholder credentials used during template building. They are **not customer credentials** — the user is renamed and password is reset at deploy time via post-provision Ansible.

| Field | Value |
|---|---|
| Username | `das-template` |
| Password | `das-template` |
| Hostname | `das-mint-workstation` |

## Manual Base Install Steps

1. Create VM with specs above
2. Mount Mint ISO to CD/DVD drive
3. Boot and install Mint, standard install:
    ```bash
    username: das-template
    password: das-template
    hostname: das-mint-workstation
    ```
4. Reboot, login to desktop
5. Install SSH server, disk utilities, and QEMU guest agent via terminal (Proxmox console or noVNC):
   ```bash
   sudo apt update
   sudo apt install -y openssh-server cloud-guest-utils qemu-guest-agent
   sudo systemctl enable ssh
   sudo systemctl start ssh
   ```
   On the Proxmox host, enable the agent in the VM config (one-time per template) — this adds the virtio-serial channel the agent uses:
   ```bash
   qm set <vmid> --agent 1
   ```
   Then reboot the VM. `qemu-guest-agent` on Ubuntu 24.04 / Mint 22.1 is a static service started by udev when the virtio-serial channel `/dev/virtio-ports/org.qemu.guest_agent.0` appears — do NOT `systemctl enable` it manually, that fails with "no installation config" because the unit has no `[Install]` section by design.

   Verify from the Proxmox host after reboot:
   ```bash
   qm agent <vmid> ping      # empty output = agent responding
   ```
   This is a hard prerequisite for DAS Stage 1's `wait_for_build_vm_ssh` step, which asks Proxmox for the build VM's IPv4 via the guest agent API.
6. Run full system update via Update Manager (GUI)
7. Verify IP address is `192.168.200.101`: (if not check the mac reservation in the firewall)
   ```bash
   ip addr show
   ```
8. Verify SSH access from Skyy-Command VM:
   ```bash
   ssh das-template@192.168.200.101
   ```
9. Remove ISO from CD/DVD drive in Proxmox
10. Snapshot the VM as `base-install` (clean rollback point before Ansible runs)

## Post-Install Ansible Configuration

Run from `/opt/skyy-net/mdc-ansible-collections`:

```bash
export ANSIBLE_ROLES_PATH=/opt/skyy-net/mdc-ansible-collections/skyy_net/common/roles

# Step 1: Base template roles (always baked: networking_utils, jq, tailscale, sunshine, ufw)
ansible-playbook /opt/skyy-net/mdc-ansible-collections/skyy_net/common/playbooks/das_mint_workstation_base.yml -i 192.168.200.101, --user=das-template -k -K

# Step 2: Customer apps (browsers, productivity, communication, media, dev tools, backup)
ansible-playbook /opt/skyy-net/mdc-ansible-collections/skyy_net/common/playbooks/das_mint_workstation_apps.yml -i 192.168.200.101, --user=das-template -k -K
```

## Image Baking (Ceph RBD)

After Ansible configuration is complete and verified:

1. Shut down the VM cleanly:
   ```bash
   ssh das-template@192.168.200.101 "sudo shutdown now"
   ```

2. Convert to Proxmox template (creates `__base__` snapshot on Ceph RBD):
   ```bash
   # From the Proxmox host where the VM is registered
   ssh root@puma-server-009
   qm template VMID
   ```

3. Verify the artifact exists on Ceph:
   ```bash
   rbd snap ls ssd-pool-rbd/base-VMID-disk-0
   # Should show: __base__ snapshot
   ```

## Deploying From the Baked Image (from ANY node)

This is the process Temporal will automate. Can be run from any Proxmox host in the cluster.

```bash
# 1. Read template config (available from any node)
cat /etc/pve/nodes/<template-owner-node>/qemu-server/VMID.conf

# 2. Clone the RBD image on Ceph (instant, copy-on-write)
rbd clone ssd-pool-rbd/base-VMID-disk-0@__base__ ssd-pool-rbd/vm-NEWVMID-disk-0

# 3. Create VM with hardware specs from the template config
qm create NEWVMID --name customer-vm-name \
  --cores 4 --memory 2048 --cpu x86-64-v2-AES \
  --scsihw virtio-scsi-single \
  --net0 virtio,bridge=vmbr0,firewall=1 \
  --ostype l26 \
  --scsi0 persistent-rbd:vm-NEWVMID-disk-0,iothread=1,size=10G,ssd=1

# 4. Start the VM
qm start NEWVMID
```

**Key facts:**
- `rbd clone` is instant (copy-on-write) — no data copied until the clone diverges
- Works from ANY node — no dependency on the template's registered node
- Ceph pool: `ssd-pool-rbd` (Proxmox storage name: `persistent-rbd`)
- Template config readable cluster-wide via `/etc/pve/nodes/`

## Full Pipeline (Manual → Automated)

```
1. Human: manual Mint install, SSH setup, note IP
2. Human: update recipe with VM IP, push to dev
   → Temporal: runs Ansible, auto-tests, stages for human
3. Human: tests manually, approves → merges PR to main
   → Temporal: qm template, rbd clone to fresh VM, auto-tests, stages for human
4. Human: tests baked image, approves → tags release (mint-workstation-v1.0.0)
   → Temporal: updates Django version, future deployments use this image
5. Human: deploys from UI as customer would, final sanity check
```

## Username Portability

Template is built with placeholder user `das-template`. At deploy time, post-provision Ansible renames to the customer's username. (TODO: document exact process after testing)
