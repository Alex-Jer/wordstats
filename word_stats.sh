#!/usr/bin/env bash

# Validação de parâmetros
if ! [ "$1" ] || ! [ "$2" ]; then
  echo >&2 "[ERROR] Insufficient parameters!"
  echo >&2 "./word_stats.sh Cc|Pp|Tt INPUT [iso3166]"
  exit 1
fi

# set -u # É obrigatório usar?

mode="$1"
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

# Validação de tipo de ficheiro
if [[ $filename == *.txt ]]; then
  echo >&2 "'$filename': Text file"
else
  echo >&2 "'$filename': PDF file"
fi

echo >&2 "[INFO] Processing '$filename'"

# Validação da existência de Stop Words
if [ "$mode" == 'c' ] || [ "$mode" == 'p' ] || [ "$mode" == 't' ]; then
  echo >&2 "[INFO] STOP WORDS will be filtered out"
  case "$stopwordsLang" in
  pt) # Ficheiro de Stop Words em português
    echo >&2 "Stop Words file 'pt': '$stopwordsPath' ($(wc -l "$stopwordsPath" | cut -d'S' -f1)words)"
    ;;
  en) # Ficheiro de Stop Words em inglês
    echo >&2 "Stop Words file 'en': '$stopwordsPath' ($(wc -l "$stopwordsPath" | cut -d'S' -f1)words)"
    ;;
  *)
    echo "[ERROR] Invalid language"
    exit 1
    ;;
  esac
fi

case "$mode" in
c) # Contagem de cada palavra sem Stop Words
  tr -d 0-9 <"$filename" | tr -d '[:punct:]' | tr -s ' ' '\n' | grep -vwif "$stopwordsPath" |
    sort | uniq -c | sort -r | cut -c 5- | nl >result---"$filenameNoExt".txt
  ;;
C) # Contagem de cada palavra com Stop Words
  tr -d 0-9 <"$filename" | tr -d '[:punct:]' | tr -s ' ' '\n' | tr -d ' ' |
    sort | uniq -c | sort -r | cut -c 5- | nl >result---"$filenameNoExt".txt
  ;;
p) # Gráfico da contagem de cada palavra sem Stop Words
  ;;
P) # Gráfico da contagem de cada palavra com Stop Words
  ;;
t) # Top N da contagem de cada palavra sem Stop Words
  ;;
T) # Top N da Contagem de cada palavra com Stop Words
  ;;
*)
  echo >&2 "[ERROR] Unknown command '$mode'"
  exit 1
  ;;
esac

# Output do número total de palavras e dos detalhes do ficheiro gerado
totalWords=$(wc -l result---"$filenameNoExt".txt | cut -d'r' -f1)
echo "RESULTS: 'result---$filenameNoExt.txt'" &&
  ls -al result---"$filenameNoExt".txt
echo "$totalWords distinct words"
