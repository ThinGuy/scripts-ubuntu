#!/bin/bash
##############################################################################
# vboxguest.sh
# 
#                                                       
#                                                       Author: Craig Michael Bender
#                                                        Rev date: 5/15/2016
# 
# Function: Helper Script to properly install VirtualBox Guest Additions on Ubuntu Server Image
# Copyright (c) 2016 Craig Michael Bender. All rights reserved.
#
##############################################################################

#Ensure script is ran under sudo
[[ $EUID -ne 0 ]] && { printf "\n\e[1;31mThis script requires admin privileges.\e[0m \e[1;37mPlease run via sudo.\e[0m\n\n"; printf "\e[0m\n"; exit 1; }

#Global Vars
export TRUE=true
export FALSE=false
IFS=$' \t\n'

#Colors
ROW='\e[1;48;5;202m'
RYW='\e[1;5;43;37m'
RRW='\e[1;5;41;37m'
RGW='\e[1;5;42;37m'
RBW='\e[1;5;44;37m'
RGrW='\e[1;5;47;37m'
RCW='\e[1;5;45;37m'
RAW='\e[1;5;46;37m'
RYB='\e[5;43;30m'
RRB='\e[5;41;30m'
RGB='\e[5;42;30m'
RWB='\e[5;47;30m'
RGrB='\e[5;47;30m'
RCB='\e[5;45;30m'
RAB='\e[5;47;30m'
BW='\e[1;37m'
BR='\e[1;31m'
BY='\e[1;33m'
BG='\e[1;32m'
BB='\e[1;34m'
BC='\e[1;35m'
BA='\e[1;36m'
BO='\e[38;5;202m'
GR='\e[0;37m'
DG='\e[1;30m'
RT='\e[0m'
RR='\e[0;31m'
RY='\e[0;33m'
RG='\e[0;32m'
RB='\e[0;34m'
RC='\e[0;35m'
RA='\e[0;36m'
RO='\e[38;5;208m'

#Functions
getSize() {
TTYTEST=$(stty size 2> /dev/null|awk '{print $2}')
TheTTYResult=$?
[[ ${TheTTYResult} -eq 0 ]] && export MYCOLUMNS=$(stty size 2>/dev/null|awk '{print $2}') && export MYROWS=$(stty size 2>/dev/null|awk '{print $1}')
[[ ${TheTTYResult} -ne 0 ]] && export MYCOLUMNS=128 && export MYROWS=48
export MIDCOL=$(($MYCOLUMNS/3))
export MIDROW=$(($MYROWS/2))
}

getSize

QStatusChk() {
local RETVAL=$?

[[ $RETVAL -eq 0 ]] && RES_COL=$(($MYCOLUMNS-60)) && printf '\e['"$RES_COL"'G\e[0;1;30;90m[  SUCCESS  ]\e[0m\n' && sleep .5
[[ $RETVAL -ne 0 ]] && RES_COL=$(($MYCOLUMNS-60)) && printf '\e['"$RES_COL"'G\e[0;1;30;90m[  FAILED!  ]\e[0m\n' && sleep 2
}

Spinner() {

case $toggle
  in
    1)
      echo -ne '\e[0m\t'"$1"'\e['$(($MYCOLUMNS-42))'G\e[1;37m| \r'
      toggle="2"
    ;;

    2)
      echo -ne '\e[0m\t'"$1"'\e['$(($MYCOLUMNS-42))'G\e[1;37m/ \r'
      toggle="3"
    ;;

    3)
      echo -ne '\e[0m\t'"$1"'\e['$(($MYCOLUMNS-42))'G\e[1;37m- \r'
      toggle="4"
    ;;

    4)
      echo -ne '\e[0m\t'"$1"'\e['$(($MYCOLUMNS-42))'G\e[1;37m\ \r'
      toggle="5"
    ;;
    *)
      echo -ne '\e[0m\t'"$1"'\e['$(($MYCOLUMNS-42))'G\e[1;37m| \r'
      toggle="1"
    ;;
esac

}

WelcomeMsg() {
themsg="${1}"
echo;for i in $(seq 232 256);do printf "\e[38;5;${i}m#\e[0m";done;printf "${themsg}";for i in $(seq 256 -1 232);do printf "\e[38;5;${i}m#\e[0m";done;echo
}

# Start of Script

WelcomeMsg "VirtualBox Guest Additions Installation Helper"

#Make sure this is a VirtualBox instance
export DMI_PRODUCT=$(dmidecode -t1|awk -F": " '/Product Name/{print $2}')
[[ $DMI_PRODUCT = "VirtualBox" ]] && export IS_VBOX="$TRUE" || { printf "\n\e[1;31mThis does not appear to be a VirtualBox VM.\e[0m \e[1;37mExiting...\e[0m\n\n"; exit 1; } 


# Check if X11 is installed
[[ `$(apt-cache policy xorg|grep -qoi "installed: (none)")|echo $?` = 0 ]] && export X11_INSTALLED="$FALSE" || export X11_INSTALLED="$TRUE"
printf "${BW}┗━ Checking if X11 is installed...${RT}\n"
[[ $X11_INSTALLED = "$FALSE" ]] && { printf "${BW}┗━━ X11 is ${BY}not installed.${BW}..${RT}\n"; export X11_OPT="--nox11"; } || { printf "${BW}┗━━ X11 is ${BA}installed.${BW}..${RT}\n"; export X11_OPT=""; }


#Unmount anything mounted on /media/cdrom
if [[ ! -z $(mount |grep 'on /media/cdrom') ]];then
	cd
	printf "${BW}┗━ Unmounting /media/cdrom...${RT}"
	umount -f /media/cdrom;QStatusChk
fi

# Check if VBox Guest Additions ISO is inserted
[[ ! -z $(readlink -f /dev/disk/by-label/VBOX*) ]] && export VBOX_GA_INSERTED="$TRUE" || export VBOX_GA_INSERTED="$FALSE"
while [[ $VBOX_GA_INSERTED = "$FALSE" ]];do
	printf "${ROW} *** Please insert Virtual Box Guest Additions ISO Now ***  ${RT}"
	sleep 2
	[[ ! -z $(readlink -f /dev/disk/by-label/VBOX*) ]] && VBOX_GA_INSERTED="$TRUE"
	printf "\n"
done
printf "${BW}┗━ Detected VirtualBox Guest Additions ISO on $(readlink -f /dev/disk/by-label/VBOX*)${RT}\n"
printf "${BW}┗━ Mounting VirtualBox Guest Additions ISO...${RT}"
mount -t iso9660 -o ro /dev/cdrom /media/cdrom;QStatusChk
[[ ! -z $(mount |grep 'on /media/cdrom') ]] || { printf "\n\e[1;31mFailed to mount VirtualBox Guest Additions ISO.\e[0m \e[1;37mExiting...\e[0m\n\n"; exit 1; }
printf "${BW}┗━ Installing additional software to assist with building guest additions...${RT}\n"
SpinnerProg=$(apt-get install -y -q dkms build-essential linux-headers-generic linux-headers-$(uname -r)) &
pid=$!
trap "kill $pid 2>/dev/null" EXIT
sleep .5
while kill -0 $pid 2>/dev/null;do
	Spinner "${BW}┗━ Installing additional software to assist with building guest additions...${RT} "			printf '                                                                                            '
done
wait $pid
SpinnerResult=$?
trap - EXIT
if [[ $SpinnerResult -eq 0 ]];then true;QStatusChk;else false;QStatusChk;fi
printf "\n\n"
[[ $X11_INSTALLED = "$FALSE" ]] && printf "${BW}┗━ Installing VirtualBox Guest Additions ${BY}(No X11 Support)${BW}...${RT}\n" || printf "${BW}┗━ Installing VirtualBox Guest Additions ${BA}(with X11 Support)${BW}...${RT}\n"
/media/cdrom/VBoxLinuxAdditions.run ${X11_OPT}
[[ $? -eq 0 ]] && { printf "\n\e[1;32m┗━ VirtualBox Guest Additions have been installed.\e[0m\n\n"; exit 0; }