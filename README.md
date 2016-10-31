# Alpine MPICH

Docker image of Alpine Linux with  [MPICH](http://www.mpich.org/) -- portable implementation of Message Passing Interface (**MPI**) standard.
Designed for MPI program development and deployment.

For usage instruction, see the Docker Hub page of this image: 
[https://hub.docker.com/r/nlknguyen/alpine-mpich](https://hub.docker.com/r/nlknguyen/alpine-mpich/).

----
Automated build with Travis CI and push to Docker Hub

[![Build Status](https://travis-ci.org/NLKNguyen/alpine-mpich.svg?branch=master)](https://travis-ci.org/NLKNguyen/alpine-mpich)



`base image` ([Dockerfile](https://github.com/NLKNguyen/alpine-mpich/blob/master/Dockerfile)) : contains MPICH and essential build tools. Intended to be used as development environment for developing MPI programs.

`onbuild image` ([Dockerfile](https://github.com/NLKNguyen/alpine-mpich/blob/onbuild/Dockerfile)) : inherits base image with network setup for cluster. Can be used like base image but intended to be used to build image that contains compiled MPI program in order to deploy to a cluster.


----


## Feedback

Feedbacks are always welcome. For general comments, use the comment section at the bottom of this [image page](https://hub.docker.com/r/nlknguyen/alpine-mpich) on Docker Hub

## Issue

Use the GitHub repository issue

## Contributing

Suggestions and pull requests are awesome.
