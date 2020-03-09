#!/bin/bash
if [[ $# != 1 ]] ; then
	echo -e "\033[1;34m Usage : build.sh <MSF version>\033[0m"
	exit 1
fi

VER=$1

if [[ ! -f $VER.tar.gz || ! -s $VER.tar.gz  ]] ; then
	echo -e "\033[1;34m [+] Downloading $VER.tar.gz...\033[0m"
	wget -q https://github.com/rapid7/metasploit-framework/archive/$VER.tar.gz -O $VER.tar.gz
fi

if [[ $? -eq 0 ]] ; then
	rm -rf metasploit-framework-$VER
	if ! tar -zxf $VER.tar.gz >/dev/null 2>&1 ; then
		echo -e "\033[1;34m [-] $VER.tar.gz corrupts. Remove it and try again.\033[0m"
		exit 1
	fi	

	cd metasploit-framework-$VER
	cp -f ../Dockerfile .
	cp -f ../*.patch .
	cp -f ../entrypoint.sh docker/entrypoint.sh
	
	if which docker >/dev/null 2>&1 ; then
		echo -e "\033[1;34m [+] Start to build image...\033[0m"
		docker build . -t msf:$VER
	else
		echo -e "\033[1;33m [-] Please install docker first.\033[0m"
        exit 1
	fi
else 
	echo -e "\033[1;34m [-] Fail to download MSF source code !\033[0m"
    exit 1
fi