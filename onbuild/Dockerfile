FROM nlknguyen/alpine-mpich:latest

USER root

RUN apk add --no-cache openssh 

# # ------------------------------------------------------------
# # Utility shell scripts
# # ------------------------------------------------------------

COPY mpi_master /usr/local/bin/mpi_master
RUN chmod +x /usr/local/bin/mpi_master

COPY mpi_worker /usr/local/bin/mpi_worker
RUN chmod +x /usr/local/bin/mpi_worker

COPY get_hosts /usr/local/bin/get_hosts
RUN chmod +x /usr/local/bin/get_hosts

COPY auto_update_hosts /usr/local/bin/auto_update_hosts
RUN chmod +x /usr/local/bin/auto_update_hosts

# # ------------------------------------------------------------
# # Miscellaneous setup for better user experience
# # ------------------------------------------------------------

# Set welcome message to display when user ssh login 
COPY welcome.txt /etc/motd

# Default hostfile location for mpirun. This file will be updated automatically.
ENV HYDRA_HOST_FILE /etc/opt/hosts
RUN echo "export HYDRA_HOST_FILE=${HYDRA_HOST_FILE}" >> /etc/profile

RUN touch ${HYDRA_HOST_FILE}
RUN chown ${USER}:${USER} ${HYDRA_HOST_FILE}

# Auto go to default working directory when user ssh login 
RUN echo "cd $WORKDIR" >> ${USER_HOME}/.profile


# # ------------------------------------------------------------
# # Set up SSH Server 
# # ------------------------------------------------------------

# Add host keys
RUN cd /etc/ssh/ && ssh-keygen -A -N ''

# Config SSH Daemon
RUN  sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config \
  && sed -i "s/#PermitRootLogin.*/PermitRootLogin no/g" /etc/ssh/sshd_config \
  && sed -i "s/#AuthorizedKeysFile/AuthorizedKeysFile/g" /etc/ssh/sshd_config
 
# Unlock non-password USER to enable SSH login
RUN passwd -u ${USER}

# Set up user's public and private keys
ENV SSHDIR ${USER_HOME}/.ssh
RUN mkdir -p ${SSHDIR}

# Default ssh config file that skips (yes/no) question when first login to the host
RUN echo "StrictHostKeyChecking no" > ${SSHDIR}/config
# This file can be overwritten by the following onbuild step if ssh/ directory has config file

# Switch back to default user
USER ${USER}


# # ------------------------------------------------------------
# # ONBUILD (require ssh/ directory in the build context)
# # ------------------------------------------------------------
ONBUILD USER root

ONBUILD RUN ssh-keygen -f ${SSHDIR}/id_rsa -t rsa -N ''

ONBUILD RUN cat ${SSHDIR}/*.pub >> ${SSHDIR}/authorized_keys

ONBUILD RUN chown -R ${USER}:${USER} ${SSHDIR}

# Switch back to default user when continue the build process
ONBUILD USER ${USER}
