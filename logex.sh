#!/bin/bash

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
  -d | --days)
    DAYS="$2"
    shift
    shift
    ;;
  *)
    POSITIONAL_ARGS+=("$1")
    shift
    ;;
  esac
done

function getDate() {
  i=$1
  TODAY=$(date +%F)

  # Check if the operating system is macOS or Linux
  if [[ $(uname) == "Darwin" ]]; then
      # macOS
      DATE=$(date -v "-$i"d +%F)
  else
      DATE=$(date -d "$TODAY - $i day" +%F)
  fi

  echo $DATE
}

function setProjectRoot() {
  PROJECT_ROOT=$1

  if [[ -z $PROJECT_ROOT ]]; then
    PROJECT_ROOT=$(pwd)
  elif [[ ! -d $PROJECT_ROOT ]]; then
    echo "$PROJECT_ROOT: No such file or directory"
    exit 1
  fi

  echo $PROJECT_ROOT
}

function setDays() {
  DAYS=$1

  if [[ -z $DAYS ]]; then
    DAYS=1
  fi

  echo $DAYS
}

function logger() {
  DATE=$1
  AUTHOR=$2
  PROJECT_PATH=$3
  PROJECT=$(basename $PROJECT_PATH)

  cd $PROJECT_PATH
  LOG=$(git log --author="$AUTHOR" --all --no-merges --pretty=format:%s --after="$DATE 00:00" --before="$DATE 23:59" | sed 's/^/• /')

  if [[ ! -z $LOG ]]; then
    echo 1
    echo -e "\033[0;34m\033[1m$PROJECT\033[0m" >&2
    echo -e "$LOG\n" >&2
  else
    echo 0
  fi
}

DAYS=$(setDays $DAYS)
AUTHOR=$(git config user.name)
PROJECT_ROOT=$(setProjectRoot ${POSITIONAL_ARGS[0]})

cd $PROJECT_ROOT
PROJECT_ROOT_IS_GIT=$(git rev-parse --is-inside-work-tree 2>/dev/null)

if [[ $PROJECT_ROOT_IS_GIT ]]; then
  DATE=$(date +%F)

  for ((i = $DAYS - 1; i >= 0; i--)); do
    DATE==$(getDate ${i})

    echo -e "\033[0;33m\033[1m\033[4m$DATE\033[0m"
    COUNT=$(logger $DATE "$AUTHOR" $PROJECT_ROOT)

    if [[ $COUNT -eq 0 ]]; then
      printf '\033[1A\033[K'
    fi
  done
else
  PROJECTS=($(ls -d "$PROJECT_ROOT"/*/))
  DATE=$(date +%F)

  for ((i = $DAYS - 1; i >= 0; i--)); do
    COUNT=0
    DATE=$(getDate ${i})
    echo -e "\033[0;33m\033[1m\033[4m$DATE\033[0m"

    for j in ${!PROJECTS[@]}; do
      PROJECT_PATH=${PROJECTS[$j]}

      cd $PROJECT_PATH
      PROJECT_ROOT_IS_GIT=$(git rev-parse --is-inside-work-tree 2>/dev/null)

      if [[ $PROJECT_ROOT_IS_GIT ]]; then
        COUNT=$(($COUNT + $(logger $DATE "$AUTHOR" $PROJECT_PATH)))
      fi
    done
    if [[ $COUNT -eq 0 ]]; then
      printf '\033[1A\033[K'
    fi
  done
fi
