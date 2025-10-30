INVENTORY := build/inventory.yml

INVENTORY_SOURCE := inventory
INVENTORY_SOURCE_DIRECTORIES := $(shell find $(INVENTORY_SOURCE) -type d)
INVENTORY_SOURCE_FILES := $(shell find $(INVENTORY_SOURCE) -type f)

ANSIBLE_INVENTORY := build/ansible.inventory.yml

SECRETS_FILE := secrets.yml

SCRIPTS_DIRECTORY := ../scripts
RENDER_DIRECTORY := $(SCRIPTS_DIRECTORY)/render_directory.py

SSH_PRIVATE_KEY := build/id_rsa

$(INVENTORY): $(INVENTORY_SOURCE) $(INVENTORY_SOURCE_FILES) $(INVENTORY_SOURCE_DIRECTORIES)
	python3 $(RENDER_DIRECTORY) $(INVENTORY_SOURCE) -v SECRETS $(SECRETS_FILE) > $@

$(ANSIBLE_INVENTORY): $(INVENTORY)
	cat $(INVENTORY) | yq '.ansible' > $@

$(SSH_PRIVATE_KEY): $(SECRETS_FILE)
	cat $(SECRETS_FILE) | yq '.ssh.private_key' > $@
	chmod 400 $@

.PHONY: a-ping
a-ping: $(SSH_PRIVATE_KEY) $(ANSIBLE_INVENTORY)
	ansible -i $(ANSIBLE_INVENTORY) all -m ping

