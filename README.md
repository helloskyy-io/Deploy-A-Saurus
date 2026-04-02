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
| `mint-workstation` | VM (qcow2) | Linux Mint workstation for US-based remote access | Phase 0 |
| `kasm-browser` | Container (Docker) | Browser-only Kasm container for lightweight access | Phase 0 |

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