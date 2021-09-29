# We use a subfolder as context rather than the default one
complex_DOCKER_CONTEXT = complex/app

# We pass some build args to docker
complex_DOCKER_BUILD_ARGS = --build-arg BASE_IMAGE=nginx:alpine

# We define prerequisite ourselves
complex_PREREQUISITES += complex/app/index.html

# How to generate the index.html file
complex/app/index.html: complex/app/index.html.tpl
	@BUILD_TIME=`date` envsubst < $< > $@
