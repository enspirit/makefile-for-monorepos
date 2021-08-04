# Makefile for monorepos

## What is this?

This project is providing a reusable Makefile for docker projects organised as monorepositories.
Everything else next to that Makefile is just us showcasing its usage and capabilities.

## Ok for the what. Now, why?

At Enspirit we embraced docker, docker-compose and monorepositories a while ago and our team is usually rotating on 4 to 5 projects at a time.

We wanted a way to have reproducible builds but also a tooling allowing us to work the same way on all these different projects.

This Makefile allows us also to have a single verbiage and we don't have to remember the specific commands of `docker` or `docker-compose`, but also the several tests framework (`mocha`, `rspec`, ...) used or the package managers (`npm`, `gem`, ...).

This Makefile also provides us with an easy way of expressing dependencies between components.

## How?

By following some conventions, the makefile gives us some magic:

If a folder at the top level of the repository directly contains a Dockerfile, Makefile assumes that it is a component of the project & you magically get all the [image rules](#per-component-image-rules) for it.

You use docker-compose? Well, for every single service listed in there you will get all the [lifecycle rules](#per-component-lifecycle-rules) for it.

It provides 'magic' but it is still make so you can [configure](#configure-it) things, [override](#overrides-things) them and even [extend](#extend-it) it.

## How do I try this?

The only thing you need to get started is the Makefile from this repo, nothing else.
We all love those one-liner installation methods, so here you go: make sure you are inside the folder of your monorepo project and run:

Option 1, with wget:
```bash
wget https://raw.githubusercontent.com/enspirit/monorepo-example/master/Makefile
```

Option 2, with curl:
```bash
curl https://raw.githubusercontent.com/enspirit/monorepo-example/master/Makefile -o Makefile
```

## Configure it

The first time you run one of the Makefile's rules, it will create a config.mk where you can configure the name of your project (it defaults to your project's folder name). That name will be used as a prefix for all the images built.

Let's take this repository as an example. [We've used "monorepo" as a project name](config.mk#1) and we have 4 components: api, base, frontend & tests. The images built will be tagged monorepo/api:latest, monorepo/base:latest, etc...

## Override things

You can override many things in your `config.mk` if our defaults are not for your taste, it's as simple as adding a line in it specifying which variable you want to override and its new value.

For instance to use your own private docker registry:
```
PROJECT := monorepo
DOCKER_REGISTRY := my.private.registry
```

Here is the list of variables you can override:

```
# Specify which docker tag is built (defaults to latest)
DOCKER_TAG :=

# Which command is used to build docker images (defaults to docker build)
DOCKER_BUILD :=

# Which command is used for docker-compose (default to docker-compose)
DOCKER_COMPOSE :=

# Docker build extra options for all builds (optional)
DOCKER_BUILD_ARGS :=
```

It is important to note that these variables can also be overriden by exporting environment variables, e.g. `DOCKER_TAG=test make images`.

## Usage:

### General image rules

* `make images`: builds all the docker images for the repo's components
* `make clean`: removes the sentinel files (see [Sentinel files](#sentinel-files))
* `make push-images`: pushes all images to the docker registry (after building them if necessary)
* `make pull-images`: pulls all images from the docker registry

### General lifecycle rules

* `make up`: starts the docker-compose project
* `make down`: stops the docker-compose project
* `make restart`: restarts the docker-compose project
* `make ps`: alias for docker-compose ps

### Per-component image rules

For every docker component in your repo, you can run:

* `make {component}.image`: builds the component's docker image
* `make {component}.clean`: removes the component's sentinel files (see [Sentinel files](#sentinel-files))
* `make {component}.pull`: pulls the component image from the docker registry
* `make {component}.push`: pushes the image to the registry, :warning: it also rebuilds the component if any files or dependencies have changed

### Per-component lifecycle rules

* `make {component}.on`: starts the component
* `make {component}.off`: stops the component
* `make {component}.up`: forces the recreation of the container, :warning: it also rebuilds the component's image if any files or dependencies have changed
* `make {component}.down`: stops the component
* `make {component}.restart`: restarts the component
* `make {component}.logs`: tails the logs of the component
* `make {component}.bash`: gets a bash on the component

You might wonder why we have both `make {component}.up` and `make {component}.on`. The reason is that they behave differently: the former will first rebuild the image when needed (if files or dependencies have changed) while the latter is just an alias for `docker-compose up -d component`.

> Ok, and the difference between `make {component}.down` and `make {component}.off`?

They behave exactly the same way and alias `docker-compose stop component`. It is just for  consistency: if we can start things with both `up` and `on` one would expect to have both `down` and `off`.

## Sentinel files

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

But on monorepo with a lot of components we can save precious seconds by not re-running 'docker build' for components that haven't changed. That also allows us to rely on `make up` to decide which components need to rebuild before starting the docker-compose project.

> Ok, now what about those sentinels?

Sentinels are files that we can use to tell makefile when a rebuild is needed.
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

You can also see that the first rule does not have a recipe and that our second rules ["touches"](https://man7.org/linux/man-pages/man1/touch.1.html) the `component/.built` after building the docker image.

> Now what does this do?

Well let's look again at some of make's user manual:

> A normal prerequisite makes two statements: first, it imposes an order in which recipes will be invoked: the recipes for all prerequisites of a target will be completed before the recipe for the target is run. Second, it imposes a dependency relationship: if any prerequisite is newer than the target, then the target is considered out-of-date and must be rebuilt.

In other terms this means that since the recipe that builds our docker image finishes by touching the sentinel file, make will know:
* that if the file is there, it doesn't have to build the image again
* that if our sentinel file is older than our Dockerfile (the prerequisite for our sentinel), then we do need a rebuild.
