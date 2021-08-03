## Better defaults for make (thanks https://tech.davis-hansson.com/p/make/)
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

###
### Generates a dynamic Makefile from the makefile.mk files that can be found
### in components folders
###
.build/bootstrap.mk: $(shell find * -name makefile.mk -maxdepth 1)
	@mkdir -p .build
	( $(foreach M,$?,echo '-include $M';) ) > $@
-include .build/bootstrap.mk

################################################################################
### Config variables
###

# Load them from an optional .env file
-include .env
.EXPORT_ALL_VARIABLES: ;

# Specify project name (used to prefix docker images names)
PROJECT := monorepo

# Specify which docker registry is to be used
DOCKER_REGISTRY := $(or ${DOCKER_REGISTRY},${DOCKER_REGISTRY},docker.io)

# Specify which docker tag is to be used
DOCKER_TAG := $(or ${DOCKER_TAG},${DOCKER_TAG},latest)

# Which command is used to build docker images
DOCKER_BUILD_CMD := docker buildx build

# Docker build extra options for all builds (optional)
DOCKER_BUILD_ARGS :=

## This is the list of components present in the project that will require a docker build
BUILD_COMPONENTS := base api

## This is the list of docker components present in the docker-compose project.
## Usually this contains the list of the project components + extras (mysql, postgresql, elasticsearch)
## that don't require a build
DOCKER_COMPONENTS := ${BUILD_COMPONENTS} mysql

## What components should be started when doing a make up/make restart
## Here we usually list only the "top" components. We indeed delegate to docker-compose
## to decide what is the full list. Example: if we have an api, and a database, we make sure
## that the api lists the database as a dependency (via depends_on in docker-compose files)
## and we only list the api in the list of UP_COMPONENTS
UP_COMPONENTS := api

################################################################################
### Images rules
###
.PHONY: images clean push-images pull-images

images: $(addsuffix .image,$(BUILD_COMPONENTS))
clean: $(addsuffix .clean,$(BUILD_COMPONENTS))

# Pushes all docker images of all components to the private registry
#
# An individual .push task exists on each component as well
push-images: $(addsuffix .push,$(BUILD_COMPONENTS))

# Pulls all docker images of all components from the private registry
#
# An individual .pull task exists on each component as well
pull-images: $(addsuffix .pull,$(BUILD_COMPONENTS))

define make-image-targets
.PHONY: $1.clean $1.push $1.pull

# Remove docker build assets
$1.clean:
	rm -rf .build/$1

# Build the image and touch the corresponding .log and .built files
$1.image:: .build/$1/Dockerfile.built
.build/$1/Dockerfile.built: $1/Dockerfile $(shell git ls-files $1)
	@mkdir -p .build/$1
	@echo
	@echo -e "--- Building $(PROJECT)/$1:${DOCKER_TAG} ---"
	${DOCKER_BUILD_CMD} ${DOCKER_BUILD_ARGS} -f $1/Dockerfile -t $(PROJECT)/$1:${DOCKER_TAG} ./$1 | tee .build/$1/Dockerfile.log
	touch .build/$1/Dockerfile.built

# Components can have dependencies on others thanks to the <t>_DEPS variables
# where <t> is the name of the component
.build/$1/Dockerfile.built: $(foreach dep,$($1_DEPS),.build/$(dep)/Dockerfile.built)

# Pushes the image to the private repository
$1.push: .build/$1/Dockerfile.pushed
.build/$1/Dockerfile.pushed: .build/$1/Dockerfile.built
	@if [ -z "$(DOCKER_REGISTRY)" ]; then \
		echo "No private registry defined, ignoring. (set DOCKER_REGISTRY or place it in .env file)"; \
		return 1; \
	fi
	@echo
	@echo -e "--- Pushing $(DOCKER_REGISTRY)/$(PROJECT)/$1:${DOCKER_TAG} ---"
	docker tag $(PROJECT)/$1:${DOCKER_TAG} $(DOCKER_REGISTRY)/$(PROJECT)/$1:${DOCKER_TAG}
	docker push $(DOCKER_REGISTRY)/$(PROJECT)/$1:${DOCKER_TAG} | tee -a .build/$1/Dockerfile.push.log
	touch .build/$1/Dockerfile.pushed

# Pull the latest image version from the private repository
$1.pull::
	docker pull $(DOCKER_REGISTRY)/$(PROJECT)/$1:${DOCKER_TAG}
	docker tag $(DOCKER_REGISTRY)/$(PROJECT)/$1:${DOCKER_TAG} ${PROJECT}/$1:${DOCKER_TAG}

endef
$(foreach component,$(BUILD_COMPONENTS),$(eval $(call make-image-targets,$(component))))

################################################################################
### Lifecycle rules
###

.PHONY: ps up restart down

# Shortcut over docker-compose ps
ps:
	docker-compose ps

# Puts the software up.
#
up: $(addsuffix .image,$(BUILD_COMPONENTS))
up: $(addsuffix .up,$(UP_COMPONENTS))
up:
	docker-compose ps

# Restarts the software without rebuilding images
#
# Faster than up
restart: $(addsuffix .restart,$(DOCKER_COMPONENTS))
	docker-compose ps

# Puts the entire software down.
#
# All docker containers are stopped.
down:
	docker-compose stop

define make-lifecycle-targets
.PHONY: $1.down $1.image $1.up $1.on $1.off $1.restart $1.logs $1.bash

# Shuts the component down
$1.down:
	docker-compose stop $1

# Builds the image
# We create an empty rule for all DOCKER_COMPONENTS
# but only the actual COMPONENTS implement the recipe
$1.image::

# Wakes the component up
$1.up: $1.image
	docker-compose up -d --force-recreate $1

# Wakes the component up using the last known image
$1.on:
	docker-compose up -d $1

# Alias for down
$1.off:
	docker-compose stop $1

# Restart the component the light way, i.e. without rebuilding the image
$1.restart:
	docker-compose stop $1
	docker-compose up -d $1

# SHow the logs in --follow mode
$1.logs:
	docker-compose logs -f $1

# Opens a bash on the component
$1.bash:
	docker-compose exec $1 bash
endef
$(foreach component,$(DOCKER_COMPONENTS),$(eval $(call make-lifecycle-targets,$(component))))
