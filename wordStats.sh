#!/usr/bin/env bash
tr '.' ' ' <"$2" | tr -s ' ' '\n' | sort | uniq -c | sort -r

while test $# -gt 0; do
  case "$1" in
  c)
    shift
    # first_argument=$1
    shift
    ;;
  C)
    shift
    # last_argument=$1
    shift
    ;;
  *)
    echo "Flag $1 não existe!"
    exit 1
    ;;
  esac
done
printf '\n'
