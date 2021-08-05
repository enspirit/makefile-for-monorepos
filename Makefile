## Better defaults for make (thanks https://tech.davis-hansson.com/p/make/)
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

################################################################################
### Automatically include components' extensions and ad-hoc rules (makefile.mk)
###
-include */makefile.mk

################################################################################
### Config variables
###

# Load them from an optional .env file
-include .env
.EXPORT_ALL_VARIABLES: ;

# Include the config
-include config.mk
config.mk:
	@echo "PROJECT := ${shell basename ${PWD}}" > config.mk

# Docker registry to be used
DOCKER_REGISTRY := $(or ${DOCKER_REGISTRY},${DOCKER_REGISTRY},docker.io)

# Specify which docker tag is to be used
DOCKER_TAG := $(or ${DOCKER_TAG},${DOCKER_TAG},latest)

# Which command is used to build docker images
DOCKER_BUILD := $(or ${DOCKER_BUILD},${DOCKER_BUILD},docker build)

# Docker build extra options for all builds (optional)
DOCKER_BUILD_ARGS :=

# Which command is used to scan docker images
DOCKER_SCAN := $(or ${DOCKER_SCAN},${DOCKER_SCAN},docker scan)

# Docker scan extra options
DOCKER_SCAN_ARGS :=

# Docker scan extra options
DOCKER_SCAN_FAIL_ON_ERR := $(or ${DOCKER_SCAN_FAIL_ON_ERR},${DOCKER_SCAN_FAIL_ON_ERR},true)

# Which command is used for docker-compose (you can switch from 'docker-compose' to 'docker compose')
# by overriding this in your config.mk
DOCKER_COMPOSE := $(or ${DOCKER_COMPOSE},${DOCKER_COMPOSE},docker-compose)

## The list of components being docker based (= component folder includes a Dockerfile)
DOCKER_COMPONENTS := $(DOCKER_COMPONENTS) $(shell find * -name "Dockerfile" -maxdepth 1 -exec dirname {} \;)

## The list of services defined in the (enabled) docker-compose files
COMPOSE_SERVICES := $(shell command -v $(DOCKER_COMPOSE) && $(DOCKER_COMPOSE) config --services 2>/dev/null || true)

################################################################################
### Automatically include plugins when present
###

MK_PLUGINS_DIR := $(or ${MK_PLUGINS_DIR},${MK_PLUGINS_DIR},.mkplugins)
-include $(MK_PLUGINS_DIR)/*.mk

################################################################################
### Image rules
###
.PHONY: images clean images.push images.pull images.scan

images: $(addsuffix .image,$(DOCKER_COMPONENTS))
clean:: $(addsuffix .clean,$(DOCKER_COMPONENTS))

# Pushes all docker images of all components to the private registry
#
# An individual .image.push task exists on each component as well
images.push: $(addsuffix .image.push,$(DOCKER_COMPONENTS))

# Pulls all docker images of all components from the private registry
#
# An individual .image.pull task exists on each component as well
images.pull: $(addsuffix .image.pull,$(DOCKER_COMPONENTS))

# Scan docker images for vulnerabilities
#
# An individual .image.scan task exists on each component as well
images.scan: $(addsuffix .image.scan,$(DOCKER_COMPONENTS))

###
### Arguments:
### $1: component name
### $2: Dockerfile
### $3: docker build context
###
define make-image-rules

.PHONY: $1.clean $1.image $.image.push $1.image.pull $1.image.scan

$1_DOCKER_FILE := $(or ${$1_DOCKER_FILE},${$1_DOCKER_FILE},$2)
$1_DOCKER_CONTEXT := $(or ${$1_DOCKER_CONTEXT},${$1_DOCKER_CONTEXT},$3)

# Remove docker build assets
$1.clean::
	@rm -rf .build/$1

# Build the image and touch the corresponding .log and .built sentinel files
$1.image:: .build/$1/Dockerfile.built
.build/$1/Dockerfile.built: $($1_DOCKER_FILE) $(shell git ls-files $1 | grep -v makefile.mk | sed 's/ /\\ /g')
	@mkdir -p .build/$1
	@echo -e "--- Building $(PROJECT)/$1:${DOCKER_TAG} ---"
	@${DOCKER_BUILD} ${DOCKER_BUILD_ARGS} ${$1_DOCKER_BUILD_ARGS} -f $${$1_DOCKER_FILE} -t $(PROJECT)/$1:${DOCKER_TAG} $${$1_DOCKER_CONTEXT} | tee .build/$1/Dockerfile.log
	@touch .build/$1/Dockerfile.built

# Components can have dependencies on others thanks to the <t>_DEPS variables
# where <t> is the name of the component
.build/$1/Dockerfile.built: $(foreach dep,$($1_DEPS),.build/$(dep)/Dockerfile.built)

# Scans the image for vulnerabilities
$1.image.scan:: $1.image
	@echo -e "--- Scanning $(PROJECT)/$1:${DOCKER_TAG} for vulnerabilities ---"
	@${DOCKER_SCAN} ${DOCKER_SCAN_ARGS} $(PROJECT)/$1:${DOCKER_TAG} || !${DOCKER_SCAN_FAIL_ON_ERR}

# Pushes the image to the private repository
$1.image.push: .build/$1/Dockerfile.pushed
.build/$1/Dockerfile.pushed: .build/$1/Dockerfile.built
	@if [ -z "$(DOCKER_REGISTRY)" ]; then \
		echo "No private registry defined, ignoring. (set DOCKER_REGISTRY or place it in .env file)"; \
		return 1; \
	fi
	@echo
	@echo -e "--- Pushing $(DOCKER_REGISTRY)/$(PROJECT)/$1:${DOCKER_TAG} ---"
	@docker tag $(PROJECT)/$1:${DOCKER_TAG} $(DOCKER_REGISTRY)/$(PROJECT)/$1:${DOCKER_TAG}
	@docker push $(DOCKER_REGISTRY)/$(PROJECT)/$1:${DOCKER_TAG} | tee -a .build/$1/Dockerfile.push.log
	@touch .build/$1/Dockerfile.pushed

# Pull the latest image version from the private repository
$1.image.pull::
	@echo
	@echo -e "--- Pulling $(DOCKER_REGISTRY)/$(PROJECT)/$1:${DOCKER_TAG} as ${PROJECT}/$1:${DOCKER_TAG} ---"
	@docker pull $(DOCKER_REGISTRY)/$(PROJECT)/$1:${DOCKER_TAG}
	@docker tag $(DOCKER_REGISTRY)/$(PROJECT)/$1:${DOCKER_TAG} ${PROJECT}/$1:${DOCKER_TAG}

endef
$(foreach component,$(DOCKER_COMPONENTS),$(eval $(call make-image-rules,$(component),$(component)/Dockerfile,$(component))))

################################################################################
### Standard rules
###

.PHONY: tests tests.unit tests.integration

tests: tests.unit tests.integration

# Run unit tests on all components
#
# An individual .test.unit task exists on each component as well
tests.unit: $(addsuffix .tests.unit,$(DOCKER_COMPONENTS))

# Run integration tests on all components
#
# An individual .test.integration task exists on each component as well
tests.integration: $(addsuffix .tests.integration,$(DOCKER_COMPONENTS))

define make-standard-rules

.PHONY: $1.tests $1.tests.unit $1.tests.integration

# Runs all unit and integration tests
$1.tests: $1.tests.unit $1.tests.integration

# Placeholder for the running of unit tests, you can override that in your component's makefile.mk
$1.tests.unit::

# Placeholder for the running of integration tests, you can override that in your component's makefile.mk
$1.tests.integration::

endef
$(foreach component,$(DOCKER_COMPONENTS),$(eval $(call make-standard-rules,$(component))))

################################################################################
### Lifecycle rules
###

.PHONY: ps up restart down

# Shortcut over docker-compose ps
ps:
	@$(DOCKER_COMPOSE) ps

# Puts the software up.
#
up: $(addsuffix .image,$(DOCKER_COMPONENTS))
up:
	@$(DOCKER_COMPOSE) up -d
	@$(DOCKER_COMPOSE) ps

# Restarts the software without rebuilding images
#
# Faster than up
restart:
	@$(DOCKER_COMPOSE) restart

# Puts the entire software down.
#
# All docker containers are stopped.
down:
	@$(DOCKER_COMPOSE) stop

define make-lifecycle-rules
.PHONY: $1.down $1.image $1.up $1.on $1.off $1.restart $1.logs $1.bash

# Shuts the component down
$1.down:
	@$(DOCKER_COMPOSE) stop $1

# Builds the image
# We create an empty rule for all DOCKER_COMPONENTS
# but only the actual COMPONENTS implement the recipe
$1.image::

# Wakes the component up
$1.up: $1.image
	@$(DOCKER_COMPOSE) up -d --force-recreate $1

# Wakes the component up using the last known image
$1.on:
	@$(DOCKER_COMPOSE) up -d $1

# Alias for down
$1.off:
	@$(DOCKER_COMPOSE) stop $1

# Restart the component the light way, i.e. without rebuilding the image
$1.restart:
	@$(DOCKER_COMPOSE) stop $1
	@$(DOCKER_COMPOSE) up -d $1

# SHow the logs in --follow mode
$1.logs:
	@$(DOCKER_COMPOSE) logs -f $1

# Opens a bash on the component
$1_SHELL := $(or ${$1_SHELL},${$1_SHELL},bash)
$1.bash:
	@$(DOCKER_COMPOSE) exec $1 $$($1_SHELL)
endef
$(foreach component,$(COMPOSE_SERVICES),$(eval $(call make-lifecycle-rules,$(component))))
