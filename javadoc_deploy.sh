#!/bin/bash

. logging_utils.sh # -f20

#LoggingOptions

POM="pom.xml"
EFFECTIVE_POM=".effective-pom.xml"

Usage() {
	cat <<-EOF >&2

	Usage:   ${0##*/} [options]

*/-	Options: -g         [local]  Don't generate javadoc
*/-	         -j         [local]  Don't create JAR file
*/-	         -d         [local]  Don't deploy JAR file
*/-	         -i         [local]  Don't execute remote installation script
*/?	         -n         [remote] Don't download JAR file
*/*	         -o	    [remote] Overwrite existing HTML directory
?/?	         -r repo    [both]   releases | snapshots | private
*/?	         -l         [both]   Write messages to $logfile
?/?	         -L         [both]   Write time-stamped messages to $logfile
?/*	         -v         [both]   Verbose messages
*/*	         -x         [both]   Dry run
	EOF
  exit 1
}

# Retrieves a POM property value
Property()
{
	delim="/_:"
	name=$delim$(echo "$1"| sed "s+\.+$delim+g")
	xmlstarlet sel -t -v $name $EFFECTIVE_POM
	if [[ $? -ne 0 ]] ; then
		echo "undefined property '$1'"
		return 1
	fi
	#echo "$1 -> $?" 1>&2
	return 0
}

# Refreshes the effective POM if neccessary
CheckPOM()
{
	[[ -f $POM ]] || Fail "current directory does not appear to be a project root"
	if [[ -f $EFFECTIVE_POM && $EFFECTIVE_POM -nt $POM ]] ; then
		echo "effective pom refresh is not required"
		return
	fi
	COMMAND="mvn help:effective-pom -Doutput=$EFFECTIVE_POM"
	if [[ $DRYRUN != "true" ]] ; then
		$COMMAND	# TODO Log output
	else
		Log "# "$COMMAND
	fi
}

# Generate the Javadoc
GenerateDoc()
{
	Log "starting GenerateDoc($*)"
	COMMAND="mvn javadoc:javadoc -Pjavadoc"
	if [[ $DRYRUN != "true" ]] ; then
		$COMMAND || Fail "GenerateDoc($*) failed"	# TODO Log output
	else
		Log "# "$COMMAND
	fi
}

# Generate the Javadoc JAR
GenerateJar()
{
	Log "starting GenerateJar($*)"
	COMMAND="mvn javadoc:jar -Pjavadoc"
	if [[ $DRYRUN != "true" ]] ; then
		$COMMAND || Fail "GenerateJar($*) failed"	# TODO Log output
	else
		Log "# "$COMMAND
	fi
	#ls -l $OUTPUT/$JAR
}

# Deploy the Javadoc JAR
DeployJar() {
	Log "starting DeployJar($*)"
	#mvn deploy:deploy-file -Pjavadoc,with-private-repo \
	COMMAND="mvn deploy:deploy-file -Pjavadoc \
	  -Dfile=$OUTPUT/$JAR \
	  -DgroupId=$GROUPID \
	  -DartifactId=$ARTIFACTID \
	  -Dversion=$VERSION \
	  -Dpackaging=jar \
	  -Dclassifier=javadoc \
	  -DrepositoryId=$REPO_ID \
	  -Durl=$REPO_URL/$REPO \
	  -DgeneratePom=false"
	if [[ $DRYRUN != "true" ]] ; then
		[[ -f $OUTPUT/$JAR ]] || Fail "JAR file '$JAR' does not exist"
		$COMMAND || Fail "DeployJar($*) failed"	# TODO Log output
	else
		Log "# "$COMMAND
	fi
}

# Install the Javadoc JAR
InstallJar() {
	Log "starting InstallJar($*)"
	ARGS=("dpl@scruffy.dpl.wtf"
		"/usr/local/bin/javadoc-postdeploy.sh"
		"-d -l -v"
		"-r $REPO"
		$REMOTE_OPTS
		$GROUPID
		$ARTIFACTID
		$VERSION
		)
	#echo ${ARGS[*]}
	COMMAND="mvn exec:exec -Dexec.executable='ssh' -Dexec.args='$(echo ${ARGS[*]})'"
	if [[ $DRYRUN != "true" ]] ; then
		$COMMAND || Fail "InstallJar($*) failed"	# TODO Log output
	else
		Log "# "$COMMAND
	fi
}

Fail()
{
	echo "ERROR: $*" >&2
	exit 1
}

AddRemoteOption() {
	[[ -n $REMOTE_OPTS ]] && REMOTE_OPTS=$REMOTE_OPTS" "
	REMOTE_OPTS=$REMOTE_OPTS"-"$*
	#echo "added '$*' -> $REMOTE_OPTS" >&2
}

Log() {
	echo "$@" | tee -a $LOGFILE
	#echo $(date +"%Y-%m-%d %H:%M:%S") $@ | tee -a $LOGFILE
}

Verbose() {
	[[ $VERBOSE = true ]] && Log $@
}

#TMPFILE=$(mktemp) || exit 1
#trap 'rm -f "$TMPFILE"' EXIT SIGINT SIGTERM SIGHUP
#        Options: -g     Don't generate javadoc
#                 -j     Don't create JAR file
#                 -d     Don't deploy JAR file
#                 -i     Don't execute remote installation script

# Get options
NO_GEN="false"
NO_JAR="false"
NO_DEPLOY="false"
NO_INSTALL="false"
####VERBOSE="true"
DRYRUN="false"
REPO_URL="http://scruffy:5309"
REPO_ID=$(Property "project.distributionManagement.repository.id")
REPO="releases"
REMOTE_OPTS=
#DOWNLOAD_OPT=
####LOGFILE=/dev/null
#OVERWRITE_OPT=

logfile=~/$(basename $0).log
while getopts :gjdivxnr:o option 2> /dev/null
    do
    case $option in
        g)  NO_GEN="true";;
        j)  NO_JAR="true";;
        d)  NO_DEPLOY="true";;
        i)  NO_INSTALL="true";;
	v)  SetVerbose 
	    AddRemoteOption $option;;
	x)  DRYRUN="true"
	    AddRemoteOption $option;;
	n)  AddRemoteOption $option;;
	r)  REPO=$OPTARG;;		# TODO Validate
	o)  AddRemoteOption $option;;
	l|L)	;; # TODO
        ?)  echo -e "\ninvalid option \"$OPTARG\"" >&2
            Usage;;
        esac
        done
shift $(expr $OPTIND - 1)
[[ $# -eq 0 ]] || Usage

GROUPID=$(Property "project.groupId") || Fail $GROUPID
ARTIFACTID=$(Property "project.artifactId") || Fail $ARTIFACTID
VERSION=$(Property "project.version") || Fail $VERSION
OUTPUT=$(Property "project.build.directory") || Fail $OUTPUT
FINALNAME=$(Property "project.build.finalName") || Fail $FINALNAME
# core-main-3.0-javadoc.jar
#JAR=$ARTIFACTID"-"$VERSION"-javadoc.jar"
JAR=$FINALNAME"-javadoc.jar"
#REPOID=$(Property "project.distributionManagement.repository.id")
#REPO_URL=$(Property "project.distributionManagement.repository.url")

#cat <<-EOF
#	GROUPID    $GROUPID
#	ARTIFACTID $ARTIFACTID
#	VERSION    $VERSION
#	OUTPUT     $OUTPUT
#	FINALNAMNE $FINALNAME
#	JAR        $JAR
#	REPO_ID    $REPO_ID
#	REPO_URL   $REPO_URL
#	EOF

ShowOptions \
	GROUPID \
	ARTIFACTID \
	VERSION \
	OUTPUT \
	FINALNAME \
	JAR \
	REPO_ID \
	REPO_URL
ShowLoggingOptions

exit

CheckPOM
$NO_GEN = "true" || GenerateDoc
$NO_JAR = "true" || GenerateJar
$NO_DEPLOY = "true" || DeployJar
$NO_INSTALL = "true" || InstallJar
