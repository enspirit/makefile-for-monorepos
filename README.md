# `make up` and go

## What is this?

This project provides a reusable Makefile for software architectures based on micro services that use docker extensively and are organised as monorepositories.
Everything else apart from the Makefile is just us showcasing its usage and capabilities.

## Why?

At Enspirit for some time we have embraced *docker*, *docker-compose* and monorepositories and our team is usually rotating between 4 to 5 projects at a time.

We wanted a way to have reproducible builds, but also tooling allowing us to work the same way on all these different projects.

We try to apply the agile rule saying that only one command is needed to start a project from a fresh clone.

This Makefile is our way of achieving that goal. Why don't you see for yourself:

```
git clone git@github.com:enspirit/monorepo-example.git
cd monorepo-example
make up
```

_n.b. You need *docker*, *docker-compose* and *make* installed locally._

## Features

* it manages builds of all components' docker images
* it allows managing inter-component dependencies
* it only rebuilds images whose source code or dependencies have changed
* it manages lifecycles of the various components (start, stop, restart, ...)
* it pushes and pulls images from repositories
* it provides extension points for standard rules (e.g. unit testing, cleaning, ...)
* it also allows the extension of the makefile with ad-hoc rules for specific components

## How do I install this on my own project?

The only thing you need to get started is to copy our Makefile from this repo and place it in your own monorepository project and follow the [conventions below](#conventions).

We all love those one-liner installation methods, so here you go:

_n.b. make sure you are inside the folder of your monorepo project._

Option 1, with wget:
```bash
wget https://raw.githubusercontent.com/enspirit/monorepo-example/master/Makefile
```

Option 2, with curl:
```bash
curl https://raw.githubusercontent.com/enspirit/monorepo-example/master/Makefile -o Makefile
```

## Conventions

By following some conventions our makefile adds some magic. Let's consider the file
structure of this very repository:

```
monorepo-example
├── base                       # A component used as a base for others (dependency)
│   └── Dockerfile             # ... with its Dockerfile
├── api                        # An api component
│   ├── Dockerfile             # ... with its Dockerfile extending the base image
│   ├── env                    #
│   │   └── devel.env          # Default env vars for the devel environment
│   ├── makefile.mk            # Extensions and ad-hoc rules for the component
│   └── ...                    #
├── frontend                   # Another component
|   └── Dockerfile             #
├── .env                       # Main environment variables including COMPOSE_FILE
├── docker-compose.base.yml    #
├── docker-compose.devel.yml   # Orchestration with docker-compose files
├── docker-compose.testing.yml #
├── Makefile                   # Our reusable makefile
└── config.mk                  # Specific configuration and global ad-hoc rules
```

1. All folders at level one will be considered *components* of the architecture as soon as they include a Dockerfile. It is the case in this example for *base*, *api* and *frontend*. For all of them you magically get all the [image rules](#per-component-image-rules).

2. All services defined in the docker-compose [currently enabled by the COMPOSE_FILE variable](https://docs.docker.com/compose/reference/envvars/#compose_file) automatically get the [lifecycle rules](#per-component-lifecycle-rules).

3. It provides 'magic' but it is still based on *make* so you can [configure or override](#configure-it) things and even [extend](#extend-it) them globally or on a component basis using `config.mk` and `makefile.mk` files. This allows you to extend rules without changing the original makefile so that you can get [bugfixes and improvements](#how-to-update)

## Configure it (optional)

The first time you run one of the Makefile's rules, it will create a config.mk where you can configure the name of your project (it defaults to your project's folder name). That name will be used as a prefix for all the subsequent images built.

Let's take this repository as an example. [We've used "monorepo" as a project name](config.mk#1) and we have 4 components: *api*, *base*, *frontend* and *tests*. The images built will be tagged monorepo/api:latest, monorepo/base:latest, etc...

You can override other things in your `config.mk` if our defaults are not to your taste. It's as simple as adding a line specifying which variable you want to override and providing its new value.

For instance to use your own private docker registry:
```
PROJECT := monorepo
DOCKER_REGISTRY := my.private.registry
```

Here is the list of variables you can override:

```
# Specify which docker tag is built (defaults to 'latest')
DOCKER_TAG :=

# Which command is used to build docker images (defaults to 'docker build')
DOCKER_BUILD :=

# Which command is used for docker-compose (defaults to 'docker-compose')
DOCKER_COMPOSE :=

# Docker build extra options for all builds (optional)
DOCKER_BUILD_ARGS :=

# Which command is used to scan docker images (defaults to 'docker scan')
DOCKER_SCAN := 

# Docker scan extra options (optional)
DOCKER_SCAN_ARGS := 

# Should docker scan fail on errors (true/false, defaults to 'true')
# When running the `make scan` rule with this setting to true
# the scan will stop at the first image with vulnerabilities
DOCKER_SCAN_FAIL_ON_ERR := 
```

It is important to note that these variables can also be overriden by exporting environment variables, e.g. `DOCKER_TAG=test make images`.

## Extend it

You can add global rules in your `config.mk` and ad-hoc component rules in `makefile.mk` files.

As soon as you create one of them it will be included automatically. You can see an example of that in [tests/makefile.mk](tests/makefile.mk) where we created a `tests.run` rule that runs the unit tests for this project.

*N.B. We recommend keeping all custom rules prefixed with the name of the component.*

## Reference of available make rules

### General image rules

* `make images`: builds all the docker images for the repo's components
* `make clean`: removes the sentinel files (see [Sentinel files](#sentinel-files))
* `make push-images`: pushes all images to the docker registry (after building them if necessary)
* `make pull-images`: pulls all images from the docker registry
* `make scan`: scan all images for vulnerabilities

### General lifecycle rules

* `make up`: starts the docker-compose project
* `make down`: stops the docker-compose project
* `make restart`: restarts the docker-compose project
* `make ps`: alias for docker-compose ps

### General standard rules

* `make tests`: Runs all tests (equivalent to `tests.unit` then `tests.integration`)
* `make tests.unit`: Runs all unit tests on all components
* `make tests.integration`: Runs all integration tests on all components

### Per-component image rules

For every docker component in your repo, you can run:

* `make {component}.image`: builds the component's docker image
* `make {component}.clean`: removes the component's sentinel files (see [Sentinel files](#sentinel-files))
* `make {component}.pull`: pulls the component image from the docker registry
* `make {component}.push`: pushes the image to the registry, :warning: it also rebuilds the component if any files or dependencies have changed
* `make {component}.scan`: scans the component image for vulnerabilities

### Per-component lifecycle rules

* `make {component}.on`: starts the component
* `make {component}.off`: stops the component
* `make {component}.up`: forces the recreation of the container, :warning: it also rebuilds the component's image if any files or dependencies have changed
* `make {component}.down`: stops the component
* `make {component}.restart`: restarts the component (equivalent of `off` then `on`)
* `make {component}.logs`: tails the logs of the component
* `make {component}.bash`: gets a bash on the component

You might wonder why we have both `make {component}.up` and `make {component}.on`. The reason is that they behave differently: the former will first rebuild the image when needed (if files or dependencies have changed) while the latter is just an alias for `docker-compose up -d component`.

> Ok, and the difference between `make {component}.down` and `make {component}.off`?

They behave exactly the same way and alias `docker-compose stop component`. It is just for  consistency: if we can start things with both `up` and `on` one would expect to have both `down` and `off`.

### Per-component standard rules

* `make {component}.tests`: Runs all tests for the component (equivalent to `{component}.tests.unit` then `tests.integration`)
* `make {component}.tests.unit`: Runs all the component's unit tests
* `make {component}.tests.integration`: Runs all the component's integration tests

These three rules are placeholder. Their recipe must be implemented in the components' `makefile.mk`.

For example consider the file [api/makefile.mk]:
```
api.tests.unit::
	@docker run monorepo/api npm run test:unit

api.tests.integration::
	@docker run monorepo/api npm run test:integration
```

## Advanced use cases

### Inter-component dependencies

Sometimes components depend on each other. There is an example of this in this repository: the *api* component depends on the *base* component [since its Dockerfile uses the base component as a base image](api/Dockerfile).

This can be expressed in the component's `makefile.mk` like we do in [api/makefile.mk](api/makefile.mk) by defining a variable `{component}_DEPS` that lists such dependencies.

In our example it means that *make* will know that the *base* component has to be built __before__ *api*. Not only that, but also any rebuild of *base* should retrigger a build of *api*.

## FAQ

**Question:** I'd love to use `make {component}.bash` but my image does not include bash (for instance: alpine-based)

**Answer** You can override the shell that is run by creating a `{component}_SHELL` override. [See our example](api/makefile.mk#2).

## Under the hood

### Sentinel files

First a little quote from [make's user manual](https://www.gnu.org/software/make/manual/html_node/Rules.html):

> A *rule* appears in the makefile and says when and how to remake certain files, called the rule's *targets* (most often only one per rule). It lists the other files that are the *prerequisites* of the target, and the *recipe* to use to create or update the target.

Now let's look at a makefile such as:

```make
component.image: component/Dockerfile
  docker build -t component component/
```

`component.image` is the rule, `component/Dockerfile` is a prerequisite and the recipe is the second line with `docker build ...`. But what about the *target*?

Well, since `docker build` does not produce any file we don't really have a real target here, it is what is called a [phony target](https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html#Phony-Targets).

And the 'problem' with a phony target is that its recipe will be executed every time the rule is called. That is: the example makefile would re-run docker build every single time.

> What's the problem? docker build has a cache mechanism.

Yes and with [buildkit](https://docs.docker.com/develop/develop-images/build_enhancements/) it's getting even better.

But on monorepos with a lot of components we can save precious seconds by not re-running 'docker build' for components that haven't changed. That also allows us to rely on `make up` to decide which components need rebuildind before starting the docker-compose project.

> Ok, now what about those sentinels?

Sentinels are files that we can use to tell make when a rebuild is needed.
Let's look at an example:

```make
component.image: component/.built

component/.built: component/Dockerfile
  docker build -t component component/
  touch component/.built
```

Here as you can see we have now two rules: `component.image` and `component/.built`.

`component.image` has one prerequisite: `component/.built`.
`component/.built` also has one prerequisite: `component/Dockerfile`.

You can also see that the first rule does not have a recipe and that our second rule ['touches'](https://man7.org/linux/man-pages/man1/touch.1.html) the `component/.built` after building the docker image.

> Now what does this do?

Well let's look again at some of make's user manual:

> A normal prerequisite makes two statements: first, it imposes an order in which recipes will be invoked: the recipes for all prerequisites of a target will be completed before the recipe for the target is run. Second, it imposes a dependency relationship: if any prerequisite is newer than the target, then the target is considered out-of-date and must be rebuilt.

In other terms this means that since the recipe that builds our docker image finishes by touching the sentinel file, make will know:
* if the file is there, it doesn't have to build the image again
* if our sentinel file is older than our Dockerfile (the prerequisite for our sentinel), then we do need a rebuild.

Our Makefile is using this in the following ways:

* `make {component}.image` uses a prerequisite: `.build/{component}/Dockerfile.built` (a sentinel file)
* For every component we generate a `.build/{component}/Dockerfile.built` rule.
* That rule produces the sentinel file after building the image, like in the example above.
* When listing [inter component dependencies](#inter-component-dependencies) we generate additional prerequisites that use the dependencies' sentinels as prerequisites. This way we can ensure that our dependent images rebuild when their dependencies change.
* `make {component}.push` is another example of such usage. It lists `.build/{component}/Dockerfile.pushed` as a prerequisite. The rule for it, in turn, lists `.build/{component}/Dockerfile.built` as a prerequisite. This means that if you already pushed your image and that none of its files (nor dependencies) have changed: there is no need to push it again.
