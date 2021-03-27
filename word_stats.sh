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
filenameNoExt="${filename%.*}"
stopwordsPath="StopWords/$3.stop_words.txt"
stopwordsLang="$3"

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

# Validação da existência de Stop Words
[ "$1" == 'c' ] || [ "$1" == 'p' ] || [ "$1" == 't' ] && removeStopWords=true

if [ "$removeStopWords" = true ]; then
  echo >&2 "[INFO] STOP WORDS will be filtered out"
  # Se o ficheiro de Stop Words estiver em português
  if [ "$stopwordsLang" == "pt" ]; then
    echo >&2 "Stop Words file 'pt': '$stopwordsPath' ($(wc -l "$stopwordsPath" | cut -d'S' -f1)words)"
  # Se o ficheiro de Stop Words estiver em inglês
  else
    echo >&2 "Stop Words file 'en':"
  fi
  # Criação do ficheiro com o ranking das palavras sem StopWords
  echo " COUNT MODE"
  tr -d 0-9 <"$filename" | tr -d '[:punct:]' | tr -s ' ' '\n' | grep -vwif "$stopwordsPath" |
    sort | uniq -c | sort -r | cut -c 5- | nl >&1 | tee result---"$filenameNoExt".txt
else
  # Criação do ficheiro com o ranking das palavras com StopWords
  echo >&2 "[INFO] STOP WORDS will be counted"
  echo " COUNT MODE"
  tr -d 0-9 <"$filename" | tr -d '[:punct:]' | tr -s ' ' '\n' | tr -d ' ' |
    sort | uniq -c | sort -r | cut -c 5- | nl >&1 | tee result---"$filenameNoExt".txt
fi

# Output do número total de palavras e dos detalhes do ficheiro gerado
totalWords=$(wc -l result---"$filenameNoExt".txt | cut -d'r' -f1)
echo "RESULTS: 'result---$filenameNoExt.txt'" &&
  ls -al result---"$filenameNoExt".txt
echo "$totalWords distinct words"
