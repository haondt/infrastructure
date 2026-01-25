# Infrastructure Automation

## Terraform Commands

Plan infrastructure changes
```bash
make tf-plan
```

Apply planned changes
```bash
make tf-apply
```

Destroy all infrastructure
```bash
make tf-destroy
```

## Ansible Commands

Test SSH connectivity to all hosts
```bash
make a-ping
```

Configure nodes after FAI installation (creates wheel/haondt groups, configures passwordless sudo, updates system)
```bash
make a-fai-setup TARGET=marble
make a-fai-setup TARGET=marble-1
```

FAI Setup Requirements

The `a-fai-setup` command:
- Can target a single host (`TARGET=marble-1`) or group (`TARGET=marble`)
- Requires the target host(s) to already have your SSH public key installed
- Requires the ansible user to already be in the sudoers group

### Debian commands

Update a debian (fai) host
```bash
make a-deb-update TARGET=marble
```

Install snapraid
```bash
make a-deb-snapraid-install TARGET=gabbro
```

Sync or Scrub snapraid
```bash
make a-deb-snapraid-sync TARGET=gabbro
make a-deb-snapraid-scrub TARGET=gabbro
```

Install mergerfs
```bash
make a-deb-mergerfs-install TARGET=gabbro
```

Configure Unbound
```bash
make a-deb-unbound-configure TARGET=flint
```

### K3s Commands

Install K3s cluster
```bash
make a-k3s-install TARGET=marble
```

Update K3s cluster
```bash
make a-k3s-upgrade TARGET=marble
```

Reboot K3s cluster nodes
```bash
make a-k3s-reboot TARGET=marble
```

Reset/uninstall K3s cluster
```bash
make a-k3s-reset TARGET=marble
```

### Kubernetes Configuration Commands

Configure Kubernetes resources (service accounts, RBAC, namespaces)
```bash
make a-k8s-configure TARGET=marble
```

Configure a particular Kubernetes component or multiple comma-seperated components
```bash
make a-k8s-configure TARGET=marble COMPONENTS=alloy,calico
```

Uninstall a particular Kubernetes component or multiple comma-seperated components
```bash
make a-k8s-uninstall TARGET=marble COMPONENTS=alloy,calico
```

After running `a-k8s-configure`, you'll find kubeconfig files in `deployment/artifacts/ansible/`:
- `{service-account-name}-kubeconfig.yaml` - Ready to use in CI/CD pipelines

Remove all Ansible-managed Kubernetes resources
```bash
make a-k8s-reset TARGET=marble
```

# TODO

- need to either add the `daemon.json` changes documented here https://gitlab.com/haondt/CICD/runner and add installing docker to the basalt setup, or rework everything to use kaniko.
