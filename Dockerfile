# This file creates a container that runs X11 and SSH services
# The ssh is used to forward X11 and provide you encrypted data
# communication between the docker container and your local 
# machine.
#
# Xpra allows to display the programs running inside of the
# container such as Firefox, LibreOffice, xterm, etc. 
# with disconnection and reconnection capabilities
#
# Author: Rob Nelson guruvan@maza.club
# Based on work by: Roberto Gandolfo Hashioka
# Date: 07/28/2013


FROM ubuntu:14.04
# IMAGE guruvan/desktop-base
MAINTAINER Rob Nelson "guruvan@maza.club"
# FORKED FROM: Roberto G. Hashioka "roberto_hashioka@hotmail.com"


# Set the env variable DEBIAN_FRONTEND to noninteractive
ENV DEBIAN_FRONTEND noninteractive

# Nice Base
RUN apt-get update -y \
     && apt-get install -y software-properties-common wget \
         build-essential cmake make automake git tmux \
	 git-flow gnupg2 zsh cryptsetup  curl gettext

RUN apt-get install -y bitlbee bitlbee-plugin-otr sudo \
	 github-backup grive vim-python-jedi 

# Xpra updated PPA
RUN curl http://winswitch.org/gpg.asc | apt-key add - 

# Updated Weechat PPS
RUN add-apt-repository ppa:nesthib/weechat-stable

RUN echo "deb http://winswitch.org/ trusty main" > /etc/apt/sources.list.d/winswitch.list \
     && apt-get install -y software-properties-common \
     && add-apt-repository -y universe \
     && apt-get update -y \
     && apt-get upgrade -y 

RUN apt-get install -y  weechat weechat-scripts \
         pinentry-curses keychain bash-completion python-optcomplete \
	 sshfs ssh-askpass openssh-server pwgen apg 

RUN apt-get install -y python-pip python-dev  python-qt4 pyqt4-dev-tools 

RUN apt-get install -y php5-cli php5-redis 
# Fix PAM login issue with sshd
RUN sed -i 's/session    required     pam_loginuid.so/#session    required     pam_loginuid.so/g' /etc/pam.d/sshd

# Upstart and DBus have issues inside docker. We work around in order to install firefox.
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

# Installing fuse package (libreoffice-java dependency) and it's going to try to create
# a fuse device without success, due the container permissions. || : help us to ignore it. 
# Then we are going to delete the postinst fuse file and try to install it again!
# Thanks Jerome for helping me with this workaround solution! :)
# Now we are able to install the libreoffice-java package  
RUN apt-get -y install fuse  || :
RUN rm -rf /var/lib/dpkg/info/fuse.postinst
RUN apt-get -y install fuse
# Get docker so we have the docker binary and all deps inside the container
RUN curl -sSL https://get.docker.com/ubuntu | bash
# get & check tomb
RUN wget https://files.dyne.org/tomb/Tomb-2.0.1.tar.gz
RUN wget https://files.dyne.org/tomb/Tomb-2.0.1.tar.gz.sha
RUN sha256sum -c Tomb-2.0.1.tar.gz.sha \
     && tar -xpzvf Tomb-2.0.1.tar.gz \
     && cd Tomb-2.0.1 \
     && make install \
     && mv /Tomb-2.0.1* /opt


#########################################
# Set locale (fix the locale warnings)
RUN localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 || :

# Copy the files into the container
EXPOSE 22 
# Start xdm and ssh services.
COPY . /src
CMD ["/bin/bash", "/src/startup.sh"] 
