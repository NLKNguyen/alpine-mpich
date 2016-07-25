# Alpine-MPICH
Docker image of Alpine Linux with MPICH installed

Include:
  * build-base (gcc, g++, make, wget, curl, etc.)
  * MPI compiler (MPICH version is according to tag version of Docker image)
  * default user `alpine` (sudoer without password)
  * default working directory `/project` owned by default user

