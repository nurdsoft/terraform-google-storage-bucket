## -----------------------------------------------------------------------------
## Make targets to provide a consistent user experience when running Terraform.
## -----------------------------------------------------------------------------

# Static variables.
TF_PLAN_FILEPATH=plan.tfplan

# Dynamic variables
COMP?=simple

define DEFAULT_PLAN_ARGS
-no-color -input=false \
-out=${TF_PLAN_FILEPATH} \
${DEFAULT_ARGS}
endef

define DEFAULT_APPLY_ARGS
--auto-approve -input=false \
${DEFAULT_ARGS}
endef

# Avoid name collisions between targets and files.
.PHONY: help fmt init validate plan apply plan-destroy destroy clean 

# A target to format and present all supported targets with their descriptions.
help: Makefile
	@sed -n 's/^##//p' $<

## fmt          : Run terraform fmt.
fmt:
	terraform -chdir=${COMP} fmt -check=true -diff

## init         : Run terraform init.
init:
	terraform -chdir=${COMP} init

## validate     : Run terraform validate.
validate:
	terraform -chdir=${COMP} validate -no-color

## plan         : Run terraform plan for the provided service.
plan: clean fmt init validate
	terraform -chdir=${COMP} plan ${DEFAULT_PLAN_ARGS} -input=false

## apply        : Run terraform apply for the provided service.
apply:
	terraform -chdir=${COMP} apply ${DEFAULT_APPLY_ARGS}

## plan-destroy : Run terraform plan destroy for the provided service.
plan-destroy: clean 
	terraform -chdir=${COMP} plan -destroy -no-color ${DEFAULT_PLAN_ARGS} -input=false

## destroy      : Run terraform destroy for the provided service.
destroy: 
	terraform -chdir=${COMP} destroy -auto-approve

## clean        : Find and remove all the temporary files
clean:
	@find . -name ".terraform" -type d -print0 | xargs -0 -I {} rm -rf "{}"
	@find . -name ".terraform.lock.hcl" -type f -print0 | xargs -0 -I {} rm -rf "{}"
	@find . -name "plan.tfplan" -type f -print0 | xargs -0 -I {} rm -rf "{}"