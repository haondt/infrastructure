INVENTORY := build/inventory.yml

INVENTORY_SOURCE := inventory
INVENTORY_SOURCE_DIRECTORIES := $(shell find $(INVENTORY_SOURCE) -type d)
INVENTORY_SOURCE_FILES := $(shell find $(INVENTORY_SOURCE) -type f)

ANSIBLE_INVENTORY := build/ansible.inventory.yml
ANSIBLE_DIRECTORY := ../ansible

SECRETS_FILE := secrets.yml

SCRIPTS_DIRECTORY := ../scripts
RENDER_DIRECTORY := $(SCRIPTS_DIRECTORY)/render_directory.py

SSH_PRIVATE_KEY := build/id_rsa

TF_TARGET := $(if $(TARGET),$(TARGET),default)
TF_VARS_JSON := build/$(TF_TARGET).terraform.tfvars.json
TF_DIRECTORY := ../terraform


$(INVENTORY): $(INVENTORY_SOURCE) $(INVENTORY_SOURCE_FILES) $(INVENTORY_SOURCE_DIRECTORIES)
	python3 $(RENDER_DIRECTORY) $(INVENTORY_SOURCE) -v SECRETS $(SECRETS_FILE) > $@

$(ANSIBLE_INVENTORY): $(INVENTORY)
	@mkdir -p artifacts/ansible
	cat $(INVENTORY) | yq '.ansible' | \
		yq eval '.clusters.vars.haondt.artifacts = "$(shell pwd)/artifacts/ansible"' - > $@

$(TF_VARS_JSON): $(INVENTORY)
	@echo "Generating $(TF_VARS_JSON)"
	yq eval '.terraform.$(TF_TARGET).tfvars' $(INVENTORY) -o=json > $@

$(SSH_PRIVATE_KEY): $(SECRETS_FILE)
	cat $(SECRETS_FILE) | yq '.ssh.private_key' > $@
	chmod 400 $@

.PHONY: a-ping
a-ping: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ansible -i $(ANSIBLE_INVENTORY) all -m ping

.PHONY: a-deb-update
a-deb-update: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/debian/update.yml \
		-e target_hosts=$(TARGET)

.PHONY: a-deb-snapraid-install
a-deb-snapraid-install: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/debian/snapraid/install.yml \
		-e target_hosts=$(TARGET)

.PHONY: a-deb-snapraid-sync
a-deb-snapraid-sync: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/debian/snapraid/sync.yml \
		-e target_hosts=$(TARGET)

.PHONY: a-deb-snapraid-scrub
a-deb-snapraid-scrub: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/debian/snapraid/scrub.yml \
		-e target_hosts=$(TARGET)

.PHONY: a-deb-mergerfs-install
a-deb-mergerfs-install: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/debian/mergerfs/install.yml \
		-e target_hosts=$(TARGET)

.PHONY: a-deb-unbound-configure
a-deb-unbound-configure: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/debian/unbound/configure.yml \
		-e target_hosts=$(TARGET)

a-k8s-configure: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	@if [ -n "$(COMPONENTS)" ]; then \
		PLAYBOOK="playbooks/kubernetes/configure-component.yml"; \
		EXTRA="-e components=$(COMPONENTS)"; \
	else \
		PLAYBOOK="playbooks/kubernetes/configure.yml"; \
		EXTRA=""; \
	fi; \
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/$$PLAYBOOK \
		$$EXTRA -e target_hosts=$(TARGET)


.PHONY: a-fai-setup
a-fai-setup: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/fai/post-setup.yml \
		-e target_hosts=$(TARGET) \
		--ask-pass --ask-become-pass

.PHONY: a-k8s-uninstall
a-k8s-uninstall: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/kubernetes/uninstall.yml \
	    -e target_hosts=$(TARGET) \
		-e components=$(COMPONENTS)


.PHONY: a-k3s-install
a-k3s-install: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/k3s/install.yml \
	    -e target_hosts=$(TARGET) \
		-e components=$(COMPONENTS)

.PHONY: a-k3s-upgrade
a-k3s-upgrade: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/k3s/upgrade.yml \
	    -e target_hosts=$(TARGET)

.PHONY: a-k3s-reboot
a-k3s-reboot: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/k3s/reboot.yml \
	    -e target_hosts=$(TARGET)

.PHONY: a-k3s-reset
a-k3s-reset: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/k3s/reset.yml \
	    -e target_hosts=$(TARGET)


.PHONY: tf-init
tf-init: $(TF_VARS_JSON)
	terraform -chdir=$(TF_DIRECTORY)/$(TF_TARGET) init -var-file=../../deployment/$(TF_VARS_JSON) \
		-backend-config="address=$$(yq eval '.terraform.$(TF_TARGET).backend_config.address' $(INVENTORY))" \
		-backend-config="lock_address=$$(yq eval '.terraform.$(TF_TARGET).backend_config.lock_address' $(INVENTORY))" \
		-backend-config="unlock_address=$$(yq eval '.terraform.$(TF_TARGET).backend_config.unlock_address' $(INVENTORY))" \
		-backend-config="username=$$(yq eval '.terraform.$(TF_TARGET).backend_config.username' $(INVENTORY))" \
		-backend-config="password=$$(yq eval '.terraform.$(TF_TARGET).backend_config.password' $(INVENTORY))" \
		-backend-config="lock_method=$$(yq eval '.terraform.$(TF_TARGET).backend_config.lock_method' $(INVENTORY))" \
		-backend-config="unlock_method=$$(yq eval '.terraform.$(TF_TARGET).backend_config.unlock_method' $(INVENTORY))" \
		-backend-config="retry_wait_min=$$(yq eval '.terraform.$(TF_TARGET).backend_config.retry_wait_min' $(INVENTORY))"

.PHONY: tf-validate
tf-validate: tf-init
	terraform -chdir=$(TF_DIRECTORY)/$(TF_TARGET) validate

.PHONY: tf-plan
tf-plan: tf-init
	terraform -chdir=$(TF_DIRECTORY)/$(TF_TARGET) plan -out=tfplan.$(TF_TARGET).out -var-file=../../deployment/$(TF_VARS_JSON)

.PHONY: tf-apply
tf-apply: tf-init
	terraform -chdir=$(TF_DIRECTORY)/$(TF_TARGET) apply tfplan.$(TF_TARGET).out

.PHONY: tf-destroy
tf-destroy: tf-init
	@echo "WARNING: This will DESTROY all resources managed by this Terraform configuration!"
	@read -p "Are you absolutely sure you want to destroy? (yes/no): " CONFIRM && [ "$$CONFIRM" = "yes" ] || exit 1
	terraform -chdir=$(TF_DIRECTORY)/$(TF_TARGET) destroy -var-file=../deployment/$(TF_VARS_JSON)

.PHONY: tf-output
tf-output: tf-init
	terraform -chdir=$(TF_DIRECTORY)/$(TF_TARGET) output -json

