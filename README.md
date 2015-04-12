DOCKER-DESKTOP
==============

This project provides
 * Text workstation base for developers
 * GUI Workstation based on Text workstation

##Availability
 * Automated Builds on Dockerhub:
   - [guruvan/desktop-base](https://registry.hub.docker.com/u/guruvan/desktop-base)
   - [guruvan/desktop-gui](https://registry.hub.docker.com/u/guruvan/desktop-gui)

Default Dockerfile builds desktop-base (text) 
   ```
   git clone https://github.com/guruvan/docker-desktop
   cd docker-desktop
   docker build -f Dockerfile -t username/desktop-base \
     && docker build -f Dockerfile.gui -t username/desktop-gui
   ```

##Quick Start

 This example uses TCP connection which is avilable in ./docker-desktop by default, for use over VPN
  - see below for commandline ssh connection

 On application server
   ```
   docker pull guruvan/desktop-gui
   docker run -d --name username_desktop -p 1337:22 -p 9001:9000  guruvan/desktop-base
   docker-enter username_desktop
   su - docker
   echo "your_sekrit_passwd" > ~/.xprapass
   ./docker-desktop -d 10
   ```
 On local display server, use Xpra Launcher app to connect to port 9000 of that host
 with the password you set above


##Description

This Dockerfile creates a docker image and once it's executed it creates a container that runs X11 and SSH services.
The ssh is used to forward X11 and provide you encrypted data communication between the docker container and your local machine.

Xpra allows to display the applications running inside of the container such as Firefox, eclipse, smartgit, xterm, etc. with recovery connection capabilities. Xpra also uses a custom protocol that is self-tuning and relatively latency-insensitive, and thus is usable over worse links than standard X.

The applications are served rootless, so the client machine manages the windows that are displayed.

This is a large kitchen-sink image intended to support developers working on cloud infrastructure
 approx. 3.5GB

We include an ssh server to allow xpra connection setup over ssh
Default is to setup connections over TCP to enhance OSX connections via VPN
  - most VPN clients appear to break xpra setup over ssh, but with encryption on VPN, this is ok

## Applications:
 * Text
   - build tools: make cmake, automake, etc - git, git-flow toolchain
   - weechat
   - Tomb
   - grive
   - bitlbee
   - 
 * GUI 
   - gvim
   - firefox
   - chromium
   - eclipse (4.3)
   - bluefish
   - meld
   - diffuse
   - smartgit
   - nautilus (for smartgit integration) 
   - pidgin (for alternative to weechat
   - mrxvt
   - seahorse
   - wine1.7



The client machine needs to have a X11 server installed (Xpra). See the "Notes" below. 


###Building the docker image

```
$ docker build -t [username]/docker-desktop git://github.com/guruvan/docker-desktop.git

OR

$ git clone https://github.com/guruvan/docker-desktop.git
$ cd docker-desktop
$ docker build -t [username]/docker-desktop .
```

###Running the docker image created (-d: detached mode, -P: expose the port 22 on the host machine)

```
$ docker run --name username_desktop -d -P [username]/docker-desktop
```
OR
```
$ docker run --name username_desktop -d -p 9999:22 -p 9001:9000 guruvan/desktop-base
```
The TCP port is bound after starting the container, so must be mapped explicitly on the commandline to start the container - if you're only using SSH for connections (generally recommended) then you may omit the port 9000 map, and/or use the "-P" to map all ports to the next available in Docker's port group. 

###Getting the password generated during runtime

**If using in production, it is wise to change this!!**
```
$ echo $(docker logs $CONTAINER_ID | sed -n 1p)
User: docker Password: xxxxxxxxxxxx
# where xxxxxxxxxxxx is the password created by PWGen that contains at least one capital letter and one number
```

##Usage

###Getting the container's external ssh port 

```
$ docker port username_desktop  22
49153 # This is the external port that forwards to the ssh service running inside of the container as port 22
```

###Connecting to the container 

If you have access, docker-enter is the simplest way to access your container, or you may use the included ssh server
 - Wise users will change the password and install a private SSH key into /home/docker/.ssh/authorized_keys

Install docker-enter:
```
docker run -it --rm -v /usr/local/bin:/target jpetazzo/nsenter 
```
Then enter the container
```
docker-enter username_desktop
```


####Starting the a new session 

```
$ ifconfig | grep "inet addr:" 
inet addr:192.168.56.102  Bcast:192.168.56.255  Mask:255.255.255.0 # This is the LAN's IP for this machine

$ ssh docker@192.168.56.102 -p 49153 "sh -c './docker-desktop -s 800x600 -d 10 > /dev/null 2>&1 &'" # Here is where we use the external port
docker@192.168.56.102's password: xxxxxxxxxxxx 

$ ./docker-desktop -h

-----------------------------------------------------------
Usage: docker-desktop [-s screen_size] [-d session_number]
-s : screen resolution (Default = 800x600
-d : session number (Default = 10)
-h : help
-----------------------------------------------------------
```

####Attaching to the session started

```
$ xpra --ssh="ssh -p 49153" attach ssh:docker@192.168.56.102:10 # user@ip_address:session_number
docker@192.168.56.102's password: xxxxxxxxxxxx 

```
If you want to execute rootless programs, you just need to connect to the container via ssh and type: 
DISPLAY=:[session_number] [program_name] & 

Eg. DISPLAY=:10 firefox &

##Notes

###On Windows:
Requirements:
- Xpra <= 14.0 (https://www.xpra.org/dists/windows/)
- Path: C:\Program Files(x86)\Xpra\Xpra_cmd.exe

###On OS X:
Requirements:
- Xpra Version <= 14.0 (https://www.xpra.org/dists/osx/x86/)
- Path: /Applications/Xpra.app/Contents/Helpers/xpra


###On Linux:
Requirements:
- Xpra: You can use apt-get to install it -> apt-get install xpra
- Path: /usr/bin/xpra
