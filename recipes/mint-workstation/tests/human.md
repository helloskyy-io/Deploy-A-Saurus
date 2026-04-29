# Human Test Checklist: Mint Workstation

## Stage 1: Configuration Test
After Ansible runs against the build VM:

- [ ] SSH into VM as `das-template`
- [ ] Desktop environment loads (Cinnamon)
- [ ] Sunshine service is running (`systemctl status sunshine`)
- [ ] Tailscale is installed (`tailscale version`)
- [ ] UFW is active with SSH allowed (`sudo ufw status`)
- [ ] No error dialogs or broken packages visible on desktop

## Stage 2: Image Test
After baking (qm template + rbd clone + qm create + boot):

- [ ] Cloned VM boots successfully
- [ ] Login as `das-template` works
- [ ] All Stage 1 checks still pass on the clone
- [ ] Sunshine web UI accessible at `https://<vm-ip>:47990`
- [ ] Moonlight can connect and stream the desktop
- [ ] Desktop is responsive via Moonlight (no artifacts, no lag)

## Final Signoff
- [ ] Admin approves for release
- [ ] Tag version in git (e.g., `mint-workstation-v0.1.0`)
