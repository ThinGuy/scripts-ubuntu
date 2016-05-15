#!/bin/bash
##############################################################################
# JujuPrep.sh
# 
#                                                       
#                                                       Author: Craig Michael Bender
#                                                        Rev date: 5/13/2016
# 
# Function: Prepare generic Ubuntu image for Juju Demo
# Copyright (c) 2016 Craig Michael Bender. All rights reserved.
#
##############################################################################
#Ensure script is ran under sudo
if [[ $EUID -ne 0 ]]; then
   printf "\n\e[1;31mThis script requires admin privileges.\e[0m \e[1;37mPlease run via sudo.\e[0m\n\n" 
   printf "\e[0m\n";exit 1
fi

#Some global vars and settings
export PREPOPTIONS="$@"
export TRUE=true
export FALSE=false
shopt -s dotglob
export IFS=$' \t\n'
export LOGDIR=/var/log
export LOGFILE="${LOGDIR}/PrepServer.$$.log"
[[ -f $LOGFILE ]] || touch $LOGFILE 

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

WelcomeMsg() {
themsg="${1}"
echo;for i in $(seq 232 256);do printf "\e[38;5;${i}m#\e[0m";done;printf "${themsg}";for i in $(seq 256 -1 232);do printf "\e[38;5;${i}m#\e[0m";done;echo
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

SCRIPTstart=$(date +"%s")

[[ -z $LXD_CONT_NAME ]] && export LXD_CONT_NAME="lxd-test"



clear
{
	WelcomeMsg "${BO}  Preparing Ubuntu for Juju Demo  ${RT}"

	#Check for AWS instanace
	export LOCAL_HOSTNAME=$(hostname -d)
	if [[ ${LOCAL_HOSTNAME} =~ .*\.amazonaws\.com ]] || [[ ${LOCAL_HOSTNAME} =~ ec2\.internal ]];then
	        printf "${BCW}  This is an EC2 instance  ${RT}\n"
	        export AWS_INSTANCE="$TRUE"
	        printf "${BW}┗━ Installing Python...${RT}"
	        apt-get install -y -q python-software-properties >> $LOGFILE;QStatusChk
	else
	        printf "${BCW}  This does not appear to be an EC2 instance  ${RT}\n"
	        export AWS_INSTANCE="$FALSE"
	        printf "${BW}┗━ Installing OpenSSH and Python...${RT}"
	        apt-get install -y -q openssh-server python-software-properties >> $LOGFILE;QStatusChk
	fi
	
	
	#Check for Ubuntu Release Name
	[[ ! -z $(grep -i "trusty" /etc/lsb-release) ]] && export TRUSTY="$TRUE" || export TRUSTY="$FALSE"
	[[ ! -z $(grep -i "xenial" /etc/lsb-release) ]] && export XENIAL="$TRUE" || export XENIAL="$FALSE"
	
	if [[ $TRUSTY = "$TRUE" ]];then
		export JUJU_VER="1.25"
		printf "${RCW}Ubuntu 14.04 LTS (Trusty) Detected.${RT}\n"
		printf "${BW}┗━ Adding Personal Package Archive: juju/stable...${RT}"
		add-apt-repository ppa:juju/stable -y;QStatusChk
		printf "${BW}┗━ Updating Available Packages...${RT}"
		apt-get update -y >> $LOGFILE;QStatusChk
		printf "${BW}┗━ Installing ${BO}Juju ${JUJU_VER}${BW} Core and QuickStart...${RT}"
		apt-get install -y -q juju-core juju-quickstart >> $LOGFILE;QStatusChk


	elif [[ $XENIAL = "$TRUE" ]];then
		export JUJU_VER="2.0"
		printf "${RCW}Ubuntu 16.04 LTS (Xenial) Detected.${RT}\n"
		printf "${BW}┗━ Installing Juju ${JUJU_VER} ${RT}\n"
		printf "${BW}┗━ Adding Personal Package Archive: juju/devel...${RT}"
		add-apt-repository ppa:juju/devel -y >> $LOGFILE;QStatusChk
		printf "${BW}┗━ Updating Available Packages...${RT}"
		apt-get update -y >> $LOGFILE;QStatusChk
		[[ `$(apt-cache policy lxd|grep -qoi "installed: (none)")|echo $?` = 0 ]] && export LXD_INSTALLED="$FALSE" || LXD_INSTALLED="$TRUE"		printf "${BW}┗━ Installing ${BO}Juju ${JUJU_VER}${BW}, ZFS Utils, and ${BO}LXD${BW}...${RT}"
		apt-get install -y -q juju zfsutils-linux lxd >> $LOGFILE;QStatusChk
		GRP_CHK=$(getent group lxd;echo $?)
		[[ $GRP_CHK -eq 0 ]] && { printf "${BW}┗━ Creating group \"${BO}lxd${BW}\"${RT}"; newgrp lxd; }
		printf "${BW}┗━ Preparing ZFS to use sparse backing stores for ${BO}Juju${BW} containers...${RT}\n"
		mkdir /var/lib/zfs
		truncate -s 32G /var/lib/zfs/lxd.img
		printf "${BW}┗━ Creating ZFS Pool: ${BO}lxd${BW}...${RT}"
		zpool create lxd /var/lib/zfs/lxd.img;QStatusChk
		zpool iostat -v;sleep 2
		printf "${BW}┗━ Informing ${BO}LXD${BW} about ZFS Storage...${RT}"
		lxd init --auto --storage-backend zfs --storage-pool lxd;QStatusChk
		printf "${BW}┗━ Configuring ${BO}/etc/default/lxd-bridge${BW} with networking information for ${BO}Juju Container${BW}...${RT}\n"

		[[ -f /etc/default/lxd-bridge ]] && printf "${BW}┗━ Renaming ${BC}/etc/default/lxd-bridge${BW} to ${GR}/etc/default/lxd-bridge.$$ ${RT}\n"
		[[ -f /etc/default/lxd-bridge ]] && mv /etc/default/lxd-bridge /etc/default/lxd-bridge.$$
		printf 'USE_LXD_BRIDGE=\"true\"\n' > /etc/default/lxd-bridge
		printf 'LXD_BRIDGE=\"lxdbr0\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_CONFILE=\"\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_DOMAIN=\"lxd\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_IPV4_ADDR=\"10.0.4.1\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_IPV4_NETMASK=\"255.255.255.0\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_IPV4_NETWORK=\"10.0.4.1/24\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_IPV4_DHCP_RANGE=\"10.0.4.2,10.0.4.254\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_IPV4_DHCP_MAX=\"253\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_IPV4_NAT=\"true\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_IPV6_ADDR=\"\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_IPV6_MASK=\"\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_IPV6_NETWORK=\"\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_IPV6_NAT=\"false\"\n' >> /etc/default/lxd-bridge
		printf 'LXD_IPV6_PROXY=\"false\"\n' >> /etc/default/lxd-bridge		printf "${BW} ┗━Stopping ${BO}LXD Bridge: ${BC}${LXD_BRIDGE} ${BW} for ${BO}Juju${BW} Controller...${RT}"
		service lxd-bridge stop;QStatusChk
		printf "${BW} ┗━Restarting ${BO}LXD Service: ${BC}${LXD_BRIDGE} ${BW} for ${BO}Juju${BW} Controller...${RT}"
		service lxd restart;QStatusChk
		printf "${BW} ┗━Create ${BO}LXD${BW} Container: ${BC}${LXD_CONT_NAME} ${BW} for ${BO}Juju${BW} Controller${RT}\n"
		printf "${RO} ┗━━ This may take a few minutes as LXD must download an OS image for Ubuntu Xenial"
		SpinnerProg=$(juju bootstrap ${LXD_CONT_NAME} lxd) &
		pid=$!
		trap "kill $pid 2>/dev/null" EXIT
		sleep .5
		while kill -0 $pid 2>/dev/null;do
			#FileSize=$(du -sh "${USXMEDIA_ISO_ROOT}/HSMGR/HSMGR.TGZ" 2>/dev/null| awk '{print $1}')
			Spinner "┗━ Creating LXD Container: ${LXD_CONT_NAME}  "
			printf '                                                  '
		done
		wait $pid
		SpinnerResult=$?
		trap - EXIT
		if [[ $SpinnerResult -eq 0 ]];then true;QStatusChk;else false;QStatusChk;fi
	fi
	
	#Generate EC2 environments.yaml
	
	if [[ $AWS_INSTANCE = "$TRUE" ]];then
		printf "${ROW}  Create environments.yaml for AWS  ${RT}\n"
		
		printf "${BW}┗━ Renaming ${BC}~/.juju/environments.yaml${BW} to ${GR}~/.juju/environments.yaml.$$ ${RT}"
		[[ -f ~/.juju/environments.yaml ]] && mv ~/.juju/environments.yaml ~/.juju/environments.yaml.$$;QStatusChk

	
		printf "${ROW} Configuring environments.yaml for AWS ${RT}\n\n"
		printf "${BC}┗━ Enter Environment Name : ${GR}[ ${BW}amazon${GR}] ${BW}"
		read ENV_NAME
		[[ -z $ENV_NAME ]] && export ENV_NAME="AWS_JUJU_DEMO" && printf "${BY}┗━ Defaulting to ${BW} amazon ${BY} environment type${RT}\n";sleep 2
		printf "${BC}┗━ Enter Environment Type : ${GR}[ ${BW}ec2 ${GR}] ${BW}"
		read ENV_TYPE
		[[ -z $ENV_TYPE ]] && export ENV_TYPE="ec2" && printf "${BY}┗━ Defaulting to ${BW} ec2 ${BY} environment type${RT}\n";sleep 2
		
		#Ask for AWS Access Key ID if not present in ENV
		if [[ -z $AWS_ACCESS_KEY_ID ]];then
			export ACCESS_KEY_VALID=1
			export ACCESS_KEY_LEN=1
			while [[ $ACCESS_KEY_VALID = 1 ]] || [[ $ACCESS_KEY_LEN = 1 ]];do
				printf "${BO}┗━ Enter Access Key ID : ${BW}"
				read ACCESS_KEY
				[[ ${#ACCESS_KEY} -ge 19 ]] && export ACCESS_KEY_LEN=0 || (printf "\n\e[1;31m┗━ Access Key Length should be 19 characters\n" && sleep 2)
				[[ -n $ACCESS_KEY ]] && export ACCESS_KEY_VALID=0 || (printf "\n\e[1;31m┗━ Access Key ID Cannot be blank${RT}\n" && sleep 2)
				[[ $ACCESS_KEY_VALID = 0 ]] && [[ $ACCESS_KEY_LEN = 0 ]] && (printf "\n\e[1;32m┗━ Access Key ID Appears OK${RT}\n" && sleep 2)
			done	
		fi
		
		#Ask for AWS Secret Key if not present in ENV
		if [[ -z $AWS_SECRET_ACCESS_KEY ]];then		
			export SECRET_KEY_VALID=1
			export SECRET_KEY_LEN=1
			while [[ $SECRET_KEY_VALID = 1 ]] || [[ $SECRET_KEY_LEN = 1 ]];do
				printf "${BO}┗━ Enter Secret Access Key : ${BW}"
				read SECRET_KEY
				[[ ${#SECRET_KEY} -ge 40 ]] && export SECRET_KEY_LEN=0 || (printf "\n\e[1;31m┗━ Secret Key Length should be 40 characters!\n" && sleep 2)
				[[ -n $SECRET_KEY ]] && export SECRET_KEY_VALID=0 || (printf "\n\e[1;31m┗━ Secret Key Cannot be blank${RT}\n" && sleep 2)
				[[ $SECRET_KEY_VALID = 0 ]] && [[ $SECRET_KEY_LEN = 0 ]] && (printf "\n\e[1;32m┗━ Secret Key Appears OK${RT}\n" && sleep 2)
	 
			done
		fi
		
		printf "${BW}┗━ Changing ${BO}Default Environment Name${GR} to ${BW}${ENV_NAME} ${RT}"
		printf "default: ${ENV_NAME}\n" > ~/.juju/environments.yaml;QStatusChk
		printf "${BW}┗━ Addomg ${BO}Environments Stanza${GR} to ${BW}environments.yaml ${RT}"
		printf "environments:\n" >> ~/.juju/environments.yaml;QStatusChk
		printf "${BW}┗━ Changing ${BO}Environment Name${GR} to ${BW}${ENV_NAME} ${RT}"
		printf "\t${ENV_NAME}\n" >> ~/.juju/environments.yaml;QStatusChk
		printf "${BW}┗━ Changing ${BO}Environment Type${GR} to ${BW}${ENV_TYPE} ${RT}"
		printf "\t\ttype: ${ENV_TYPE}\n" >> ~/.juju/environments.yaml;QStatusChk
		[[ -z $AWS_ACCESS_KEY_ID ]] && printf "${BW}┗━ Changing ${BC}access-key:${GR} to ${BW}${ACCESS_KEY} ${RT}"
		[[ -z $AWS_ACCESS_KEY_ID ]] && printf "\t\taccess-key: ${ACCESS_KEY}" >> ~/.juju/environments.yaml;QStatusChk
		[[ -z $AWS_SECRET_ACCESS_KEY ]] && printf "${BW}┗━ Changing ${BC}secret-key${GR} to ${BW}${SECRET_KEY} ${RT}"
		[[ -z $AWS_SECRET_ACCESS_KEY ]] && printf "\t\tsecret-key: ${SECRET_KEY}" >> ~/.juju/environments.yaml;QStatusChk
		
		printf "\n\n${RCW}  Canonical Juju is ready for bootstrapping  ${RT}\n"
		printf "${BW}┗━ Bootstrapping ${BO}Juju Environment: ${BW}${ENV_NAME} ${RT}"
		SpinnerProg=$(juju bootstrap) &
		pid=$!
		trap "kill $pid 2>/dev/null" EXIT
		sleep .5
		while kill -0 $pid 2>/dev/null;do
			#FileSize=$(du -sh "${USXMEDIA_ISO_ROOT}/HSMGR/HSMGR.TGZ" 2>/dev/null| awk '{print $1}')
			Spinner "┗━━ Bootstrapping Juju Environment: ${ENV_NAME}      "
		done
		wait $pid
		SpinnerResult=$?
		trap - EXIT
		if [[ $SpinnerResult -eq 0 ]];then true;QStatusChk;else false;QStatusChk;fi
	fi
	
	
	
	
	
	SCRIPTend=$(date +"%s")
	SCRIPTtime=$(($SCRIPTend-$SCRIPTstart))
	printf "\n\n${ROW}  Juju $JUJU_VER preparation complete  ${RT}\n"
	printf "${RO}┗━ Juju preparation took $(($SCRIPTtime / 60)) min(s) $(($SCRIPTtime % 60)) secs. to complete.${RT}\n\n"
} 2> ${LOGFILE}


