#!/bin/bash
##############################################################################
# LXDNetConf.sh
# 
#                                                       
#                                                       Author: Craig Michael Bender
#                                                        Rev date: 5/15/2016
# 
# Function: Prepare LXD Networking without using dpkg-reconfigure GUI
# Copyright (c) 2016 Craig Michael Bender. All rights reserved.
#
##############################################################################
#Ensure script is ran under sudo
if [[ $EUID -ne 0 ]]; then
   printf "\n\e[1;31mThis script requires admin privileges.\e[0m \e[1;37mPlease run via sudo.\e[0m\n\n" 
   printf "\e[0m\n";exit 1
fi

[[ `$(apt-cache policy ipcalc|grep -qoi "installed: (none)")|echo $?` = 0 ]] && export IPCALC_INSTALLED="$FALSE" || IPCALC_INSTALLED="$TRUE"
if [[ $IPCALC_INSTALLED="$FALSE" ]];then
	SpinnerProg=$(apt-get install -y -q ipcalc) &
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
fi

Validate_IP() {
ip="$@"
VALID_IP=$(ipcalc -n $ip &>/dev/null;echo $?)
if [[ $VALID_IP -eq 0 ]];then
	return 0
else
	NETCONF_INVALID="$TRUE"
	NETCONF_INVALID_REASON="$NETCONF_VALID_REASON 'Invalid IP Address/Netmask: '$ip''"
	return 1
fi
	
}

LoadLXDDefaults() {
export USE_LXD_BRIDGE="true"
export LXD_BRIDGE="lxdbr0"
export LXD_CONFILE=""
export LXD_DOMAIN="lxd"
export LXD_IPV4_ADDR="10.0.4.1"
export LXD_IPV4_NETMASK="255.255.255.0"
export LXD_IPV4_NETWORK="10.0.4.1/24"
export LXD_IPV4_DHCP_RANGE_START="10.0.4.2"
export LXD_IPV4_DHCP_RANGE_END="10.0.4.254"
export LXD_IPV4_DHCP_RANGE="${LXD_IPV4_DHCP_RANGE_START},${LXD_IPV4_DHCP_RANGE_START}"
export LXD_IPV4_DHCP_MAX="253"
export LXD_IPV4_NAT="true"
export LXD_IPV6_ADDR=""
export LXD_IPV6_NETMASK=""
export LXD_IPV6_NETWORK=""
export LXD_IPV6_NAT="false"
export LXD_IPV6_PROXY="false"
}

ConfigIPV4Network() {
LoadLXDDefaults
RANGE_START_VALID=1
while [[ $RANGE_START_VALID = 1 ]];do
	WelcomeMsg 'LXD IPV4 Network Configuration'	read -e -i $LXD_IPV4_DHCP_RANGE_START -r -p "Enter Starting IP Address for the IPV4 Network : " LXD_IPV4_DHCP_RANGE_START
	read -e -i ${LXD_IPV4_NETMASK} -r -p "Enter Netmask for $LXD_IPV4_DHCP_RANGE_START : " LXD_IPV4_NETMASK
	[[ $(Validate_IP $LXD_IPV4_DHCP_RANGE_START $LXD_IPV4_NETMASK) -eq 0 ]] && export RANGE_START_VALID=0 
  	[[ $(Validate_IP $LXD_IPV4_DHCP_RANGE_START $LXD_IPV4_NETMASK) -eq 1 ]] && printf "\n\t\e[1;31mInvalid IP Address:\e[1;37m $LXD_IPV4_DHCP_RANGE_START $LXD_IPV4_NETMASK \e[0m\n" && sleep 2
done
while true; do
	read -e -i "yes" -r -p "Use LXD Bridge?  [y/n]: " yn_use_bridge
	case $yn_use_bridge in
		[Y]|[y]* )	
					export USE_LXD_BRIDGE="$TRUE"
					read -e -i "lxdbr0" -r -p "Enter LXD Bridge Name   : " LXD_BRIDGE
					read -e -i "lxd" -r -p "Enter LXD Domain Name   : " LXD_DOMAIN
					break
					;;
		[N]|[n]* )	export USE_LXD_BRIDGE="$FALSE"
					break;;
			* ) echo "Please enter y or n (y/n) :";;
	esac
done

while true; do
	if [[ $LXD_IPV4_DHCP_RANGE_START = $LXD_IPV4_DHCP_RANGE_START ]];then
		read -e -i "no" -r -p "Use DNS for name resolution?  [y/n]: " yndns
	else
		read -e -i "yes" -r -p "Use DNS for name resolution?  [y/n]: " yndns
	fi
	case $yndns in
		[Y]|[y]* )	export LXD_IPV4_DNS_ENABLE="$TRUE"
					read -e -r -p "Enter primary DNS Server   : " LXD_IPV4_DNS1
					read -e -r -p "Enter secondary DNS Server : " LXD_IPV4_DNS2
					break
					;;
		[N]|[n]* )	export LXD_IPV4_DNS_ENABLE_="$FALSE"
					export LXD_IPV4_DNS1=
					export LXD_IPV4_DNS2=
					break
					;;
			* ) echo "Please enter y or n (y/n) :";;
	esac
done	

while true; do
	if [[ $LXD_IPV4_DHCP_RANGE_START = $LXD_IPV4_DHCP_RANGE_START ]];then
		read -e -i "no" -r -p "Use NTP for system time?  [y/n]: " ynntp

	case $ynntp in
		[Y]|[y]* )	export LXD_IPV4_NTP_ENABLE="$TRUE"
					read -e -r -p "Enter primary NTP Server   : " LXD_IPV4_NTP1
					read -e -r -p "Enter secondary NTP Server : " LXD_IPV4_NTP2
					break;;
		[N]|[n]* )	export LXD_IPV4_NTP_ENABLE="$FALSE"
					export LXD_IPV4_NTP1=$LXD_IPV4_NTP1
					export LXD_IPV4_NTP1=$LXD_IPV4_NTP2
					break;;
			* ) echo "Please enter y or n (y/n) :";;
	esac
done
}

ReviewNetConf() {
printf "\n\n\e[5;46;30mReview LXD Network Configuration \e[0m\n\n"
printf "\tUse LXD Bridge: $USE_LXD_BRIDGE"
printf "\tLXD Bridge Name: $LXD_BRIDGE"
printf "\tLXD Configuration File Name: $LXD_CONFILE"
printf "\tLXD Domain Name: $LXD_DOMAIN"
printf "\tLXD Container IPV4 Address: $LXD_IPV4_ADDR"
printf "\tLXD Container IPV4 Netmask:$LXD_IPV4_NETMASK"
printf "\tLXD Container IPV4 Network:$LXD_IPV4_NETWORK"
printf "\tLXD DHCP Range Start: $LXD_IPV4_DHCP_RANGE_START"
printf "\tLXD DHCP Range End: $LXD_IPV4_DHCP_RANGE_END"
printf "\tLXD DHCP Range: $LXD_IPV4_DHCP_RANGE"
printf "\tLXD DHCP Max Addresses: $LXD_IPV4_DHCP_MAX"
printf "\tLXD IPV4 Use NAT :$LXD_IPV4_NAT"
printf "\tLXD Container IPV6 Address: $LXD_IPV6_ADDR"
printf "\tLXD Container IPV6 Netmask: $LXD_IPV6_NETMASK"
printf "\tLXD Container IPV6 Network: $LXD_IPV6_NETWORK"
printf "\tLXD IPV6 Use NAT: $LXD_IPV6_NAT"
printf "\tLXD IPV6 Use Proxy: $LXD_IPV6_PROXY"


while true; do
	read -e -i "yes" -r -p "Accept these settings? Type q to quit [y/n/q]: " ynsnet 
	case $ynsnet in
	[Yy]* ) writeNetConf /mnt/HYPERMEDIA/network.conf
			export LXD_NETCONF_CUSTOM=/mnt/HYPERMEDIA/network.conf
			export LXD_NETCONF_FILE=$LXD_NETCONF_CUSTOM
			break
			;;		
	[Nn]* ) ClearNetConf
			ConfigMgmtNetwork
			break
			;;
	[Qq]* ) printf "\n\nNetwork configuration cancelled.\nExiting.\n\n"
			ClearNetConf
			exit 0
			;;				
		* ) echo "Please enter y or n (y/n) :";;
  esac
done
}
