##
## This plugins adds some debugging tools to work on the Makefile
##

### Print the content of a variable
### e.g. make print-DOCKER_COMPONENTS
print-% : ; $(info $* is a $(flavor $*) variable set to [$($*)]) @true
