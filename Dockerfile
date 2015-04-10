# This file creates a container that runs X11 and SSH services
# The ssh is used to forward X11 and provide you encrypted data
# communication between the docker container and your local 
# machine.
#
# Xpra allows to display the programs running inside of the
# container such as Firefox, LibreOffice, xterm, etc. 
# with disconnection and reconnection capabilities
#
# Xephyr allows to display the programs running inside of the
# container such as Firefox, LibreOffice, xterm, etc. 
#
# Fluxbox and ROX-Filer creates a very minimalist way to 
# manages the windows and files.
#
# Author: Roberto Gandolfo Hashioka
# Date: 07/28/2013


FROM ubuntu:14.04
# IMAGE guruvan/desktop-base
MAINTAINER Rob Nelson "guruvan@maza.club"
# FORKED FROM: Roberto G. Hashioka "roberto_hashioka@hotmail.com"


# Set the env variable DEBIAN_FRONTEND to noninteractive
ENV DEBIAN_FRONTEND noninteractive

# Update to latest xpra
RUN apt-get update -y \
     && apt-get install -y software-properties-common wget \
         build-essential cmake make automake git tmux \
	 git-flow gnupg2 zsh cryptsetup  curl
RUN curl http://winswitch.org/gpg.asc | apt-key add - 
RUN add-apt-repository ppa:nesthib/weechat-stable
RUN echo "deb http://winswitch.org/ trusty main" > /etc/apt/sources.list.d/winswitch.list \
     && apt-get install -y software-properties-common \
     && add-apt-repository -y universe \
     && apt-get update -y \
     && apt-get upgrade -y \
     && apt-get install -y  weechat firefox xterm mrxvt \
         xfe xfe-themes pidgin pidgin-otr pidgin-hotkeys \
	 pidgin-guifications pidgin-twitter pidgin-themes \
	 pidgin-openpgp python-dev python-qt4 pyqt4-dev-tools \
	 python-pip php5 imagemagick php5-cli php5-redis \
	 default-jre default-jdk sshfs ssh-askpass chromium-browser deluge \
	 bluefish meld diffuse xpra openssh-server pwgen apg \
	 xdm xvfb sudo pinentry-gtk2 pinentry-curses bitlbee bitlbee-plugin-otr \
	 xpad weechat-scripts keychain bash-completion python-optcomplete \
	 git-all github-backup grive vim-gtk vim-python-jedi
# Installing the environment required: xserver, xdm, flux box, roc-filer and ssh

# Configuring xdm to allow connections from any IP address and ssh to allow X11 Forwarding. 
RUN sed -i 's/DisplayManager.requestPort/!DisplayManager.requestPort/g' /etc/X11/xdm/xdm-config
RUN sed -i '/#any host/c\*' /etc/X11/xdm/Xaccess
RUN ln -s /usr/bin/Xorg /usr/bin/X
RUN echo X11Forwarding yes >> /etc/ssh/ssh_config

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

# Installing the apps: Firefox, flash player plugin, LibreOffice and xterm
# libreoffice-base installs libreoffice-java mentioned before

# Get docker so we have the docker binary and all deps inside the container
RUN curl -sSL https://get.docker.com/ubuntu | bash
# liclipse 
#RUN wget https://googledrive.com/host/0BwwQN8QrgsRpLVlDeHRNemw3S1E/LiClipse%201.4.0/liclipse_1.4.0_linux.gtk.x86_64.tar.gz
#RUN if [ "$(md5sum liclipse_1.4.0_linux.gtk.x86_64.tar.gz|awk '{print $1}')" = "ce65311d12648a443f557f95b8e0fd59" ]; then tar -xpzvf liclipse_1.4.0_linux.gtk.x86_64.tar.gz; fi 

# addon to eclipse

# smartgit
RUN wget http://www.syntevo.com/downloads/smartgit/smartgit-6_5_7.deb
RUN if [ "$(md5sum smartgit-6_5_7.deb)|awk '{print $1}'" = "4a5449fee499d5e23edc21ceb24b9bef" ]; then dpkg -i smartgit-6_5_7.deb; fi \
     && apt-get install -f \
     && mv /smartgit* /opt


# get & check tomb
RUN wget https://files.dyne.org/tomb/Tomb-2.0.1.tar.gz
RUN wget https://files.dyne.org/tomb/Tomb-2.0.1.tar.gz.sha
RUN sha256sum -c Tomb-2.0.1.tar.gz.sha \
     && tar -xpzvf Tomb-2.0.1.tar.gz \
     && cd Tomb-2.0.1 \
     && make install \
     && mv /Tomb-2.0.1* /opt
RUN wget http://mirrors.ibiblio.org/pub/mirrors/eclipse/technology/epp/downloads/release/kepler/SR2/eclipse-standard-kepler-SR2-linux-gtk-x86_64.tar.gz
RUN if [ "$(sha512sum eclipse-standard-kepler-SR2-linux-gtk-x86_64.tar.gz|awk '{print $1}')" = "38d53d51a9d8d2fee70c03a3ca0efd1ca80d090270d41d6f6c7d8e66b118d7e5c393c78ed5c7033a2273e10ba152fa8eaf31832e948e592a295a5b6e7f1de48f" ]; then test -d /opt || mkdir /opt && mv eclipse-standard-kepler-SR2-linux-gtk-x86_64.tar.gz /opt && cd /opt && tar -xpzvf eclipse-standard-kepler-SR2-linux-gtk-x86_64.tar.gz ; fi
RUN  wget https://googledrive.com/host/0BwwQN8QrgsRpLVlDeHRNemw3S1E


RUN add-apt-repository -y ppa:ubuntu-wine/ppa \
     && dpkg --add-architecture i386 \
     && apt-get update -y \
     && apt-get upgrade -y \
     && apt-get install -y  wine1.7 winbind winetricks  

# Set locale (fix the locale warnings)
RUN localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 || :

# Copy the files into the container
COPY . /src

EXPOSE 22 9000 
# Start xdm and ssh services.
CMD ["/bin/bash", "/src/startup.sh"]
