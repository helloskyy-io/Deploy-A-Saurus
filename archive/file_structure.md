File Structure:

/fluxedge-deployment-toolbox
├── ansible/
│   ├── inventories                             (defines local host only)
│   ├── playbooks                               (Various entrypoints specific to a deployment)
│   ├── roles                                   (Generic reusable OoP components handles a single configuration task)
│   ├── vars                                    (global ansible vars)
│   └── ansible.cfg                            
│
├── bash/                                       (not in use)
│
├── deployments
│   ├── ubuntu_22.04
│   │   ├── deployment_configs/                 (yml based deployment files)
│   │   │   ├── argo_cd/                        (Base requirements file for initial dependency resolution)
│   │   │   ├── base/                           (Base files for deployment and service)
│   │   │   ├── overlay/                        (Environment-specific patches)
│   │   │   └── post_sync_hook/                 (Additional Ansible based configuration)
│   │   ├── environment/                        (Configure environment and dependencies)
│   │   │   ├── requirements.txt                (Base requirements file for initial dependency resolution)
│   │   │   └── environment.yml                 (Conda env recipe, for reproducing env)
│   │   ├── python/
│   │   │   └── deployment_recipe.py            (edit me later)
│   │   ├── test-suite/                         (Automated testing scripts)
│   │   ├── README.md                           (Specific to this deployment, also rendered in UI)
│   │   └── Dockerfile                          (Base Ubuntu + additional configs)
│   │
│   ├── detectron2
│   │   ├── deployment_configs/                 (yml based deployment files)
│   │   │   └── post_sync_hook/                 (Additional Ansible based configuration)
│   │   └── README.md                           (Specific to this deployment, also rendered in UI)
│   │
│   ├── pytorch_xxx
│   │   ├── README.md
│   │   └── Dockerfile
│
├── python                                      (not in use)
│   └── tbd.py 
│
├── scripts                                     (not in use)
│   └── shared-utils.sh 
│
├── sidecar_containers                          (these are containers that run beside the main deployment in the same pod)
│   ├── nginx/
│   ├── prometheus_node_exporter/
│   └── uptime_kuma_monitoring/ 
│
├── test_suite/                                 (not in use)
│   ├── shared/
│   └──  deployment_specific/
│
├── file_structure.md                           (Provides breakdown of directory)
└── README.md                                   (Explains the framework and usage)
