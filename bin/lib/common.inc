#!/bin/sh
defineANSI() 
{
  # Standard tty codes
  ESC="\047"
  ERASELINE="${ESC}[2K"
  CRSRHIDE="${ESC}[?25l"
  CRSRSHOW="${ESC}[?25h"

  # Color-type codes, needs explicit terminal settings
  if [ ! "${_BPX_TERMPATH-x}" = "OMVS" ] && [ -z "${NO_COLOR}" ] && [ ! "${FORCE_COLOR-x}" = "0" ] && [ -t 1 ] && [ -t 2 ]; then
    esc="\047"
    BLACK="${esc}[30m"
    RED="${esc}[31m"
    GREEN="${esc}[32m"
    YELLOW="${esc}[33m"
    BLUE="${esc}[34m"
    MAGENTA="${esc}[35m"
    CYAN="${esc}[36m"
    GRAY="${esc}[37m"
    BOLD="${esc}[1m"
    UNDERLINE="${esc}[4m"
    NC="${esc}[0m"
  else
# unset esc RED GREEN YELLOW BOLD UNDERLINE NC

    esc=''
    BLACK=''
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    GRAY=''
    BOLD=''
    UNDERLINE=''
    NC=''
  fi
}
ansiupdate(){
  deltax=$1
  deltay=$2
  echostr=$3
  #crsrSetPos $x $y
  if [ $deltax -gt 0 ]; then
    crsrUp $deltax
  elif [ $deltax -lt 0 ]; then
    crsrDown $(expr $deltax \* -1)
  fi
  if [ $deltay -gt 0 ]; then
    crsrRight $deltay
  elif [ $deltay -lt 0 ]; then
    crsrLeft $(expr $deltay \* -1)
  fi
 /bin/echo "${echostr}"
}
crsrGetPos(){
# TODO
    /bin/echo "\027[6n"            # ask the terminal for the position
    read foo              # store the position in bash variable 'foo'
    /bin/echo "Current position: >>${foo}<<"
}
crsrSetPos(){
#TODO
  x=$1
  y=$2
  /bin/echo "${ESC}[${y};${x}H"
}

crsrUp(){
  chars=$1
  /bin/echo "${ESC}[${chars}A"
}
crsrDown(){
  chars=$1
  /bin/echo "${ESC}[${chars}B"
}
crsrRight(){
  chars=$1
  /bin/echo "${ESC}[${chars}C"
}
crsrLeft(){
  chars=$1
  /bin/echo "${ESC}[${chars}D"
}

zosfind(){
  # Use the standard z/OS find utility; If the findutils package is installed,
  # the installed find command takes precedence but is not compatible with the
  # standard zos find [regex searches for "-name" are not allowed, but
  # "-wholename" is not available on standard zosfind. For the tooling to be
  # consistent across platofmrs (where findutils is/is not installed) use the
  # standard zos version
  /bin/find $*
}

defineEnvironment()
{
  # Required for proper operation of z/OS auto-conversion support
  export _BPXK_AUTOCVT=ON
  export _CEE_RUNOPTS="$_CEE_RUNOPTS FILETAG(AUTOCVT,AUTOTAG) POSIX(ON)"
  export _TAG_REDIR_ERR=txt
  export _TAG_REDIR_IN=txt
  export _TAG_REDIR_OUT=txt

  # Required for proper operation of xlclang
  export _CC_CCMODE=1
  export _C89_CCMODE=1
  export _CXX_CCMODE=1

  # Required for proper operation of (USS shipped) sed
  export _UNIX03=YES

  # Use /bin/cat as the pager in case xlclang help is displayed, we don't want to wait for input
  export PAGER=/bin/cat
}

#
# For now, explicitly specify /bin/echo to ensure we get the EBCDIC echo since the escape
# sequences are EBCDIC escape sequences
#
printColors()
{
  /bin/echo "$1"
}

zopenInitialize()
{
  defineEnvironment
  defineANSI
  processConfig
}

printVerbose()
{
  [ -z "${-%%*x*}" ] && set +x && xtrc="-x" || xtrc=""
  if ${verbose}; then
    printColors "${NC}${GREEN}${BOLD}VERBOSE${NC}: '${1}'" >&2
  fi
  [ ! -z "$xtrc" ] && set -x
}

printHeader()
{
  [ -z "${-%%*x*}" ] && set +x && xtrc="-x" || xtrc=""
  printColors "${NC}${YELLOW}${BOLD}${UNDERLINE}${1}${NC}" >&2
  [ ! -z "$xtrc" ] && set -x
}

runAndLog()
{
  printVerbose "$1"
  eval "$1"
  rc=$?
  if [ ! -z "${SSH_TTY}" ]; then
    chtag -r $SSH_TTY
  fi
  return $rc
}

runInBackgroundWithTimeoutAndLog()
{
  command="$1"
  timeout="$2"

  printVerbose "$command with timeout of ${timeout}s"
  eval "$command &; TEEPID=$!"
  PID=$!
  n=0
  while [ $n -le $timeout ]; do
    kill -0 $PID 2>/dev/null
    if [ $? != 0 ]; then
      wait $PID
      if [ ! -z "${SSH_TTY}" ]; then
        chtag -r $SSH_TTY
      fi
      rc=$?
      return $rc
    else
      sleep 1
      n=`expr $n + 1`
    fi
  done
  kill -9 $PID
  kill -9 $TEEPID
  printError "TIMEOUT: (PID: $PID): $command"
}

printSoftError()
{
  [ -z "${-%%*x*}" ] && set +x && xtrc="-x" || xtrc=""
  printColors "${NC}${RED}${BOLD}***ERROR: ${NC}${RED}${1}${NC}" >&2
  [ ! -z "$xtrc" ] && set -x
}

printError()
{
  [ -z "${-%%*x*}" ] && set +x && xtrc="-x" || xtrc=""
  printSoftError "${1}"
  [ ! -z "$xtrc" ] && set -x
  exit 4
}

printWarning()
{
  [ -z "${-%%*x*}" ] && set +x && xtrc="-x" || xtrc=""
  printColors "${NC}${YELLOW}${BOLD}***WARNING: ${NC}${YELLOW}${1}${NC}" >&2
  [ ! -z "$xtrc" ] && set -x
}

printInfo()
{
  [ -z "${-%%*x*}" ] && set +x && xtrc="-x" || xtrc=""
  printColors "$1" >&2
  [ ! -z "$xtrc" ] && set -x
}

# Used to input sensitive data - turns off echo to the screen for the input
getInputHidden()
{
  stty -echo
  read zopen_input
  echo $zopen_input
  stty echo
}

getInput()
{
  read zopen_input < /dev/tty
  echo $zopen_input
}

printElapsedTime()
{
  printType=$1
  functionName=$2
  startTime=$3
  elapsedTime=$(( $SECONDS - $startTime ))

  elapsedTimeOutput="$functionName completed in $elapsedTime seconds."

  case $printType in
    "info")
      printInfo "$elapsedTimeOutput"
      ;;
    "verbose")
      printVerbose "$elapsedTimeOutput"
      ;;
  esac
}

processConfig()
{
  if [ -f "$HOME/.zopen-config" ]; then
    . "$HOME/.zopen-config"
  fi
}

parseDeps()
{
  dep="$1"
  version=$(echo $dep | awk -F '[>=<]+' '{print $2}')
  if [ -z "$version" ]; then
    operator=""
    dep=$(echo $dep | awk -F '[>=<]+' '{print $1}')
  else
    operator=$(echo $dep | awk -F '[0-9.]+' '{print $1}' | awk -F '^[a-zA-Z]+' '{print $2}')
    dep=$(echo $dep | awk -F '[>=<]+' '{print $1}')
    case $operator in
      ">=") ;;
      "=") ;;
      *) printError "$operator is not supported."
    esac
    major=$(echo $version | awk -F. '{print $1}')
    minor=$(echo $version | awk -F. '{print $2}')
    if [ -z "$minor" ]; then
      minor=0
    fi
    patch=$(echo $version | awk -F. '{print $3}')
    if [ -z "$patch" ]; then
      patch=0
    fi
    prerelease=$(echo $version | awk -F. '{print $4}')
    if [ -z "$prerelease" ]; then
      prerelease=0
    fi
  fi

  echo "$dep|$operator|$major|$minor|$patch|$prerelease"
}

compareVersions()
{
  v1="$1"
  v2="$2"
  awk -v v1="$v1" -v v2="$v2" '
  function vercmp(v1, v2) {
    n1 = split(v1, v1_array, ".")
    n2 = split(v2, v2_array, ".")

    for (i = 1; i <= n1 || i <= n2; i++) {
      if (v1_array[i] != v2_array[i]) {
        return (v1_array[i] < v2_array[i] ? -1 : 1)
      }
    }
    return 0
  }

  BEGIN {
    if (vercmp(v1, v2) >= 0) {
      exit 0
    } else {
      exit 1
    }
  }
  '

  return $?
}

validateVersion()
{
  version=$1
  operator=$2
  requestedVersion=$3
  dependency=$4
  if [ ! -z "$operator" ] && [ -z "$version" ]; then
    printVerbose "$operator ${requestedVersion} requsted, but no version file found in $versionPath." 
    return 1
  elif [ ! -z "$operator" ] && ! compareVersions "${version}" "${requestedVersion}"; then
    printVerbose "$dependency does not satisfy ${version} $operator ${requestedVersion}"
    return 1
  fi
  return 0
}

deleteDuplicateEntries() 
{
  value=$1
  delim=$2
  echo "$value$delim" | awk -v RS="$delim" '!($0 in a) {a[$0]; printf("%s%s", col, $0); col=RS; }' | sed "s/${delim}$//"
}

# Logging Types
LOG_E="ERROR"    # If there was a failure and a command failed 
LOG_W="WARNING"  # If an error occurred but there was a workaround/fallback
LOG_I="INFO"     # General information
LOG_A="AUDIT"    # Security-type log for admin activities

# Logging Categories - more than one possible for a log entry
CAT_CONFIG="C"    # Configuration change
CAT_FILE="F"      # File handling (eg. downloading)
CAT_INSTALL="I"   # Install processing
CAT_NETWORK="N"   # Network processing
CAT_PKG="P"       # Package handling
CAT_QUERY="Q"     # Query processing
CAT_REMOVE="R"    # Removal handling  
CAT_SYS="S"       # Related to the underlying native z/OS system
CAT_ZOPEN="Z"     # Related to the zopen system itself 

syslog() {
  fd=$1
  type=$2
  categories=$3
  module=$4
  location=$5
  msg=$6
  if [ ! -e $fd ]; then
    mkdir -p "$(dirname $fd)" 
    touch $fd
  fi
  echo $(date +"%F %T") $(id | cut -d' ' -f1)::$module:$type:$categories:$location:$msg >> $fd
  
}
zopenInitialize
