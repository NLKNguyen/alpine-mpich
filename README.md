# Alpine-MPICH
* `3.2`, `latest` ([Dockerfile](https://github.com/NLKNguyen/alpine-mpich/blob/master/Dockerfile))

Docker image of Alpine Linux with latest version of [MPICH](http://www.mpich.org/) -- portable implementation of Message Passing Interface (**MPI**) standard.

#### Include:  
  * MPICH compiler (the version is according to the tag version)
  * build-base package (gcc, g++, make, wget, curl, etc.)
  * common networking packages (openssh, nfs-utils)
  * default user `alpine` (sudoer without password)
  * default working directory `/project` (owned by default user)
    * to be mounted to a host's directory when developing a MPI program (see Usage)

The image is available [here](https://hub.docker.com/r/nlknguyen/alpine-mpich/) at DockerHub and is automatically rebuilt by changes on [this](https://github.com/NLKNguyen/alpine-mpich) GitHub repository. This image is intended for developing projects that use MPICH and unlikely to be suitable for developing MPICH itself.

# Usage

## For Development

At the directory of your MPI project, run:

```
$ docker run --rm -it -v ${PWD}:/project nlknguyen/alpine-mpich
```
After downloading the image to the cache in your system for the first time, it will fire up a Docker container based on this image, and without additional argument it drops you in an interactive shell (ASH)  where you can run `mpicc`, `mpiexec`, or any softwares available in the container. Your project directory is mounted to `/project` directory inside the container so that the programs in the container can have effects on your project directory. This way you can develop your MPI program using any editor in any host OS and use this Docker container to compile and run the MPI program. 

Argument explanation:
* `--rm` remove the container after the program is finished.
* `-it` open an interactive terminal session (see [-i -t](https://docs.docker.com/engine/reference/run/) for details)
* `-v ${PWD}:/project` volume mount the current directory `${PWD}` where your shell is at, to the directory `/project` inside the container based on this `nlknguyen/alpine-mpich` image. Alternatively, `-v ${PWD}:${PWD}` also has the same effect since `/project` is the default working directory of the container, but if you extend the image or customize the build, that might not hold true.

*Follow general guidelines for using Docker container*

## Extending the Image
It is common that you need to install/remove packages, add compiled program, configure network, or any administration task. You can do those with this image just like you can do with any other Docker images. Below is a simple example. See Docker documentation for details.

* Example: add packages
```Dockerfile
FROM nlknguyen/alpine-mpich:3.2

RUN sudo apk add --no-cache valgrind gdb

CMD ["/bin/ash"]
```

Some **environment variables** you can use:
- `DEFAULT_USER` *non-root user who is a sudoer without password. Default=`alpine`*
- `WORKING_DIRECTORY` *main working directory owned by default user. Default=`/project`*

## Build Customization

These are available Docker **build arguments** to customize the build:
- `REQUIRED_PACKAGES` *space-separated names of packages to be installed from Alpine main [package repository](http://pkgs.alpinelinux.org/packages) before downloading and installing MPICH. Default=`"sudo build-base openssh nfs-utils"`*
- `MPICH_VERSION` *to find which version of MPICH to download from [here](http://www.mpich.org/static/downloads/). Default=`"3.2"`*
- `MPICH_CONFIGURE_OPTIONS` *to be passed to `./configure` in MPICH source directory. Default=`"--disable-fortran"`*
- `MPICH_MAKE_OPTIONS` *to be passed to `make` after the above command. Default is empty*

*See MPICH documentation for available options*

Should you need more than that, you need to change the Dockerfile yourself or send suggestion/pull requests to this GitHub repository.

# Feedback

Feedbacks are always welcome. For general comments, use the comment section at the bottom of this image page on DockerHub

## Issue

Use the GitHub repository issue

## Contributing

Suggestions and pull requests are awesome.
