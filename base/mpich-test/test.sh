#!/bin/sh
set -e

echo "--- Test MPICH installation ---"

printf "it should find mpicc... "
mpicc --version > /dev/null
echo ok

printf "it should find mpiexec... "
mpiexec --version > /dev/null
echo ok

printf "it should compile mpi_hello_world.c source... "
mpicc -o mpi_hello_world mpi_hello_world.c > /dev/null
echo ok

printf "it should run mpi_hello_world program successfully... "
mpirun -n 4 ./mpi_hello_world > /dev/null
echo ok
