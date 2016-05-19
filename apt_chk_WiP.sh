

alias catcol='pygmentize -g'
alias lcatcol='pygmentize -g -O style=colorful,linenos=1'

Rar() {
if [[ $EUID -ne 0 ]]; then
   echo "This must be run as root" 
   return 1
fi
}

apt_chk() {
	Rar
	local TRUE=true
	local FALSE=false
	apt_chk_usage() { echo -e "\napt_chk -p <pkg1> [<pkg2> <pkg 3>] [-i] [-q]\n\n\tExample: apt_check ipcacl sshpass -i\n\n\t-p: \tPackage name(s)\n\t-i \tInstall Package\n\t-q \tQuiet mode\n\n\tActions logged to /var/log/apt_check_<packagename>.log" 1>&2; exit; }

    local OPTIND o p i
    while getopts ":p:iq" o; do
        case "${o}" in
            p)
                PKG_LIST="${OPTARG}"
                ;;
            i)
                INSTALL="${TRUE}"
                ;;
            q)
                QUIET={TRUE}"
                ;;           
            *)
                apt_chk_usage
                ;;
        esac
    done
    shift $((OPTIND-1))
    if [[ -z ${PKG_LIST};then
    	{apt_chk_usage; return; }
    else
	
		for PKG in "${PKG_LIST}";do
			LOGFILE=/var/log/apt_check_$PKG.log
			[[ -f $LOGFILE ]] || touch $LOGFILE
			if [[ `$(apt-cache policy $PKG|grep -qoi "installed: (none)")|echo $?` = 0 ]];then
				[[ $QUIET = "$FALSE" ]] && { printf "${PKG} is not installed\n"|tee -a $LOGFILE; } || { printf "${PKG} is not installed\n" >> $LOGFILE; }
				if [[ $INSTALL = "$TRUE" ]];then
					[[ $QUIET = "$TRUE" ]] && { printf "Installing ${PKG}...\n" >> $LOGFILE; } || { printf "Installing ${PKG}...\n" |tee -a $LOGFILE; }
					[[ $QUIET = "$TRUE" ]] && { apt-get install -yq ${PKG} >> $LOGFILE; } || { apt-get install -y ${PKG} |tee -a $LOGFILE; }
				fi
			
			elif [[ `$(apt-cache policy $PKG|grep -qoi "Unable to locate package")|echo $?` = 0 ]];then
				[[ $QUIET = "$TRUE" ]] && {printf "${PKG} not found in repository\n" >> $LOGFILE; } || { printf "${PKG} not found in repository\n" |tee -a $LOGFILE; }
				export RC_$PKG=2
			elif [[ `$(apt-cache policy $PKG|grep -qoi "installed: (none)")|echo $?` = 1 ]];then
				[[ $QUIET = "$TRUE" ]] && { printf "${PKG} is already installed.  Skipping.\n >> $LOGFILE"; } || { printf "${PKG} is already installed.  Skipping.\n" |tee -a $LOGFILE; } 
				export RC_$PKG=1
			fi
		done
	fi
}