# Deploy-A-Saurus

## What This Repo Is

A **thin recipe repo** — declarative build definitions for container images and VM templates. This repo defines WHAT to build, WITH WHAT versions/vars, and HOW TO VERIFY the result.

This repo does NOT contain:
- **Ansible roles** — those live in `mdc-ansible-collections`
- **Temporal workflows** — those live in `skyy-command/components/temporal/`
- **Build execution logic** — that's Skyy-Command's job
- **Desired state** — that's the desired-state repo

## Standards (must follow)

**All DAS development must follow the [DAS Standard](/opt/skyy-net/mdc-master-planning/standards/development/deploy-a-saurus/das_standard.md).** This defines recipe format, versioning, testing conventions, pipeline behavior, and storage standards. If an implementation contradicts the standard, pause and seek clarification.

Also reference:
- **[Architecture Standard](/opt/skyy-net/mdc-master-planning/standards/architecture/architectural_standard.md)** — governing design document
- **[Stack Reference](/opt/skyy-net/mdc-master-planning/standards/architecture/stack_reference.md)** — DAS and Harbor component definitions
- **[Ansible Standard](/opt/skyy-net/mdc-master-planning/standards/development/ansible/ansible_standard.md)** — roles referenced by recipes must follow this
- **[Temporal Standard](/opt/skyy-net/mdc-master-planning/standards/development/temporal/temporal_standard.md)** — workflows that execute recipes follow this

## Planning Docs

- **[DAS Roadmap](/opt/skyy-net/mdc-master-planning/development/common/deploy-a-saurus/roadmap.md)** — phase overview
- **[Phase 0: Foundation](/opt/skyy-net/mdc-master-planning/development/common/deploy-a-saurus/phase0_foundation.md)** — current implementation plan

## GitOps Pipeline

This repo drives builds via git actions:

| Git Action | What Happens |
|---|---|
| Push to `dev` | Temporal builds configuration, runs automated tests, stages for human testing |
| Merge PR to `main` | Temporal bakes image (docker commit / qcow2 export), deploys from image, tests again |
| Tag on `main` | Temporal stores artifact (Harbor / Proxmox), updates Django version, purges old versions |

Only changed recipes trigger builds. Each stage gates the next.

## Key Rules

- **Recipes are declarative** — they define what to build, not how to execute
- **One folder per image** under `recipes/` — self-contained with vars, compose/Dockerfile, and test criteria
- **No hardcoded paths** — paths resolve through config.yaml
- **No Ansible roles in this repo** — reference them from `mdc-ansible-collections` by FQCN
- **Test criteria live with the recipe** — automated.yaml for machines, human.md for people
