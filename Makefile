.ONESHELL:
SHELL := /bin/bash
.PHONY: help set-env init update plan plan-destroy show graph apply output taint
# Strips 'build-' from the folder name and uses this as the storage folder in S3.
BUCKETKEY = $(shell basename "$$(pwd)" | sed 's/terraform-//')

help:

validate:
	@for i in $$(find -type f -name "*.tf" -exec dirname {} \; | grep -v "/test"); do \
        terraform validate "$$i"; \
        if [ $$? -ne 0 ]; then \
                echo "Failed Terraform .tf file validation"; \
                echo; \
                exit 1; \
        fi; \
    done

set-env:
	@if [ -z $(ENVIRONMENT) ]; then\
         echo "ENVIRONMENT was not set"; exit 10;\
     fi
	@echo -e "\nRemoving existing ENVIRONMENT.tfvars from local directory"
	@find . -maxdepth 1 -type f -name '*.tfvars' ! -name example_ENV.tfvars -exec rm -f {} \;
	@echo -e "\nPulling fresh $(ENVIRONMENT).tfvars from s3://$(AWS_STATE_BUCKET)/terraform/$(BUCKETKEY)/"
	@aws s3 cp s3://$(AWS_STATE_BUCKET)/terraform/$(BUCKETKEY)/$(ENVIRONMENT).tfvars . --profile=$(AWS_PROFILE)

init: validate set-env
	@rm -rf .terraform/*
	@terraform init \
		-backend-config="region=$(AWS_REGION)" \
        -backend-config="bucket=$(AWS_STATE_BUCKET)" \
        -backend-config="profile=$(AWS_PROFILE)" \
        -backend-config="key=terraform/$(BUCKETKEY)/$(ENVIRONMENT).tfstate" \
        -backend-config="encrypt=1" \
        -backend-config="acl=private" \
        -backend-config="kms_key_id=$(AWS_KMS_ARN)"

update:
	@terraform get -update=true 1>/dev/null

plan: init update
	@terraform plan \
        -input=false \
        -refresh=true \
        -module-depth=-1 \
        -var-file=environments/$(ENVIRONMENT)/$(ENVIRONMENT).tfvars \
        -var-file=$(ENVIRONMENT).tfvars

plan-destroy: init update
	@terraform plan \
        -input=false \
        -refresh=true \
        -module-depth=-1 \
        -destroy \
        -var-file=environments/$(ENVIRONMENT)/$(ENVIRONMENT).tfvars \
        -var-file=$(ENVIRONMENT).tfvars

show: init
	@terraform show -module-depth=-1

graph:
	@rm -f graph.png
	@terraform graph -draw-cycles -module-depth=-1 | dot -Tpng > graph.png
	@shotwell graph.png

apply: init update
	@terraform apply \
        -input=true \
        -refresh=true \
        -var-file=environments/$(ENVIRONMENT)/$(ENVIRONMENT).tfvars \
        -var-file=$(ENVIRONMENT).tfvars

apply-target: init update
	@tput setaf 3; tput bold; echo -n "[INFO]   "; tput sgr0; echo "Specifically APPLY a piece of Terraform data."
	@tput setaf 3; tput bold; echo -n "[INFO]   "; tput sgr0; echo "Example to type for the following question: module.rds.aws_route53_record.master"
	@tput setaf 1; tput bold; echo -n "[DANGER] "; tput sgr0; echo "You are about to apply a new state."
	@tput setaf 1; tput bold; echo -n "[DANGER] "; tput sgr0; echo "This has the potential to break your infrastructure."
	@read -p "APPLY target: " DATA &&\
        terraform apply \
            -input=true \
            -refresh=true \
            -var-file=environments/$(ENVIRONMENT)/$(ENVIRONMENT).tfvars \
            -var-file=$(ENVIRONMENT).tfvars \
            -target=$$DATA

output: init update
	@echo "Example to type for the module: MODULE=module.rds.aws_route53_record.rds-master"
	@echo
	@if [ -z $(MODULE) ]; then\
        terraform output;\
     else\
        terraform output -module=$(MODULE);\
     fi

taint: init update
	@echo "Tainting involves specifying a module and a resource"
	@read -p "Module: " MODULE && \
        read -p "Resource: " RESOURCE && \
        terraform taint \
            -var-file=environments/$(ENVIRONMENT)/$(ENVIRONMENT).tfvars \
            -var-file=$(ENVIRONMENT).tfvars \
            -module=$$MODULE $$RESOURCE
	@echo "You will now want to run a plan to see what changes will take place"

destroy: init update
	@terraform destroy \
        -var-file=environments/$(ENVIRONMENT)/$(ENVIRONMENT).tfvars \
        -var-file=$(ENVIRONMENT).tfvars

destroy-target: init update
	@echo "Specifically destroy a piece of Terraform data."
	@echo
	@echo "Example to type for the following question: module.rds.aws_route53_record.rds-master"
	@echo
	@read -p "Destroy target: " DATA &&\
        terraform destroy \
        -var-file=environments/$(ENVIRONMENT)/$(ENVIRONMENT).tfvars \
        -var-file=$(ENVIRONMENT).tfvars \
        -target=$$DATA
