# Makefile for monorepos

## What is this?

This project is

## Ok for the what. Now, why?


## How do I use this?

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

## Usage:

### General rules

* `make images`: builds all the docker images for the repo's components
* `make up`: starts the (docker-compose) project
* `make down`: stops the (docker-compose) project
* `make restart`: restarts the (docker-compose) project
* `make ps`: alias for docker-compose ps
* `make clean`: removes the sentinel files (see [Sentinel files](#sentinel-files))

### Per-component rules

For every docker component in your repo, you can run:

* `make {component}.image`: builds the component's docker image
* `make {component}.clean`: removes the component's sentinel files (see [Sentinel files](#sentinel-files))
* `make {component}.on`: starts the component
* `make {component}.off`: stops the component
* `make {component}.up`: forces the recreation of the container, :warning: it also rebuilds the component if files/dependencies have changed
* `make {component}.down`: stops the component
* `make {component}.restart`: restarts the component
* `make {component}.logs`: tails the logs of the container
* `make {component}.bash`: gets a bash on the container
* `make {component}.pull`: pulls the component image from the docker registry
* `make {component}.push`: pushes the image to the registry, , :warning: it also rebuilds the component if files/dependencies have changed

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

And the "problem" with a phony target is that its recipe will be executed every time the rule is run. That is: the example makefile would re-run docker build every single time.

> What's the problem? docker build has a cache mechanism.

Yes and with [buildkit](https://docs.docker.com/develop/develop-images/build_enhancements/) it's getting even better.

But on monorepo with a lot of components we can save previous seconds by not re-running 'docker build' for components that haven't changed. That also allows us to rely on `make up` to decide which components need to rebuild before starting the docker-compose project.

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

In other terms this means that since the recipe that builds our docker image finishes by touching the sentinel file, make will 1) know that if the file is there we don't need to build the image 2) that if our sentinel file is older than our Dockerfile (the prerequisite for our sentinel) then we do need a rebuild.

