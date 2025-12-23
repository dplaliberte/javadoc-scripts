#!/bin/bash

# Installation of Javadoc artifact
#
# TODO	Support linking to version
# TODO	Support Speed Dial image 
# TODO	Support Overwrite of existing directory
# TODO	Support java
# TODO	Support javafx
# TODO	Support logging command output

HTML="/var/www/html"
ROOT="api"
OVERWRITE="false"
LOGFILE="/dev/null"
VERBOSE="false"
DRYRUN="false"

Usage() {
  cat <<-EOF 1>&2

	Usage:   ${0##*/} [options] [<group> <artifact> <version>] <jarfile>

	Options: -t <type>     java | javafx | api (default)
	         -s            Create or update symbolic link
	         -o            Overwrite existing HTML directory
	         -l <file>     Log messages to the specified file
	         -v            Verbose messages
	         -x	       Dry run

	When the type is "api", the group, artifact and version are required.
	For type "java" and "javafx" only the jarfile should be provided.

	EOF
  exit 1
}

Log() {
	echo $(date +"%Y-%m-%d %H:%M:%S") $@ | tee -a $LOGFILE
}

Fail() {
  Log "ERROR: $@"
  exit 1
}

Verbose() {
	[[ $VERBOSE = true ]] && Log $@
}

while getopts :t:ol:vx option 2> /dev/null
    do
    case $option in
	t)  case $OPTARG in
		api)    ROOT=api;;
		java)   ROOT=java;;
		javafx) ROOT=javafx;;
                *)      echo -e "\ninvalid type \"$OPTARG\"" 1>&2
                        Usage
                        exit 1;; 
	    esac;;
	o)  OVERWRITE="true";;
        l)  LOGFILE=$OPTARG;;
	v)  VERBOSE="true";;
        x)  DRYRUN="true";;
        *)  echo -e "\ninvalid option \"$OPTARG\"" 1>&2
            Usage
            exit 1;;
        esac
        done
shift $(expr $OPTIND - 1)

# TESTING
[[ $# -eq 0 ]] && set -- wtf.dpl.core core-main 3.0 /home/dpl/core-main-3.0-javadoc.jar
#[[ $# -eq 0 ]] && set -- jdk-21-javadoc.jar

if [[ $ROOT = "java" || $ROOT = "javafx" ]] ; then
        [[ $# -ne 1 ]] && Usage
	GROUP=$ROOT
	JAR=$1
        Fail "not implemented"
fi

[[ $# -ne 4 ]] && Usage
GROUP=$(echo "$1"| sed "s+\.+/+g")
ARTIFACT=$2
VERSION=$3
JAR=$4
[[ -f $JAR && -r $JAR ]] || Fail "file $JAR does not exist"

Verbose "GROUP    = $GROUP"
Verbose "ARTIFACT = $ARTIFACT"
Verbose "VERSION  = $VERSION"
Verbose "JAR      = $JAR"
Verbose "HTML     = $HTML"
Verbose "ROOT     = $ROOT"
Verbose "LOGFILE  = $LOGFILE"
Verbose "VERBOSE  = $VERBOSE"
Verbose "DRYRUN   = $DRYRUN"

#TARGET=$HTML/$ROOT/$GROUP/$ARTIFACT/$VERSION
TARGET=$HTML/$ROOT/$GROUP/$VERSION
Verbose "TARGET   = $TARGET"
if [[ ! -d $TARGET ]] ; then
	Log "creating version directory $TARGET"
	if [[ $DRYRUN = "false" ]] ; then
		RESULT=$(mkdir -p $TARGET >&1)
		[[ -z $RESULT ]] || Fail "could not create version directory: $RESULT"
	fi
else
	Log "version directory $TARGET already exists"
fi

TARGET=$TARGET"/"$ARTIFACT
if [[ -d "$TARGET" && -z "$(find "$JAVADOC" -maxdepth 0 -type d -empty)" ]]; then
	[[ $OVERWRITE = "false" ]] && Fail "artifact directory \"$TARGET\" is not empty"
	Log "removing previous artifact directory \"$TARGET\""
	if [[ $DRYRUN = "false" ]] ; then
		RESULT=$(rm -rf $TARGET >&1)
		[[ -z $RESULT ]] || Fail "could not remove previous artifact directory: $RESULT"
	fi
fi
JAVADOC=$TARGET"/docs"
if [[ ! -d $TARGET ]] ; then
	Log "creating artifact directory $TARGET"
	if [[ $DRYRUN = "false" ]] ; then
		RESULT=$(mkdir -p $JAVADOC >&1)
	[[ -z $RESULT ]] || Fail "could not create artifact directory: $RESULT"
	fi
fi

#JAVADOC=$TARGET"/docs"
#if [[ -d "$JAVADOC" && -z "$(find "$JAVADOC" -maxdepth 0 -type d -empty)" ]]; then
#	Fail "javadoc directory \"$JAVADOC\" is not empty"
#fi
#if [[ ! -d ^JAVADOC ]] ; then
#	Log "creating javadoc directory $JAVADOC"
#	if [[ $DRYRUN = "false" ]] ; then
#		RESULT=$(mkdir -p $JAVADOC 2>&1)
#		[[ -z $RESULT ]] || Fail "could not create javadoc directory: $RESULT"
#	fi
#fi
Log "extracting files"
if [[ $DRYRUN = "false" ]] ; then
	pushd $JAVADOC > /dev/null
	RESULT=$(unzip -q $JAR 2>&1)
 	[[ -z $RESULT ]] || Fail "extraction failed: $RESULT"
	DIRS=$(($(find . -type d | wc -l) - 1))
	FILES=$(find . -type f| wc -l)
	Log "extracted $DIRS directories, $FILES files"
	popd > /dev/null
fi
Log "done"

exit

# vim: tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab:
