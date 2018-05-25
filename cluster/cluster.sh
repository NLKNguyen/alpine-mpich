#!/bin/sh

# The MIT License (MIT)
#
# Copyright (c) 2016 Nikyle Nguyen
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Origin: https://github.com/NLKNguyen/alpine-mpich

set -e

# shellcheck disable=SC1091
. ./.env

#######################
# TASK INDICATORS
COMMAND_UP=0
COMMAND_DOWN=0
COMMAND_RELOAD=0
COMMAND_SCALE=0
COMMAND_LOGIN=0
COMMAND_EXEC=0
COMMAND_LIST=0
COMMAND_CLEAN=0

# Default values if providing empty
SIZE=4

#############################################
usage ()
{
    echo " Alpine MPICH Cluster (for Docker Compose on single Docker host)"
    echo ""
    echo " USAGE: ./cluster.sh [COMMAND] [OPTIONS]"
    echo ""
    echo " Examples of [COMMAND] can be:"
    echo "      up: start cluster"
    echo "          ./cluster.sh up size=10"
    echo ""
    echo "      scale: resize the cluster"
    echo "          ./cluster.sh scale size=30"
    echo ""
    echo "      reload: rebuild image and distribute to nodes"
    echo "          ./cluster.sh reload size=15"
    echo ""
    echo "      login: login to Docker container of MPI master node for interactive usage"
    echo "          ./cluster.sh login"
    echo ""
    echo "      exec: execute shell command at the MPI master node"
    echo "          ./cluster.sh exec [SHELL COMMAND]"
    echo ""
    echo "      down: shutdown cluster"
    echo "          ./cluster.sh down"
    # echo ""
    # echo "      clean: remove images in the system"
    # echo "          ./cluster.sh clean"
    echo ""
    echo "      list: show running containers of cluster"
    echo "          ./cluster.sh list"
    echo ""
    echo "      help: show this message"
    echo "          ./cluster.sh help"
    echo ""
    echo "  "
}

HEADER="
         __v_
        (.___\/{
~^~^~^~^~^~^~^~^~^~^~^~^~"

down_all ()
{
    printf "\n\n===> CLEAN UP CLUSTER"

    printf "\n%s\n" "$HEADER"
    echo "$ docker-compose down"
    printf "\n"

    docker-compose down
}

up_registry ()
{
    printf "\n\n===> SPIN UP REGISTRY"

    printf "\n%s\n" "$HEADER"
    echo "$ docker-compose up -d registry"
    printf "\n"

    docker-compose up -d registry
}

generate_ssh_keys ()
{
    if [ -f ssh/id_rsa ] && [ -f ssh/id_rsa.pub ]; then
        return 0
    fi

    printf "\n\n===> GENERATE SSH KEYS \n\n"

    echo "$ mkdir -p ssh/ "
    printf "\n"
    mkdir -p ssh/

    echo "$ ssh-keygen -f ssh/id_rsa -t rsa -N ''"
    printf "\n"
    ssh-keygen -f ssh/id_rsa -t rsa -N ''
}

build_and_push_image ()
{
    printf "\n\n===> BUILD IMAGE"
    printf "\n%s\n" "$HEADER"
    echo "$ docker build -t \"$REGISTRY_ADDR:$REGISTRY_PORT/$IMAGE_NAME\" ."
    printf "\n"
    docker build -t "$REGISTRY_ADDR:$REGISTRY_PORT/$IMAGE_NAME" .

    printf "\n"

    printf "\n\n===> PUSH IMAGE TO REGISTRY"
    printf "\n%s\n" "$HEADER"
    echo "$ docker push \"$REGISTRY_ADDR:$REGISTRY_PORT/$IMAGE_NAME\""
    printf "\n"
    docker push "$REGISTRY_ADDR:$REGISTRY_PORT/$IMAGE_NAME"
}

up_master ()
{
    printf "\n\n===> SPIN UP MASTER NODE"
    printf "\n%s\n" "$HEADER"
    echo "$ docker-compose up -d master"
    printf "\n"
    docker-compose up -d master
}


up_workers ()
{
    printf "\n\n===> SPIN UP WORKER NODES"
    printf "\n%s\n" "$HEADER"
    echo "$ docker-compose up -d worker"
    printf "\n"
    docker-compose up -d worker 

    printf "\n"
    printf "\n%s\n" "$HEADER"

    NUM_WORKER=$((SIZE - 1))
    echo "$ docker-compose scale worker=$NUM_WORKER"
    printf "\n"
    docker-compose scale worker=${NUM_WORKER}
}

down_master ()
{
    printf "\n\n===> TORN DOWN MASTER NODE"
    printf "\n%s\n" "$HEADER"

    echo "$ docker-compose stop master && docker-compose rm -f master"
    printf "\n"
    docker-compose stop master && docker-compose rm -f master
}

down_workers ()
{
    printf "\n\n===> TORN DOWN WORKER NODES"
    printf "\n%s\n" "$HEADER"
    echo "$ docker-compose stop worker && docker-compose rm -f worker"
    printf "\n"
    docker-compose stop worker && docker-compose rm -f worker
}

list ()
{
    printf "\n\n===> LIST CONTAINERS"
    printf "\n%s\n" "$HEADER"
    echo "$ docker-compose ps"
    printf "\n"
    docker-compose ps
}


exec_on_mpi_master_container ()
{
    # shellcheck disable=SC2046
    docker exec -it -u mpi $(docker-compose ps | grep 'master'| awk '{print $1}') "$@"
}

prompt_ready ()
{
    printf "\n\n===> CLUSTER READY \n\n"
}

show_instruction ()
{
    echo '                            ##         .          '
    echo '                      ## ## ##        ==          '
    echo '                   ## ## ## ## ##    ===          '
    echo '               /"""""""""""""""""\___/ ===        '
    echo '          ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~ '
    echo '               \______ o           __/            '
    echo '                 \    \         __/               '
    echo '                  \____\_______/                  '
    echo '                                                  '
    echo '                 Alpine MPICH Cluster             '
    echo ''
    echo ' More info: https://github.com/NLKNguyen/alpine-mpich'
    echo ''
    echo '=============================================================='
    echo ''

    echo "To run MPI programs in an interative shell:"
    echo "  1. Login to master node:"
    echo "     Using Docker through command wrapper:"
    echo "     $ ./cluster.sh login"
    echo ""
    echo "     Or using SSH with keys through exposed port:"
    echo "     $ ssh -o \"StrictHostKeyChecking no\" -i ssh/id_rsa -p $SSH_PORT mpi@localhost"
    echo '       where [localhost] could be changed to the host IP of master node'
    echo ""
    echo "  2. Execute MPI programs inside master node, for example:"
    echo "     $ mpirun hostname"
    echo "      *----------------------------------------------------*"
    echo "      | Default hostfile of connected nodes in the cluster |"
    echo "      | is automatically updated at /etc/opt/hosts         |"
    echo "      | To obtain hostfile manually: $ get_hosts > hosts   |"
    echo "      * ---------------------------------------------------*"
    echo ""
    echo ""
    echo "To run directly a shell command at master node:"
    echo "     $ ./cluster.sh exec [COMMAND]"
    echo ""
    echo "     Example: "
    echo "     $ ./cluster.sh exec mpirun hostname"
    echo ""
}



#############################################

while [ "$1" != "" ];
do
    PARAM=$(echo "$1" | awk -F= '{print $1}')
    VALUE=$(echo "$1" | awk -F= '{print $2}')

    case $PARAM in
        help)
            usage
            exit
            ;;
        -i)
            show_instruction
            exit
            ;;

        login)
            COMMAND_LOGIN=1
            ;;

        exec)
            COMMAND_EXEC=1
            shift # the rest is the shell command to run in the node
            SHELL_COMMAND="$*"
            break # end while loop
            ;;

        up)
            COMMAND_UP=1
            ;;

        down)
            COMMAND_DOWN=1
            ;;

        reload)
            COMMAND_RELOAD=1
            ;;

        scale)
            COMMAND_SCALE=1
            ;;

        list)
            COMMAND_LIST=1
            ;;

        clean)
            COMMAND_CLEAN=1
            ;;

        size)
            [ "$VALUE" ] && SIZE=$VALUE
            ;;

        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done


if [ $COMMAND_UP -eq 1 ]; then
    down_all
    up_registry
    generate_ssh_keys
    build_and_push_image
    up_master
    up_workers

    prompt_ready
    show_instruction

elif [ $COMMAND_DOWN -eq 1 ]; then
    down_all

elif [ $COMMAND_CLEAN -eq 1 ]; then
    echo "TODO"


elif [ $COMMAND_SCALE -eq 1 ]; then
    down_master
    down_workers
    up_master
    up_workers

    prompt_ready
    show_instruction

elif [ $COMMAND_RELOAD -eq 1 ]; then
    down_master
    down_workers
    build_and_push_image
    up_master
    up_workers

    prompt_ready
    show_instruction

elif [ $COMMAND_LOGIN -eq 1 ]; then
    exec_on_mpi_master_container ash

elif [ $COMMAND_EXEC -eq 1 ]; then
    exec_on_mpi_master_container ash -c "${SHELL_COMMAND}"

elif [ $COMMAND_LIST -eq 1 ]; then
    list
else
    usage
fi

