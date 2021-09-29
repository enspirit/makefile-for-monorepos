ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# We can see we copy here index.html and not app/index.html
# this is because we've overridden the build context in
# complex/makefile.mk
COPY index.html /usr/share/nginx/html
