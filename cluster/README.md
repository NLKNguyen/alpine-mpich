Alpine MPICH Cluster
====================

Scaffolding project structure for a MPI cluster using [Alpine MPICH](https://hub.docker.com/r/nlknguyen/alpine-mpich) Docker image. Architecturally compatible with *Docker Swarm Mode*. Include a runner script that automates Docker commands.

Original software targets:
- Docker Engine version 1.12.1
- Docker Compose version 1.8.0

# Quickstart

This is a quickstart guide of how you can typically use this setup to deploy MPI programs in a cluster of connected Docker containers. For further details, see the next sections.

0. Open a shell terminal where Docker Engine and Docker Compose are available (bash, zsh, etc. but **NOT** Windows's CMD or Powershell because the runner script has not been ported to those environment).

1. Clone this repository (or download zip file) 
    ```
    $ git clone https://github.com/NLKNguyen/alpine-mpich
    ```

2. Go to `cluster` directory: 
    ```
    $ cd alpine-mpich/cluster/
    ```

3. Put MPI program source code in `project` directory. There is a sample mpi_hello_world.c program  in the project directory, so let's just use this as an example.

4. Modify the `Dockerfile` to build the program inside the image. It already has instructions to build that program, so again, let's just leave it like that.

5. Use `cluster.sh` script to automate the Docker commands. The actual CLI commands that run will also be shown. List of possible arguments for this script is explained in another section below. For now, just simply spin up the cluster by the following command: 
    ```
    $ ./cluster.sh up size=5
    ```

6. Login to the master node:
    ```
    $ ./cluster.sh login
    ```

7. While in the master node, run the MPI hello world program:
    ```
    $ mpirun ./mpi_hello_world
    ```
    The host file that contains addresses of connected nodes is automatically updated at `/etc/opt/hosts` where Hydra, the process management system that MPICH uses, will look into by default. Therefore, no need to explicitly provide the host file, but if you want to do it manually:

    ```
    $ get_hosts > hosts
    $ mpirun -f hosts ./mpi_hello_world
    ```

# Architecture

![mpi cluster](https://cloud.githubusercontent.com/assets/4667129/19843876/c5b77c78-9ee3-11e6-8068-20e37f5e8655.png)

# Project structure
```
cluster
├── project             # source code directory
│   └── mpi_hello_world.c
├── Dockerfile          # Image specification
├── .env                # General configuration
├── docker-compose.yml  # Container orchestration 
└── cluster.sh          # Commands wrapper ultility
```

## project directory
Put all of the project source code in this directory. This is not a requirement and is entirely up to the Dockerfile that expects the location of source code in the host.  

## Dockerfile
Build the Docker image by specifying how to install additional packages and compile the programs. 

## .env file

Configuration file that contains environment variables for both `docker-compose.yml` and `cluster.sh`

## docker-compose.yml
Specify components in the network using Docker Compose script version 2

## cluster.sh script

Use this POSIX shell script to automate common commands on the cluster of MPI-ready Docker containers.

In your shell where Docker is available, navigate to the project directory.

To run the script directly, make sure the file has executable permission `chmod +x cluster.sh`
```
./cluster.sh [COMMAND] [OPTIONS]
```

Or regardless of executable permission

```
sh cluster.sh [COMMAND] [OPTIONS]
```

Examples where `[COMMAND]` can be:

----

**up**
```
./cluster.sh up size=10
```
It will:
- shutdown existing services before starting all the services
- spin up an image registry container
- build the image using the Dockerfile
- push the image to the registry
- spin up `n` containers using the image in the registry, where n is the provided size. 
    - 1 container serves as MPI master
    - n-1 containers serve as MPI workers.

The MPI containers will be distributed evenly accross the Docker Swarm cluster.

Once the cluster is ready, the master node can be accessed using SSH (an instruction will show after this command finish) or using `login` command (see below).  

----

**scale**
```
./cluster.sh scale size=20
```

- shutdown MPI containers
- start `n` MPI containers using the same image existing in the image registry.

----

**reload**
```
./cluster.sh reload size=20
```

- shutdown MPI containers
- rebuild image and push to existing image registry
- spin up `n` containers using the image in the registry, where n is the provided size. 
    - 1 container serves as MPI master
    - n-1 containers serve as MPI workers.

----

**login**
```
./cluster.sh login
```

- login to the MPI master container's shell

----

**exec**
```
./cluster.sh exec [COMMAND]

ex:

./cluster.sh exec mpirun hostname
```

- execute command at master node

----

**list**
```
./cluster.sh list
```

- list running containers in the cluster

----

**down**
```
./cluster.sh down
```

- shutdown everything
