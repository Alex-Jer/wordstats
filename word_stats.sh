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

# Se o utilizador especificar a língua das Stop Words
if [ "$3" ]; then
  stopwordsLang="$3"
else
  # Se não especificar, assume inglês
  stopwordsLang="en"
fi

stopwordsPath="StopWords/$stopwordsLang.stop_words.txt"

# Validação do caminho do ficheiro
if ! test -f "$filepath"; then
  echo >&2 "[ERROR] File '$filename' not found!"
  exit 1
fi

# Validação de tipo de ficheiro
if [[ $filename == *.txt ]]; then
  echo >&2 "'$filename': Text file"
else
  # Cria um novo ficheiro de texto a partir do PDF temporariamente
  echo >&2 "'$filename': PDF file"
  isPdf=true
  pdftotext "$filepath" "temp---$filenameNoExt".txt
  filepath="temp---$filenameNoExt".txt
fi

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

# Output do número total de palavras e dos detalhes do ficheiro gerado
details_output() {
  totalWords=$(wc -l <result---"$filenameNoExt".txt)
  case "$mode" in
  c | C)
    echo "RESULTS: 'result---$filenameNoExt.txt'" &&
      ls -al result---"$filenameNoExt".txt
    echo "$totalWords distinct words"
    ;;
  p | P)
    #
    ;;
  t | T)
    if [[ ($WORD_STATS_TOP =~ ^[0-9]+$) && $WORD_STATS_TOP -gt 0 ]]; then
      top=$WORD_STATS_TOP
      echo "WORD_STATS_TOP=$top"
    else
      top=10
      echo "Environment variable 'WORD_STATS_TOP' is empty (using default 10)"
    fi
    echo "RESULTS: 'result---$filenameNoExt.txt'" &&
      ls -al result---"$filenameNoExt".txt
    ;;
  esac

}

case "$mode" in
c) # Contagem de cada palavra sem Stop Words
  echo >&2 "[INFO] Processing '$filename'"
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | grep -vwif "$stopwordsPath" | sort | uniq -c |
    sort -r | cut -c 5- | nl >result---"$filenameNoExt".txt
  details_output
  ;;
C) # Contagem de cada palavra com Stop Words
  echo >&2 "[INFO] Processing '$filename'"
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | tr -d ' ' | sort | uniq -c |
    sort -r | cut -c 5- | nl >result---"$filenameNoExt".txt
  details_output
  ;;
p) # Gráfico da contagem de cada palavra sem Stop Words
  echo >&2 "[INFO] Processing '$filename'"
  ;;
P) # Gráfico da contagem de cada palavra com Stop Words
  echo >&2 "[INFO] Processing '$filename'"
  ;;
t) # Top N da contagem de cada palavra sem Stop Words
  echo >&2 "[INFO] Processing '$filename'"
  details_output
  echo "-------------------------------------"
  echo "# TOP $top elements"
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | grep -vwif "$stopwordsPath" | sort | uniq -c |
    sort -r | cut -c 5- | nl | head -n "$top" | tee result---"$filenameNoExt".txt
  echo "-------------------------------------"
  ;;
T) # Top N da Contagem de cada palavra com Stop Words
  echo >&2 "[INFO] Processing '$filename'"
  details_output
  echo "-------------------------------------"
  echo "# TOP $top elements"
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | tr -d ' ' | sort | uniq -c |
    sort -r | cut -c 5- | nl | head -n "$top" | tee result---"$filenameNoExt".txt
  echo "-------------------------------------"
  ;;
*)
  echo >&2 "[ERROR] Unknown command '$mode'"
  exit 1
  ;;
esac

# Apaga o ficheiro temporário criado pelo pdftotext
if [ $isPdf ]; then
  rm "$filepath"
fi
