#!/bin/sh
set -e

echo "---- Check shell scripts styling with ShellCheck ----"

docker pull nlknguyen/alpine-shellcheck
alias shellcheck='docker run --rm -it -v $(pwd):/mnt nlknguyen/alpine-shellcheck'

shellcheck --version
shellcheck  **/*.sh                     \
            onbuild/auto_update_hosts   \
            onbuild/get_hosts           \
            onbuild/mpi_master          \
            onbuild/mpi_worker

echo "=> No styling trouble found"
