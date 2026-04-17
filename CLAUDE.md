# Deploy-A-Saurus

A **thin recipe repo** — declarative build definitions for container images and VM templates. This repo defines WHAT to build, WITH WHAT versions/vars, and HOW TO VERIFY the result.

**All MDC platform standards live in `mdc-master-planning`.** This file references them by absolute path. Do not duplicate a standard here — always link to the canonical copy.

## What This Repo Does NOT Contain

- **Ansible roles** — those live in `mdc-ansible-collections`
- **Temporal workflows** — those live in `skyy-command/components/temporal/modules/deploy_a_saurus/`
- **Build execution logic** — that's Skyy-Command's job
- **Desired state** — that's the desired-state repo

## Standards (read when triggered)

Each entry tells you **when to read the standard**. Do not pull every standard into context — read only the ones relevant to your current task.

### Architecture & cross-cutting (read first for any design work)

- **[Architecture Standard](/opt/skyy-net/mdc-master-planning/standards/architecture/architectural_standard.md)** — the governing document. **Read before** any new component, phase, or cross-cutting change.
- **[Stack Reference](/opt/skyy-net/mdc-master-planning/standards/architecture/stack_reference.md)** — **read when** referencing DAS or Harbor components or their current status.
- **[MDC Networking Standard](/opt/skyy-net/mdc-master-planning/standards/development/networking/networking_standard.md)** — **read when** editing a recipe's `vm.workload_tier` field or anything else that touches VLANs or VMID ranges. Recipes declare a customer-facing tier (currently `production`); internal tiers (`das_in_progress`, `golden_template`) are rejected by the validator. See Networking Standard §6 for the `workload_tier` field definition.

### Development (read when doing that type of work)

- **[DAS Standard](/opt/skyy-net/mdc-master-planning/standards/development/deploy-a-saurus/das_standard.md)** — **read when** writing or modifying any recipe, test criteria, or pipeline behavior in this repo. Defines recipe format, versioning, testing conventions, pipeline behavior, and artifact storage.
- **[Ansible Standard](/opt/skyy-net/mdc-master-planning/standards/development/ansible/ansible_standard.md)** — **read when** referencing roles from recipes. Roles themselves live in `mdc-ansible-collections`.
- **[Temporal Standard](/opt/skyy-net/mdc-master-planning/standards/development/temporal/temporal_standard.md)** — **read when** the recipe interacts with how Temporal workflows execute it (e.g., var passing, test invocation).
- **[Persistent Storage Standard](/opt/skyy-net/mdc-master-planning/standards/development/persistent-storage/persistent_storage.md)** — **read when** touching anything that writes persistent state (Harbor storage, Ceph RBD artifact storage, build VM data).
- **[SSH Key Management Standard](/opt/skyy-net/mdc-master-planning/standards/development/remote-access/ssh_key_management.md)** — **read when** recipes reference SSH keys or the build VM's SSH configuration.

### Documentation (read when writing docs)

- **[Dev Docs Standard](/opt/skyy-net/mdc-master-planning/development/dev_docs_standard.md)** — **read when** creating or revising roadmap docs, phase docs, or any document under `development/` in mdc-master-planning.

## Planning Docs (in mdc-master-planning)

- **[DAS Roadmap](/opt/skyy-net/mdc-master-planning/development/common/deploy-a-saurus/roadmap.md)** — phase overview
- **[Phase 0: Foundation](/opt/skyy-net/mdc-master-planning/development/common/deploy-a-saurus/phase0_foundation.md)** — manual build process (complete)
- **[Phase 1: Temporal Workflows](/opt/skyy-net/mdc-master-planning/development/common/deploy-a-saurus/phase1_temporal_workflows.md)** — current work: script-triggered build pipeline

## GitOps Pipeline

This repo drives builds via git actions:

| Git Action | What Happens |
|---|---|
| Push to `dev` | Temporal builds configuration, runs automated tests, stages for human testing |
| Merge PR to `main` | Temporal bakes image (docker commit / qm template + rbd snapshot), deploys from image, tests again |
| Tag on `main` | Temporal stores artifact (Harbor / Ceph RBD), updates Django version, purges old versions |

Only changed recipes trigger builds. Each stage gates the next.

## Key Rules

- **Recipes are declarative** — they define what to build, not how to execute
- **One folder per image** under `recipes/` — self-contained with vars, compose/Dockerfile, and test criteria
- **No hardcoded paths** — paths resolve through `config.yaml`
- **No Ansible roles in this repo** — reference them from `mdc-ansible-collections` by FQCN
- **Test criteria live with the recipe** — `automated.yaml` for machines, `human.md` for people
