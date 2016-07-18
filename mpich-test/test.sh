#!/bin/sh
echo --- Test MPICH installation ---

echo -n "it should find mpicc... "
mpicc --version > /dev/null
[ "$?" -ne 0 ] && echo nope && exit 1
echo ok

echo -n "it should find mpiexec... "
mpiexec --version > /dev/null
[ "$?" -ne 0 ] && echo nope && exit 1
echo ok

echo -n "it should compile mpi_hello_world.c source... "
mpicc -o mpi_hello_world mpi_hello_world.c > /dev/null
[ "$?" -ne 0 ] && echo nope && exit 1
echo ok

echo -n "it should run mpi_hello_world program successfully... "
mpirun -n 4 ./mpi_hello_world > /dev/null
[ "$?" -ne 0 ] && echo nope && exit 1
echo ok