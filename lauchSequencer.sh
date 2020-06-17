#!/usr/bin/env bash

FILEPATH=""
CLASSNAME=""
SUBSYSTEM=""
OBSMODE=""
VERSION=""

function usage() {
  echo
  echo -e "usage: $script_name COMMAND [--filePath | -f <script file>] [--subsystem | -s <Subsystem>] [--obsMode | -o <Observing mode>] [--script-version | -v <version of scripts repo>]"

  echo "  --filePath | -f <script file>               Path of the script"
  echo "  --subsystem | -s <Subsystem>                (Optional) Subsystem of the Sequencer. Default value: ESW"
  echo "  --obsMode | -o <Observing mode>             (Optional) Observing mode of the Sequencer. Default value: <class name of the script>"
  echo "  --script-version | -v <version of scripts repo>    (Optional) Version of Sequencer-Scripts repo with which script is compatible."
}

function parseArgs() {
  while [[ $# -gt 1 ]]; do
    key="$1"

    case ${key} in
    --filePath | -f)
      FILEPATH=$2
      filename=${FILEPATH##*/}
      CLASSNAME=${filename%.*}
      CLASSNAME="$(tr '[:lower:]' '[:upper:]' <<<${CLASSNAME:0:1})${CLASSNAME:1}"
      ;;

    --subsystem | -s)
      SUBSYSTEM=$2
      ;;

    --obsMode | -o)
      OBSMODE=$2
      ;;

    --script-version | -v)
      VERSION=":${2}"
      ;;

    *)
      echo "[ERROR] Unknown arguments provided for start command. Find usage below:"
      usage
      ;;
    esac
    shift
    shift
  done

  if [[ ${FILEPATH} == "" ]]; then
    echo "[ERROR] Script path cannot be empty"
    usage
    exit 1
  fi
}

parseArgs "$@"

# Add default subsystem if not provided
if [[ ${SUBSYSTEM} == "" ]]; then
  SUBSYSTEM="ESW"
fi

# Add default obsMode if not provided
if [[ ${OBSMODE} == "" ]]; then
  OBSMODE="${CLASSNAME}"
fi

# ---------------- Compiling ------------------
echo "[INFO] Compiling the script:" $FILEPATH
JARNAME=$CLASSNAME.jar
kotlinc -jvm-target 1.8 -Xuse-experimental=kotlin.time.ExperimentalTime -classpath "$(cs fetch ocs-app$VERSION --classpath)" $FILEPATH -d $JARNAME

if [[ $? -eq 1 ]]; then
  echo "[ERROR] Compilation failed. Fix the compiler errors and also Make sure script is .kts file"
  exit 1
fi
echo "[INFO] Compilation completed. Compiled jar name:" $JARNAME

# ---------------- Launching sequencer ------------------
echo "[INFO] Launching sequencer with Subsystem:" $SUBSYSTEM "and Observation Mode:" $OBSMODE
cs launch --extra-jars $JARNAME -J -Dscripts.$SUBSYSTEM.$OBSMODE.scriptClass="$CLASSNAME" ocs-app$VERSION -- sequencer -s $SUBSYSTEM -m $OBSMODE
