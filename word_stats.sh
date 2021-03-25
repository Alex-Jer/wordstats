#!/usr/bin/env bash

# ================================================================================

# Validação de parâmetros
if ! [ "$1" ] || ! [ "$2" ]; then
  echo '[ERROR] Insufficient parameters!'
  echo './word_stats.sh Cc|Pp|Tt INPUT [iso3166]'
  exit 1
fi

# set -u # Obrigatório?

filepath="$2"
filename="$(basename "$2")"

# Validação do caminho do ficheiro
if ! test -f "$filepath"; then
  echo "[ERROR] File '$filename' not found!"
  exit 1
fi

# Validação da primeira flag (converte em lowercase e valida)
flagLower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
if [ "$flagLower" != 'c' ] && [ "$flagLower" != 'p' ] && [ "$flagLower" != 't' ]; then
  echo "[ERROR] Unknown command '$1'"
  exit 1
fi

# Validação de tipo de ficheiro
if [[ $filename == *.txt ]]; then
  echo "'$filename': Text file"
else
  echo "'$filename': PDF file"
fi

# Output do ranking de palavras
echo "[INFO] Processing '$filename'"
echo
echo ' COUNT MODE'
tr '.' ' ' <"$2" | tr -s ' ' '\n' | sort | uniq -c | sort -r | cut -c 5- | nl

printf '\n'

# while test $# -gt 0; do
# case "$1" in
# c)
#   # first_argument=$1
#   ;;
# C)
#   # last_argument=$1
#   ;;
# *)
#   echo "Flag $1 não existe!"
#   exit 1
#   ;;
# esac
# done
