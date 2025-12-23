#!/bin/bash -x

LOGGING="false"
LOGFILE="/dev/null"
LOGFILE_NAME="/home/dpl/test.log"
VERBOSE="false"
NAME_FORMAT="%-16s"
TIMESTAMP="false"
TIMESTAMP_FORMAT="%Y-%m-%d %H:%M:%S"

SetLogging() {
	[[ -n $1 ]] && LOGFILE_NAME=$1
	LOGFILE=LOGFILE_NAME
	LOGGING="true"
}

SetVerbose() {
	VERBOSE="true"
}

SetNameFormat() {
	NAME_FORMAT="%-"$1"s"			# TODO Validate?
}
	
SetTimestamp() {
	[[ -n $1 ]] && TIMESTAMP_FORMAT=$1
	TIMESTAMP="true"
}

Log() {
	#echo $(date +"%Y-%m-%d %H:%M:%S") $@ | tee -a $LOGFILE
	echo $@ | tee -a $LOGFILE
}

Verbose() {
	[[ $VERBOSE = true ]] && Log $@
}

ShowOptions()
{
	for option in $* ; do
		printf $NAME_FORMAT"%s\\n" $option "${!option}"
	done
}

ShowLoggingOptions() {
	ShowOptions \
		LOGGING \
		LOGFILE \
		LOGFILE_NAME \
		VERBOSE \
		NAME_FORMAT \
		TIMESTAMP \
		TIMESTAMP_FORMAT
}

while getopts :vlL:f:tT: option 2> /dev/null ; do
	case $option in
		l)  SetLogging;;
		L)  SetLogging $OPTARG;;
		v)  SetVerbose;;
		f)  SetNameFormat $OPTARG;;
		?)  echo -e "\ninvalid option \"$OPTARG\"" 1>&2
			Usage
			exit 1;;
	esac
	done
shift $(expr $OPTIND - 1)

#return

# Execute command and pipe output through logger
shopt -s lastpipe
Tee2() {
	local last_line=""
	$* 2>&1 | while read -r ; do
	#while read -r ; do
		last_line=$REPLY
                echo ">> $REPLY" tee -a bar
                #tee -a bar <<< $line
        done
	#echo "pipestatus = ${PIPESTATUS[@]}"
	RC=${PIPESTATUS[0]}
	#[[ $RC != 0 ]] && echo ">> $last_line" | tee -a bar
	#echo "last_line $last_line" >&2
        echo "result"
        return $RC
}
#R=$(Tee2 "ls -l $1")
#echo "exit '$R' -> $?"
#R=$(ls -l $1 2>&1 | Tee2)
#echo "exit '$R' -> $?"
return

# Pipe command output through tee
Tee() {
	#tee -a bar
	while read -r line ; do
		echo ">> $line" | tee -a bar
		#tee -a bar <<< $line
	done
	echo "result"
	return 17
}
R=$(ls -l) | Tee
echo "exit '$R', ${PIPESTATUS[*]}"
