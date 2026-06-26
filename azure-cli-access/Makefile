TERRAFORM_DIR := terraform
SSH_KEY := id_rsa_azure

.PHONY: generate role join ssh-key clean-generated

# Render role.yaml and join.yaml from templates, substituting the current
# Azure subscription (via `az account show`) and the managed identity URI
# (from terraform output). Run `terraform apply` in ./terraform first.
generate: role join

role: role.yaml.tpl
	@command -v az >/dev/null || { echo "az CLI not found"; exit 1; }
	@command -v terraform >/dev/null || { echo "terraform not found"; exit 1; }
	@SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
	MANAGED_IDENTITY_ID=$$(terraform -chdir=$(TERRAFORM_DIR) output -no-color -raw managed_identity_id 2>/dev/null) && \
	case "$$MANAGED_IDENTITY_ID" in /subscriptions/*) ;; *) echo "managed_identity_id terraform output is missing — did you run 'terraform apply' in $(TERRAFORM_DIR)?"; exit 1 ;; esac && \
	export SUBSCRIPTION_ID MANAGED_IDENTITY_ID && \
	envsubst '$$SUBSCRIPTION_ID $$MANAGED_IDENTITY_ID' < role.yaml.tpl > role.yaml
	@echo "Wrote role.yaml"

join: join.yaml.tpl
	@command -v az >/dev/null || { echo "az CLI not found"; exit 1; }
	@SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
	export SUBSCRIPTION_ID && \
	envsubst '$$SUBSCRIPTION_ID' < join.yaml.tpl > join.yaml
	@echo "Wrote join.yaml"

ssh-key: $(SSH_KEY)

$(SSH_KEY):
	ssh-keygen -t rsa -b 4096 -f $(SSH_KEY) -C "azure-teleport-vm" -N ""

clean-generated:
	rm -f role.yaml join.yaml
