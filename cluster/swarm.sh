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

# Default values if providing empty
SIZE=4
PROJECT_NAME="mpi"
NETWORK_NAME="mpi-network"
NETWORK_SUBNET="10.0.9.0/24"
SSH_PORT="2222"

# Include config variables if the file exists
# shellcheck disable=SC1091
if [ -f ./swarm.conf ]; then
    . ./swarm.conf
fi

MPI_MASTER_SERVICE_NAME="${PROJECT_NAME}-master"
MPI_WORKER_SERVICE_NAME="${PROJECT_NAME}-worker"

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
COMMAND_CONFIG=0

OPTION_SHOW=0
OPTION_SET=0
OPTION_DELAY=1
OPTION_SSH_KEYGEN=0
OPTION_WATCH=0

SHELL_COMMAND=""
#############################################
usage ()
{
    echo " Alpine MPICH Cluster (for Swarm Mode on multi Docker hosts)"
    echo ""
    echo " USAGE: ./swarm.sh [COMMAND] [OPTIONS]"
    echo ""
    echo " Examples of [COMMAND] can be:"
    echo "      up: start cluster"
    echo "          ./swarm.sh up size=10"
    echo ""
    echo "      scale: resize the cluster"
    echo "          ./swarm.sh scale size=30"
    echo ""
    echo "      reload: rebuild image and distribute to nodes"
    echo "          ./swarm.sh reload size=15"
    echo ""
    echo "      login: login to Docker container of MPI master node for interactive usage"
    echo "          ./swarm.sh login"
    echo ""
    echo "      exec: execute shell command at the MPI master node"
    echo "          ./swarm.sh exec [SHELL COMMAND]"
    echo ""
    echo "      down: shutdown cluster"
    echo "          ./swarm.sh down"
    # echo ""
    # echo "      clean: remove images in the system"
    # echo "          ./swarm.sh clean"
    echo ""
    echo "      list: show running containers of cluster"
    echo "          ./swarm.sh list"
    echo ""
    echo "      help: show this message"
    echo "          ./swarm.sh help"
    echo ""
    echo "  "
}

HEADER="
         __v_
        (.___\/{
~^~^~^~^~^~^~^~^~^~^~^~^~"

set_variables ()
{
    MPI_MASTER_SERVICE_NAME="${PROJECT_NAME}-master"
    MPI_WORKER_SERVICE_NAME="${PROJECT_NAME}-worker"
}


delay ()
{
    if [ $OPTION_DELAY -ne 0 ]; then
        sleep ${OPTION_DELAY}
    fi
}

up_network ()
{
    printf "\n%s\n" "$HEADER"
    printf "$ docker network create  \\
                --driver overlay      \\
                --subnet %s  \\
                --opt encrypted       \\
                %s\n" "${NETWORK_SUBNET}" "${NETWORK_NAME}"
    printf "\n"

    docker network create               \
            --driver overlay            \
            --subnet ${NETWORK_SUBNET}  \
            --opt encrypted             \
            ${NETWORK_NAME}

    echo "=> network is created"

    delay
}

down_network ()
{
    printf "\n\n===> REMOVE NETWORK"

    printf "\n%s\n" "$HEADER"
    echo "$ docker network rm ${NETWORK_NAME}"
    printf "\n"
    if docker network rm ${NETWORK_NAME} ; then
        echo "=> network is removed"
    else
        echo "=> No problem"
    fi

    delay
}

up_master ()
{
    printf "\n\n===> SPIN UP MASTER SERVICE"

    printf "\n%s\n" "$HEADER"
    printf "$ docker service create \\
        --name %s \\
        --replicas 1 \\
        --network %s \\
        --publish %s:22 \\
        --user root \\
        %s mpi_bootstrap \\
            mpi_master_service_name=%s \\
            mpi_worker_service_name=%s \\
            role=master\n" \
    "${MPI_MASTER_SERVICE_NAME}" "${NETWORK_NAME}" "${SSH_PORT}" "${IMAGE_TAG}" \
    "${MPI_MASTER_SERVICE_NAME}" "${MPI_WORKER_SERVICE_NAME}"

    printf "\n"

    docker service create                      \
        --name ${MPI_MASTER_SERVICE_NAME}      \
        --replicas 1                           \
        --network ${NETWORK_NAME}              \
        --publish ${SSH_PORT}:22               \
        --user root                            \
        "${IMAGE_TAG}" mpi_bootstrap             \
                    mpi_master_service_name=${MPI_MASTER_SERVICE_NAME} \
                    mpi_worker_service_name=${MPI_WORKER_SERVICE_NAME} \
                    role=master

    echo "=> master service is created"

    delay
}

up_workers ()
{
    printf "\n\n===> SPIN UP WORKER SERVICE"
    NUM_WORKER=$((SIZE - 1))

    printf "\n%s\n" "$HEADER"
    printf "$ docker service create \\
        --name %s \\
        --replicas %s \\
        --network %s \\
        --user root \\
        %s mpi_bootstrap \\
            mpi_master_service_name=%s \\
            mpi_worker_service_name=%s \\
            role=worker\n" \
    "${MPI_WORKER_SERVICE_NAME}" "${NUM_WORKER}" "${NETWORK_NAME}" "${IMAGE_TAG}" \
    "${MPI_MASTER_SERVICE_NAME}" "${MPI_WORKER_SERVICE_NAME}"

    printf "\n"

    docker service create                      \
        --name ${MPI_WORKER_SERVICE_NAME}      \
        --replicas ${NUM_WORKER}               \
        --network ${NETWORK_NAME}              \
        --user root                            \
        "${IMAGE_TAG}" mpi_bootstrap             \
                    mpi_master_service_name=${MPI_MASTER_SERVICE_NAME} \
                    mpi_worker_service_name=${MPI_WORKER_SERVICE_NAME} \
                    role=worker

    echo "=> worker service is created"

    delay
}

scale_workers ()
{
    printf "\n\n===> SCALE SERVICES"
    NUM_WORKER=$((SIZE - 1))

    printf "\n%s\n" "$HEADER"
    printf "$ docker service scale %s=%s" \
        "${MPI_WORKER_SERVICE_NAME}" "${NUM_WORKER}"

    printf "\n"

    docker service scale ${MPI_WORKER_SERVICE_NAME}=${NUM_WORKER}

    echo "=> New cluster size is $SIZE"

    delay
}

down_services ()
{
    printf "\n%s\n" "$HEADER"
    echo "$ docker service rm ${MPI_MASTER_SERVICE_NAME} ${MPI_WORKER_SERVICE_NAME}"
    printf "\n"
    if ! docker service rm ${MPI_MASTER_SERVICE_NAME} ${MPI_WORKER_SERVICE_NAME} ; then
        echo "=> No problem"
    fi

    delay
}



down_all ()
{
    printf "\n\n===> CLEAN UP CLUSTER"
    down_services
    down_network
}



generate_ssh_keys ()
{
    # if [ -f ssh/id_rsa ] && [ -f ssh/id_rsa.pub ]; then
    #     return 0
    # fi

    printf "\n\n===> GENERATE SSH KEYS \n\n"
    echo "$ rm -f ssh/id_rsa ssh/id_rsa.pub"
    printf "\n"
    rm -f ssh/id_rsa ssh/id_rsa.pub

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
    echo "$ docker build -t \"$IMAGE_TAG\" ."
    printf "\n"
    docker build -t "$IMAGE_TAG" .

    printf "\n"

    printf "\n\n===> PUSH IMAGE TO REGISTRY"
    printf "\n%s\n" "$HEADER"
    echo "$ docker push \"$IMAGE_TAG\""
    printf "\n"
    docker push "$IMAGE_TAG"
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
    docker-compose stop master && docker-compose rm -f master
}

list ()
{
    docker service ls | awk '{ print $2, $3 }' | column -t
}


exec_on_mpi_master_container ()
{
    # shellcheck disable=SC2046
    docker exec -it -u mpi $(docker-compose ps | grep 'master'| awk '{print $1}') "$@"
}

set_config ()
{
cat > ./swarm.conf <<- EOF
IMAGE_TAG=${IMAGE_TAG}
PROJECT_NAME=${PROJECT_NAME}
NETWORK_NAME=${NETWORK_NAME}
NETWORK_SUBNET=${NETWORK_SUBNET}
SSH_ADDR=${SSH_ADDR}
SSH_PORT=${SSH_PORT}
EOF
}

show_config ()
{
    cat ./swarm.conf
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
    echo '                      Swarm Mode                  '
    echo ''
    echo ' More info: https://github.com/NLKNguyen/alpine-mpich'
    echo ''
    echo '=============================================================='
    echo ''

    echo "To run MPI programs in an interative shell:"
    echo "  1. Login to master node:"
    echo "     $ ./swarm.sh login"
    echo ""
    echo "     which is equivalent to:"
    echo "     $ ssh -o \"StrictHostKeyChecking no\" -i ssh/id_rsa -p $SSH_PORT mpi@$SSH_ADDR"
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
    echo "     $ ./swarm.sh exec [COMMAND]"
    echo ""
    echo "     Example: "
    echo "     $ ./swarm.sh exec mpirun hostname"
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

        config)
            COMMAND_CONFIG=1
            ;;

            show)
                OPTION_SHOW=1
                ;;

            set)
                OPTION_SET=1
                ;;

                ### key-value pairs
                IMAGE_TAG)
                    [ "$VALUE" ] && IMAGE_TAG=$VALUE
                    ;;

                PROJECT_NAME)
                    [ "$VALUE" ] && PROJECT_NAME=$VALUE
                    ;;

                NETWORK_NAME)
                    [ "$VALUE" ] && NETWORK_NAME=$VALUE
                    ;;

                NETWORK_SUBNET)
                    [ "$VALUE" ] && NETWORK_SUBNET=$VALUE
                    ;;

                SSH_PORT)
                    [ "$VALUE" ] && SSH_PORT=$VALUE
                    ;;

                SSH_ADDR)
                    [ "$VALUE" ] && SSH_ADDR=$VALUE
                    ;;


        up)
            COMMAND_UP=1
            ;;

        down)
            COMMAND_DOWN=1
            ;;

        scale)
            COMMAND_SCALE=1
            ;;

        reload)
            COMMAND_RELOAD=1
            ;;

        login)
            COMMAND_LOGIN=1
            ;;

        list)
            COMMAND_LIST=1
            ;;

        exec)
            COMMAND_EXEC=1
            shift # the rest is the shell command to run in the node
            SHELL_COMMAND="$*"
            break # end while loop
            ;;

        ### options
        size)
            [ "$VALUE" ] && SIZE=$VALUE
            ;;

        
        --delay)
            [ "$VALUE" ] && OPTION_DELAY=$VALUE
            ;;

        --generate-ssh-keys)
            OPTION_SSH_KEYGEN=1
            ;;

        --watch)
            OPTION_WATCH=1
            ;;                    
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

set_variables

watch_replicas_resizing ()
{
    while sleep 0.5
    do
      clear; docker service ls | awk '{ print $2, $3 }' | column -t && printf '\nPress Ctrl + C to stop watching'
    done
    # watch -n 0.1 "docker service ls | awk '{ print \$2, \$3 }' | column -t && printf '\nPress Ctrl + C to stop watching'"
    # ^ Some systems don't come with `watch` program
}

if [ $COMMAND_UP -eq 1 ]; then
    down_all

    if [ $OPTION_SSH_KEYGEN -eq 1 ]; then
        generate_ssh_keys
    fi
    build_and_push_image
    up_network
    up_master
    up_workers

    if [ $OPTION_WATCH -eq 1 ]; then
        watch_replicas_resizing
    fi

    prompt_ready
    show_instruction

elif [ $COMMAND_DOWN -eq 1 ]; then
    down_services
    down_network

elif [ $COMMAND_CONFIG -eq 1 ]; then
    if [ $OPTION_SHOW -eq 1 ]; then
        show_config
    elif [ $OPTION_SET -eq 1 ]; then
        set_config
    else
        echo "command config: missing argument 'show' or 'set'"
    fi

elif [ $COMMAND_CLEAN -eq 1 ]; then
    echo "TODO"


elif [ $COMMAND_SCALE -eq 1 ]; then
    scale_workers
    if [ $OPTION_WATCH -eq 1 ]; then
        watch_replicas_resizing
    fi

elif [ $COMMAND_RELOAD -eq 1 ]; then
    down_services

    if [ $OPTION_SSH_KEYGEN -eq 1 ]; then
        generate_ssh_keys
    fi
    build_and_push_image
    up_master
    up_workers

    if [ $OPTION_WATCH -eq 1 ]; then
        watch_replicas_resizing
    fi

    prompt_ready
    show_instruction

elif [ $COMMAND_LOGIN -eq 1 ]; then
    # shellcheck disable=SC2086
    ssh -o "StrictHostKeyChecking no" -i ssh/id_rsa -p ${SSH_PORT} mpi@${SSH_ADDR}

elif [ $COMMAND_EXEC -eq 1 ]; then
    # shellcheck disable=SC2029 disable=SC2086
    ssh -o "StrictHostKeyChecking no" -i ssh/id_rsa -p ${SSH_PORT} mpi@${SSH_ADDR} \
    ". /etc/profile; . ~/.profile; $SHELL_COMMAND"

elif [ $COMMAND_LIST -eq 1 ]; then
    list
else
    usage
fi

