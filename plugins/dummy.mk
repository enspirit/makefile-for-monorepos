################################################################################
### This an example of a plugin.
###
### It adds a general rule `dummy`
### and a component ad-hoc rule, `{component}.dummy.example`
###

# Subscribe the plugin
$(eval $(call mk-plugin-subscribe) dummy)

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))

# Print info about the plugin
.PHONY: dummy.info
dummy.info:
	@head -n 6 < $(mkfile_path)

.PHONY: dummy
dummy: $(addsuffix .dummy.example,$(DOCKER_COMPONENTS))

# Defines the following rules for each component:
#
# - {component}.dummy.example: does something cool
define make-dummy-targets

.PHONY: $#.dummy.example

$1.dummy.example:
	@echo "Some dummy example for $1"

endef
$(foreach component,$(DOCKER_COMPONENTS),$(eval $(call make-dummy-targets,$(component))))
