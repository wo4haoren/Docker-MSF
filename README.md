# Docker-MSF
 A script to build metasploit-framework container.

Dockerfile and entrypoint.sh are from metasploit-framework repo with some changes.

Just run build.sh to create your own docker image and play with metasploit-framework.


HOWTO:

1.  Clone this repo and run "./build.sh <MSF version>":

    ./build.sh 5.0.79

    And the script will download the specified version from Github, extracts the tar file, replace Dockerfile and entrypoint.sh, and then build the docker image.

2.  Create two mapping directories to hold the PG data and the home dir of user msf:
    
    mkdir /Users/woo/msf/data && mkdir /Users/woo/msf/home

3.  Create docker container :

    docker run -v /Users/woo/msf/data:/var/lib/postgresql/.msf4/ -v /Users/woo/msf/home:/home/msf -p 443:443/tcp -p 80:80/tcp -it --rm  msf:5.0.79



Features :

1.  Run any version of MSF you want in less than 30 mins. (Tested on some version of MSF4 and MSF5)
2.  Fresh MSF every time with backend DB unchanged, same MSF profile, and same shell profile...
3.  More security and more time saving!