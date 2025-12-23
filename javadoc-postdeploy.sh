# /Post-deployment processing of Javadoc artifact
#
# TODO	When downloading jar, delete on exit
# TODO	Support logging command output

REPO_URL="http://scruffy:5309"
DOWNLOAD="false"
REPO_ID="releases"
LOGFILE=/dev/null
logfile="/home/dpl/javadoc-postdeploy.log"
VERBOSE="false"
VERBOSE_OPT=
DRYRUN="false"
INSTALL_OPT=

Usage() {
  cat <<-EOF 1>&2

	Usage:   ${0##*/} [options] <group> <artifact> <version>

	Options: -d       Download the Javadoc artifact
	         -r repo  releases | snapshots | private
	         -l       Write messages to $logfile
	         -v       Verbose messages
	         -s       Create or update symbolic link
	         -o       Overwrite existing HTML directory
	         -x	  Dry run

	EOF
  exit 1
}

Fail() {
  echo "ERROR: $@" 1>&2
  exit 1
}

AddInstallOption() {
	[[ -n $INSTALL_OPT ]] && INSTALL_OPT=$INSTALL_OPT" "
	INSTALL_OPT=$INSTALL_OPT"-"$*
}

Log() {
	echo $(date +"%Y-%m-%d %H:%M:%S") $@ | tee -a $LOGFILE
}

Verbose() {
	[[ $VERBOSE = true ]] && Log $@
}

while getopts :dr:lvsox option 2> /dev/null
    do
    case $option in
        d)  DOWNLOAD="true";;
	r)  REPO_ID=$OPTARG;;	# TODO Validate
        l)  LOGFILE=$logfile;;
	v)  VERBOSE="true"i
            VERBOSE_OPT="-"$option;;
	s)  AddInstallOption "s";;
	o)  AddInstallOption "o";;
	x)  DRYRUN="true"
	    AddInstallOption "x";;
        ?)  echo -e "\ninvalid option \"$OPTARG\"" 1>&2
            Usage
            exit 1;;
        esac
        done
shift $(expr $OPTIND - 1)

# TESTING
[[ $# -eq 0 ]] && set -- "wtf.dpl.core" "core-main" "3.0"

[[ $# -ne 3 ]] && Usage

GROUP=$(echo "$1"| sed "s+\.+/+g")
ARTIFACT=$2
VERSION=$3
JAR=$ARTIFACT-$VERSION"-javadoc.jar"
JARDIR=$(pwd)
FILE=$GROUP/$ARTIFACT/$VERSION/$JAR

Verbose "FILE = '$FILE'"
Verbose "DOWNLOAD = '$DOWNLOAD'"
Verbose "VERBOSE= '$VERBOSE'"

if [[ $DOWNLOAD = true ]] ; then
	JARDIR="/tmp"
	COMMAND="wget -nv -P . -O $JARDIR/$JAR $REPO_URL/$REPO_ID/$FILE"
	if [[ $DRYRUN == "false" ]] ; then
		$COMMAND
		[[ $? -eq 0 ]] || Fail "download of $REPO_URL/$REPO_ID/$FILE failed"
	else
		Log "# "$COMMAND
	fi
fi

#[[ -f $JAR && -r $JAR ]] || Fail "file $JAR does not exist"
#ls -l $JAR
Log proceeding...
COMMAND="exec javadoc-install.sh -t api -l $LOGFILE $VERBOSE_OPT $INSTALL_OPT $GROUP $ARTIFACT $VERSION $JARDIR/$JAR"
if [[ $DRYRUN == "false" ]] ; then
        $COMMAND
else
	Log "# "$COMMAND
fi

exit

#curl -O $REPO_URL/$1/$3/$JAR
wget -P . -O $JAR $REPO_URL/$FILE

Log "Javadoc JAR $JAR deployed at $(date)"
#>> /var/log/reposilite-javadoc.log

#echo "Javadoc deployed for $1:$2:$3 ($4)" | Log
# >> /var/log/reposilite-javadoc.log

# vim: tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab:
