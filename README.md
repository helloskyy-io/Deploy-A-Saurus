# Deploy-A-Saurus

**Image factory for the MDC platform.** Produces tested, versioned container images and VM templates from composable Ansible roles.

## What This Is

Deploy-A-Saurus (DAS) is a thin recipe repo. Each recipe defines what to build, with what versions, and how to verify it works. The actual building is done by Skyy-Command (Temporal workflows) using Ansible roles from `mdc-ansible-collections`.

## How It Works

```
  dev                      main                     tagged
  ┌──────────────┐        ┌──────────────┐         ┌──────────────┐
  │  Workshop    │ merge  │   Quality    │  tag    │  Production  │
  │              │  ──→   │   Control    │  ──→    │    Ready     │
  │  "Try it"    │        │  "Bake it"   │         │  "Ship it"   │
  └──────────────┘        └──────────────┘         └──────────────┘
```

| Git Action | What Happens |
|---|---|
| Push to `dev` | Temporal builds configuration, runs automated tests, stages for human testing |
| Merge PR to `main` | Temporal bakes image (docker commit / qcow2), deploys from image, tests again |
| Tag on `main` | Temporal stores artifact (Harbor / Proxmox), updates Django, purges old versions |

Only changed recipes trigger builds. Each stage gates the next.

## Recipes

| Recipe | Type | Description | Status |
|---|---|---|---|
| `mint-workstation` | VM (qcow2) | Linux Mint workstation for US-based remote access | Phase 1 published (v0.1.0) |
| `ubuntu-24-server-base` | VM (qcow2) | Platform-substrate Ubuntu 24 server base | Phase 1 published (v1.0.0) |
| `kasm-browser` | Container (Docker) | Browser-only Kasm container for lightweight access | Phase 0 |

## Running Phase 1 Workflows

VM pipeline (Phase 1, Sprint 1-2a/1-2c) is run from the Skyy-Command host via three trigger scripts. Each stage gates the next; run them in sequence:

```bash
# Stage 1 — Build VM, Ansible, automated tests
sudo /opt/skyy-net/skyy-command/lib/temporal/scripts/das_vm_stage1_start.sh <recipe-name>

# Stage 2 — Convert to template, RBD clone test, automated tests
sudo /opt/skyy-net/skyy-command/lib/temporal/scripts/das_vm_stage2_start.sh <recipe-name>

# Stage 3 — Commit version-of-record, purge old images, cleanup
sudo /opt/skyy-net/skyy-command/lib/temporal/scripts/das_vm_stage3_start.sh <recipe-name>
```

Recipe name is the directory name under `recipes/` (e.g. `mint-workstation`). Stage 3 commits the published version to the desired-state repo's `common/das-versions.yaml` — git is the source of truth. Container pipeline (Phase 2, Sprint 2-5) lands when Harbor is operational.

## Creating a New Recipe

See [docs/recipe_format.md](docs/recipe_format.md) for the recipe schema and conventions.

Each recipe lives in its own folder under `recipes/`:

```
recipes/<name>/
├── recipe.yaml          # Build definition (required)
├── Dockerfile           # Container builds only (if needed)
├── docker-compose.yaml  # Container builds only (if needed)
└── tests/
    ├── automated.yaml   # Machine test criteria (required)
    └── human.md         # Human test checklist (required)
```

## Standards

All DAS development follows the [DAS Standard](/opt/skyy-net/mdc-master-planning/standards/development/deploy-a-saurus/das_standard.md).

## Related Repos

| Repo | Role |
|---|---|
| `mdc-ansible-collections` | Ansible roles referenced by recipes |
| `skyy-command` | Temporal workflows that execute builds, Django for version tracking |
| `mdc-master-planning` | DAS standard, roadmap, and phase planning docs |