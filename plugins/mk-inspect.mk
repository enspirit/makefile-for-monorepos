##
## This plugins adds some debugging tools to work on the Makefile
##

### Print the content of a variable
### e.g. make print-DOCKER_COMPONENTS
print-% : ; $(info $($*)) @true

CSV_DELIMITER := $(or ${CSV_DELIMITER},${CSV_DELIMITER},|)

inspect: inspect.header $(addsuffix .inspect,$(DOCKER_COMPONENTS))
inspect.header:
	@echo "name$(CSV_DELIMITER)dockerfile$(CSV_DELIMITER)context$(CSV_DELIMITER)deps"

define mk-debug-rules

# Dumps information about the component
$1.inspect:
	@echo "$1$(CSV_DELIMITER)$${$1_DOCKER_FILE}$(CSV_DELIMITER)$${$1_DOCKER_CONTEXT}$(CSV_DELIMITER)$${$1_DEPS}"
endef

$(foreach component,$(DOCKER_COMPONENTS),$(eval $(call mk-debug-rules,$(component))))

