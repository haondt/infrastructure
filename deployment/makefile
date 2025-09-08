
.PHONY: all tf-validate tf-plan tf-apply

TARGET ?= default

BASE_VARS_FILE := ./vars_base.yaml
SENSITIVE_VARS_FILE := ./vars_sensitive.yaml
COMBINED_VARS := build/vars.yaml
GENERATED_TFVARS_JSON := build/terraform.tfvars.json
GENERATED_GROUP_TFVARS_JSON = build/$(TARGET).terraform.tfvars.json
SSH_PRIVATE_KEY := build/id_rsa
TF_DIRECTORY := ../terraform

ANSIBLE_DIRECTORY := ../ansible
ANSIBLE_INVENTORY := build/ansible.inventory.yml
GENERATED_ANSIBLE_VARS := build/ansible.vars.yaml
GENERATED_GROUP_VARS = build/$(TARGET).ansible.vars.yaml


all: tf-plan

$(COMBINED_VARS): $(BASE_VARS_FILE) $(SENSITIVE_VARS_FILE)
	@echo "Generating $(COMBINED_VARS)"
	@yq eval-all '. as $$item ireduce ({}; . * $$item) | explode(.)' $(BASE_VARS_FILE) $(SENSITIVE_VARS_FILE) > $@

$(GENERATED_TFVARS_JSON): $(COMBINED_VARS)
	@echo "Generating $(GENERATED_TFVARS_JSON)"
	@yq eval '.terraform.default.tfvars' $(COMBINED_VARS) -o=json > $@

$(GENERATED_GROUP_TFVARS_JSON): $(COMBINED_VARS)
	@echo "Generating $(GENERATED_GROUP_TFVARS_JSON)"
	@yq eval '.terraform.$(TARGET).tfvars' $(COMBINED_VARS) -o=json > $@

$(GENERATED_ANSIBLE_VARS): $(COMBINED_VARS)
	@echo "Generating $(GENERATED_ANSIBLE_VARS)"
	@mkdir -p artifacts/ansible
	@yq eval '.ansible.vars' $(COMBINED_VARS) | \
		yq eval '.haondt.artifacts = "$(shell pwd)/artifacts/ansible"' - > $@

$(GENERATED_GROUP_VARS): $(COMBINED_VARS)
	@echo "Generating $(GENERATED_GROUP_VARS)"
	@yq eval '.ansible.group_vars.$(TARGET) // {}' $(COMBINED_VARS) > $@

$(ANSIBLE_INVENTORY): $(COMBINED_VARS)
	@echo "Generating $(ANSIBLE_INVENTORY)"
	@yq eval '.ansible.inventory' $(COMBINED_VARS) > $@

$(SSH_PRIVATE_KEY): $(COMBINED_VARS)
	@echo "Generating $(SSH_PRIVATE_KEY)"
	@yq eval '.ssh.private_key' $(COMBINED_VARS) > $@
	@chmod 400 $@

tf-init: $(GENERATED_GROUP_TFVARS_JSON)
	terraform -chdir=$(TF_DIRECTORY)/$(TARGET) init -var-file=../../deployment/$(GENERATED_GROUP_TFVARS_JSON) \
		-backend-config="address=$$(yq eval '.terraform.$(TARGET).backend_config.address' $(COMBINED_VARS))" \
		-backend-config="lock_address=$$(yq eval '.terraform.$(TARGET).backend_config.lock_address' $(COMBINED_VARS))" \
		-backend-config="unlock_address=$$(yq eval '.terraform.$(TARGET).backend_config.unlock_address' $(COMBINED_VARS))" \
		-backend-config="username=$$(yq eval '.terraform.$(TARGET).backend_config.username' $(COMBINED_VARS))" \
		-backend-config="password=$$(yq eval '.terraform.$(TARGET).backend_config.password' $(COMBINED_VARS))" \
		-backend-config="lock_method=$$(yq eval '.terraform.$(TARGET).backend_config.lock_method' $(COMBINED_VARS))" \
		-backend-config="unlock_method=$$(yq eval '.terraform.$(TARGET).backend_config.unlock_method' $(COMBINED_VARS))" \
		-backend-config="retry_wait_min=$$(yq eval '.terraform.$(TARGET).backend_config.retry_wait_min' $(COMBINED_VARS))"

tf-validate: tf-init
	terraform -chdir=$(TF_DIRECTORY)/$(TARGET) validate

tf-plan: tf-init $(GENERATED_GROUP_TFVARS_JSON)
	terraform -chdir=$(TF_DIRECTORY)/$(TARGET) plan -out=tfplan.$(TARGET).out -var-file=../../deployment/$(GENERATED_GROUP_TFVARS_JSON)

tf-apply: tf-init $(GENERATED_GROUP_TFVARS_JSON)
	terraform -chdir=$(TF_DIRECTORY)/$(TARGET) apply tfplan.$(TARGET).out

tf-output: tf-init $(GENERATED_GROUP_TFVARS_JSON)
	terraform -chdir=$(TF_DIRECTORY)/$(TARGET) output -json

tf-destroy: tf-init $(GENERATED_GROUP_TFVARS_JSON)
	@echo "WARNING: This will DESTROY all resources managed by this Terraform configuration!"
	@read -p "Are you absolutely sure you want to destroy? (yes/no): " CONFIRM && [ "$$CONFIRM" = "yes" ] || exit 1
	terraform -chdir=$(TF_DIRECTORY)/$(TARGET) destroy -var-file=../deployment/$(GENERATED_GROUP_TFVARS_JSON)

a-ping: $(SSH_PRIVATE_KEY) $(GENERATED_ANSIBLE_VARS) $(ANSIBLE_INVENTORY)
	ansible --extra-vars "@$(GENERATED_ANSIBLE_VARS)" -i $(ANSIBLE_INVENTORY) all -m ping

a-fai-setup: $(SSH_PRIVATE_KEY) $(GENERATED_ANSIBLE_VARS) $(ANSIBLE_INVENTORY)
	ansible-playbook -i $(ANSIBLE_INVENTORY) --extra-vars "@$(GENERATED_ANSIBLE_VARS)" \
		$(ANSIBLE_DIRECTORY)/playbooks/fai/post-setup.yml \
		-e target_hosts=$(TARGET) \
		--ask-become-pass

a-k3s-install: $(SSH_PRIVATE_KEY) $(GENERATED_ANSIBLE_VARS) $(ANSIBLE_INVENTORY)
	$(eval GENERATED_GROUP_VARS := build/$(TARGET).ansible.vars.yaml)
	@$(MAKE) $(GENERATED_GROUP_VARS) TARGET=$(TARGET)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/k3s/install.yml \
		--extra-vars "@../deployment/$(GENERATED_ANSIBLE_VARS)" \
		--extra-vars "@../deployment/$(GENERATED_GROUP_VARS)" \
	    -e target_hosts=$(TARGET)


a-k3s-reboot: $(SSH_PRIVATE_KEY) $(GENERATED_ANSIBLE_VARS) $(ANSIBLE_INVENTORY)
	$(eval GENERATED_GROUP_VARS := build/$(TARGET).ansible.vars.yaml)
	@$(MAKE) $(GENERATED_GROUP_VARS) TARGET=$(TARGET)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/k3s/reboot.yml \
		--extra-vars "@../deployment/$(GENERATED_ANSIBLE_VARS)" \
		--extra-vars "@../deployment/$(GENERATED_GROUP_VARS)" \
	    -e target_hosts=$(TARGET)

a-k3s-reset: $(SSH_PRIVATE_KEY) $(GENERATED_ANSIBLE_VARS) $(ANSIBLE_INVENTORY)
	$(eval GENERATED_GROUP_VARS := build/$(TARGET).ansible.vars.yaml)
	@$(MAKE) $(GENERATED_GROUP_VARS) TARGET=$(TARGET)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/k3s/reset.yml \
		--extra-vars "@../deployment/$(GENERATED_ANSIBLE_VARS)" \
		--extra-vars "@../deployment/$(GENERATED_GROUP_VARS)" \
	    -e target_hosts=$(TARGET)

a-k3s-upgrade: $(SSH_PRIVATE_KEY) $(GENERATED_ANSIBLE_VARS) $(ANSIBLE_INVENTORY)
	$(eval GENERATED_GROUP_VARS := build/$(TARGET).ansible.vars.yaml)
	@$(MAKE) $(GENERATED_GROUP_VARS) TARGET=$(TARGET)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/k3s/upgrade.yml \
		--extra-vars "@../deployment/$(GENERATED_ANSIBLE_VARS)" \
		--extra-vars "@../deployment/$(GENERATED_GROUP_VARS)" \
	    -e target_hosts=$(TARGET)

a-k8s-configure: $(SSH_PRIVATE_KEY) $(GENERATED_ANSIBLE_VARS) $(ANSIBLE_INVENTORY)
	$(eval GENERATED_GROUP_VARS := build/$(TARGET).ansible.vars.yaml)
	@$(MAKE) $(GENERATED_GROUP_VARS) TARGET=$(TARGET)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/kubernetes/configure.yml \
		--extra-vars "@../deployment/$(GENERATED_ANSIBLE_VARS)" \
		--extra-vars "@../deployment/$(GENERATED_GROUP_VARS)" \
	    -e target_hosts=$(TARGET)

a-k8s-reset: $(SSH_PRIVATE_KEY) $(GENERATED_ANSIBLE_VARS) $(ANSIBLE_INVENTORY)
	$(eval GENERATED_GROUP_VARS := build/$(TARGET).ansible.vars.yaml)
	@$(MAKE) $(GENERATED_GROUP_VARS) TARGET=$(TARGET)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/kubernetes/reset.yml \
		--extra-vars "@../deployment/$(GENERATED_ANSIBLE_VARS)" \
		--extra-vars "@../deployment/$(GENERATED_GROUP_VARS)" \
	    -e target_hosts=$(TARGET)

a-k8s-uninstall: $(SSH_PRIVATE_KEY) $(GENERATED_ANSIBLE_VARS) $(ANSIBLE_INVENTORY)
	$(eval GENERATED_GROUP_VARS := build/$(TARGET).ansible.vars.yaml)
	@$(MAKE) $(GENERATED_GROUP_VARS) TARGET=$(TARGET)
	ANSIBLE_CONFIG=$(ANSIBLE_DIRECTORY)/ansible.cfg ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_DIRECTORY)/playbooks/kubernetes/uninstall.yml \
		--extra-vars "@../deployment/$(GENERATED_ANSIBLE_VARS)" \
		--extra-vars "@../deployment/$(GENERATED_GROUP_VARS)" \
	    -e target_hosts=$(TARGET) \
		-e components=$(COMPONENTS)

