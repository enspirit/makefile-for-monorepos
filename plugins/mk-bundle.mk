# Plugin to handle dependencies & bundling management

# Automatically find ruby & node components
NODE_COMPONENTS ?= $(shell find * -maxdepth 1 -mindepth 1 -name "package.json" -exec dirname {} \;)
RUBY_COMPONENTS ?= $(shell find * -maxdepth 1 -mindepth 1 -name "Gemfile" -exec dirname {} \;)

MK_BUNDLE_FILTER_OUT ?=

RUBY_COMPONENTS := $(filter-out $(MK_BUNDLE_FILTER_OUT),$(RUBY_COMPONENTS))
NODE_COMPONENTS := $(filter-out $(MK_BUNDLE_FILTER_OUT),$(NODE_COMPONENTS))

bundle: $(addsuffix .bundle,$(NODE_COMPONENTS)) $(addsuffix .bundle,$(RUBY_COMPONENTS))

# Create the correct target for node-based components
define make-node-targets
$1.bundle:: $1/node_modules
	@$(DOCKER_COMPOSE) exec -T $1 npm install

$1.outdated::
	@echo "No outdated target for node components"
endef
$(foreach component,$(NODE_COMPONENTS),$(eval $(call make-node-targets,$(component))))

# Create the correct target for ruby-based components
define make-ruby-bundle-targets
$1.bundle::
	@$(DOCKER_COMPOSE) exec -T $1 bundle install --gemfile Gemfile
	@$(DOCKER_COMPOSE) exec -T $1 bundle update --gemfile Gemfile

$1.outdated::
	@$(DOCKER_COMPOSE) exec -T $1 bundle outdated --filter-minor
endef
$(foreach component,$(RUBY_COMPONENTS),$(eval $(call make-ruby-bundle-targets,$(component))))

