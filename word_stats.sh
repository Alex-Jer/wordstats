#!/usr/bin/env bash

# Validação de parâmetros
if ! [ "$1" ] || ! [ "$2" ]; then
  echo >&2 "[ERROR] Insufficient parameters!"
  echo >&2 "./word_stats.sh Cc|Pp|Tt INPUT [iso3166]"
  exit 1
fi

# set -u # É obrigatório usar?

filepath="$2"
filename="$(basename "$2")"

# Validação do caminho do ficheiro
if ! test -f "$filepath"; then
  echo >&2 "[ERROR] File '$filename' not found!"
  exit 1
fi

# Validação da primeira flag (converte-a em lowercase e valida-a)
flagLower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
if [ "$flagLower" != 'c' ] && [ "$flagLower" != 'p' ] && [ "$flagLower" != 't' ]; then
  echo >&2 "[ERROR] Unknown command '$1'"
  exit 1
fi

# Validação de tipo de ficheiro
if [[ $filename == *.txt ]]; then
  echo >&2 "'$filename': Text file"
else
  echo >&2 "'$filename': PDF file"
fi

echo >&2 "[INFO] Processing '$filename'"

# Validação da existência de Stop Words e output do ranking de palavras
if [ "$1" == 'c' ] || [ "$1" == 'p' ] || [ "$1" == 't' ]; then
  echo >&2 "[INFO] STOP WORDS will be filtered out"
  if [ "$3" == "pt" ]; then
    echo >&2 "Stop Words file 'pt':"
  else
    echo >&2 "Stop Words file 'en':"
  fi
  echo " COUNT MODE"
  tr '.' ' ' <"$2" | tr -s ' ' '\n' | grep -vwf ./StopWords/"$3".stop_words.txt | sort | uniq -c | sort -r | cut -c 5- | nl
else
  echo >&2 "[INFO] STOP WORDS will be counted"
  echo " COUNT MODE"
  tr '.' ' ' <"$2" | tr -s ' ' '\n' | sort | uniq -c | sort -r | cut -c 5- | nl
fi
