################################################################################
### This plugins allows you to have subcomponents.
###
### You can create subcomponents by adding a Dockerfile.{subname} in a component
### directory. The resulting image name will follow the format
### {project}/{component}.{subname}:{tag}
###
### Subcomponents automatically image rules like subcomponent but including
### their subname:
###
### * make {component}.{subname}.image
### * make {component}.{subname}.image.push
### * make {component}.{subname}.image.pull
### * make {component}.{subname}.image.scan
###
### Example:
###
### monorepo
### ├── ...
### └── frontend
###     ├── Dockerfile
###     └── Dockerfile.builder
### └── Makefile
###

## The list of sub-components (= full path of all {component}/Dockerfile.*)
DOCKER_SUB_COMPONENTS := $(shell find * -maxdepth 1 -mindepth 1 -name "Dockerfile.*")

###
### Arguments:
### $1 = component name
### $2 = dockerfile
### $3 = context
###
define subcomponent-factor
DOCKER_COMPONENTS += $1
$1_DOCKER_FILE := $2
$1_DOCKER_CONTEXT := $3
endef

$(foreach subcmp,$(DOCKER_SUB_COMPONENTS),\
	$(eval $(call subcomponent-factor,$(shell dirname $(subcmp))$(suffix $(subcmp)),$(subcmp),$(shell dirname $(subcmp)))))
