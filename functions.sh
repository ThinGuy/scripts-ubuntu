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

centerText() {
local title=$(printf "$@")
printf "%*s\n" $(((${#title}+$MYCOLUMNS)/2)) "$title"
}

centerTextNoCR() {
local title=$(printf "$@")
printf "\r%*s" $(((${#title}+$MYCOLUMNS)/2)) "$title"
}

WelcomeMsg() {
themsg="${1}"
echo;for i in $(seq 232 256);do printf "\e[38;5;${i}m#\e[0m";done;printf "${themsg}";for i in $(seq 256 -1 232);do printf "\e[38;5;${i}m#\e[0m";done;echo
}

ColorTest256() {

for fgbg in 38 48;do
	for color in $(seq 0 256);do
		printf "\e[$fgbg;5;${color}m $color \t\e[0m"
		if [[ $((($color+1)%10)) = 0 ]]; then
			echo
		fi
	done
	echo
done
return 0
}

ColorTest16() {
for clbg in $(seq 40 47) $(seq 100 107) 49;do
	for clfg in $(seq 30 37) $(seq 90 97) 39; do
		for attr in 0 1 2 4 5 7;do
			printf "\e[$attr;$clbg;${clfg}m \e[$attr;$clbg;${clfg}m \e[0m"
		done
		echo
	done
done
return 0
}

CenterWait() {
RLength=$(echo "$1"|sed -e 's/\\e[[0-9;]*[a-zA-Z]//g' -e 's/\\n//g'|wc -c)
sleep .25
case $toggle
  in
    1)
      centerTextNoCR ''"$1"''
      toggle="2"
    ;;

    2)
      centerTextNoCR '<'"$1"'>'
      toggle="3"
    ;;

    3)
      centerTextNoCR '<-'"$1"'->'
      toggle="4"
    ;;

    4)
      centerTextNoCR '<--'"$1"'-->'
      toggle="5"
    ;;
    5)
      centerTextNoCR '<---'"$1"'--->'
      toggle="6"
    ;;
    6)
      centerTextNoCR '<----'"$1"'---->'
      toggle="7"
    ;;
    7)
      centerTextNoCR '<---'"$1"'--->'
      toggle="8"
    ;;
    8)
      centerTextNoCR '<--'"$1"'-->'
      toggle="9"
    ;;
    9)
      centerTextNoCR '<-'"$1"'->'
      toggle="10"
    ;;
    *)
      centerTextNoCR '<'"$1"'>'
      toggle="1"
    ;;
esac
unset RLength
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

mask2cidr() {
local MASK="$1"
nbits=0
IFS=.
for dec in $MASK; do
	case $dec in
		255) let nbits+=8;;
		254) let nbits+=7;;
		252) let nbits+=6;;
		248) let nbits+=5;;
		240) let nbits+=4;;
		224) let nbits+=3;;
		192) let nbits+=2;;
		128) let nbits+=1;;
		0);;
		*) echo "Error: $dec is not recognised"; return 1
	esac
done
echo "$nbits"
}

cidr2mask() {
local i mask=""
local CIDR=$1
local full_octets=$(($CIDR/8))
local partial_octet=$(($CIDR%8))
i=0
while [[ $i -lt 4 ]]; do
	if [ $i -lt $full_octets ]; then
	  mask="${mask}255"
	elif [ $i -eq $full_octets ]; then
	  mask="${mask}$((256 - 2**(8-$partial_octet)))"
	else
	  mask="${mask}0"
	fi
	test $i -lt 3 && mask="${mask}."
	i=$(($i+1))
done
echo $mask
}

CountDown() {
[[ -z "$1" ]] && return
local STRING="$1"
local STRINGSTRIP=$(echo "${1}"|sed -e 's/\\e[[0-9;]*[a-zA-Z]//g' -e 's/\\t//g' -e 's/\\n//g')
local STRINGLEN=${#STRINGSTRIP}
[[ ! -z $2 ]] && [[ $2 = "-c" ]] && CENTERED=true
local TIME=$(echo $STRINGSTRIP|grep -oE [0-9]..|grep -vE [a-zA-Z]|sed 's/\ //g')
local S1=`echo "$STRING"|awk -F"${TIME}" '{print $1}'`
local S2=`echo "$STRING"|awk -F"${TIME}" '{print $2}'`
local TW="seconds"
#local MYCOLS=$(stty size 2>/dev/null|awk '{print $2}')
[[ $KERNEL = Linux ]] && setterm -cursor on
for i in $(seq $TIME -1 0);do
	[[ $CENTERED = "$TRUE" ]] && CSTR="\e[$(((${MYCOLUMNS}-${#STRINGSTRIP})/2))G" || CSTR=
	[[ $i = 1 ]] && printf "\r${CSTR}${S1}${i}${S2} "|sed 's/seconds/second/g'
	[[ $i != 1 ]] && printf "\r${CSTR}${S1}${i}${S2} "

	sleep 1
done
[[ $KERNEL = Linux ]] && setterm -cursor on
}

pvCopy() {
export SOURCE="${1}"
export DEST="${2}"
export COPYTEXT="${3}"
if [[ $(basename $SOURCE) != $(basename $DEST) ]];then
	if [[ "${DEST:$((${#DEST}-1))}" = "/" ]];then
		export DEST="${DEST}$(basename $SOURCE)"
	elif [[ "${DEST:$((${#DEST}-1))}" != "/" ]];then
		export DEST="${DEST}/$(basename $SOURCE)"
	fi
fi
pv -fCN "$(printf "${BW}${COPYTEXT}${RT}")" -w $(($MYCOLUMNS+4)) -s $(du -sb ${SOURCE} 2>/dev/null|awk '{print $1}') ${SOURCE} > ${DEST} && (printf "\e[1A" && QStatusChk)
}

pvTarCopyEx() {
#Copy files with tar showing progress with pv and use exclude files
export SOURCEPATH="$1"
export DESTPATH="$2"
export COPYTEXT="$3"
export SCRIPTTTY="$4"
[[ ! -d $DESTPATH ]] && mkdir -p $DESTPATH
(printf "\t\e[0;37mCreating list of files to exclude...\e[0m";(for i in $(find $SOURCEPATH -type l|sed '/lib/d');do printf "$(basename $i)\n";done)|sort -u > /tmp/exclude.list;QStatusChk)
(export DUEXCLUDES=$(for i in $(find $SOURCEPATH -type l|sed '/lib/d');do printf "%s--exclude=${i} ";done|sort -u))
export CPSIZE=$(du -sb $SOURCEPATH "$DUEXCLUDES" 2>/dev/null|awk '{print $1}')
(tar -C $SOURCEPATH -c -X /tmp/exclude.list -f - . | pv -fCN "$(printf "${BA}${COPYTEXT}${RT}")" -w $(($MYCOLUMNS+4)) -s "${CPSIZE}"|tar -C $DESTPATH -x -X /tmp/exclude.list -f - .) &>$SCRIPTTTY && (printf "\e[1A";QStatusChk)
}

StatusChk() {
export RETVAL=$?
[[ $RETVAL -eq 0 ]] && printf '\e['$(($MYCOLUMNS-18))'G\e[0;37m[\e[1;37m***\e[1;32mOK\e[1;37m***\e[0;37m]\e[0m\n' && sleep .10
[[ $RETVAL -ne 0 ]] && printf '\e['$(($MYCOLUMNS-20))'G\e[0;37m[\e[1;37m***\e[1;31mFAILED\e[1;37m***\e[0;37m]\e[0m\n' && sleep 2
}

QStatusChk() {
local RETVAL=$?
[[ $RETVAL -eq 0 ]] && printf '\e['$(($MYCOLUMNS-18))'G\e[1;30m[  SUCCESS  ]\e[0m\n' && sleep .25
[[ $RETVAL -ne 0 ]] && printf '\e['$(($MYCOLUMNS-18))'G\e[1;30m[  FAILED!  ]\e[0m\n' && sleep 2
unset RETVAL
}

QStatusChk2() {
local RETVAL=$?
[[ $RETVAL -eq 0 ]] && printf '\e['$(($MYCOLUMNS-18))'G\e[1;30m[  \e[1;32mSUCCESS\e[1;30m  ]\e[0m\n' && sleep .5
[[ $RETVAL -ne 0 ]] && printf '\e['$(($MYCOLUMNS-18))'G\e[1;30m[  \e[1;31mFAILED!\e[1;30m  ]\e[0m\n' && sleep 2
unset RETVAL
}

QYN() {
local RETVAL=$?
[[ $RETVAL -eq 0 ]] && printf '&s\n' '\e['$(($MYCOLUMNS-18))'G\e[1;30m[  SUCCESS  ]\e[0m\n' && sleep .25
[[ $RETVAL -ne 0 ]] && printf '\e['$(($MYCOLUMNS-18))'G\e[1;30m[  FAILED!  ]\e[0m\n' && sleep 2
unset RETVAL
}

centerText() {
RLength=$(echo $@|sed -e 's/\\e[[0-9;]*[a-zA-Z]//g' -e 's/\\n//g'|wc -c)
printf "\e[$((($MYCOLUMNS-$RLength)/2))G${@}\n"
unset RLength
}
centerTextNoCR() {
RLength=$(echo $@|sed -e 's/\\e[[0-9;]*[a-zA-Z]//g' -e 's/\\n//g'|wc -c)
printf "\e[$((($MYCOLUMNS-$RLength)/2))G${@}\r"
unset RLength
}

centerTextNoCR2() {
RLength=$(echo $@|sed -e 's/\\e[[0-9;]*[a-zA-Z]//g' -e 's/\\n//g'|wc -c)
printf "\e[$((($MYCOLUMNS-$RLength)/2))G${@}"
unset RLength
}