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

Install K3s cluster
```bash
make a-k3s-install TARGET=marble
```

Reboot K3s cluster nodes
```bash
make a-k3s-reboot TARGET=marble
```

Reset/uninstall K3s cluster
```bash
make a-k3s-reset TARGET=marble
```
