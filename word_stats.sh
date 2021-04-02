#!/usr/bin/env bash

# Arguments validation
if ! [ "$1" ] || ! [ "$2" ]; then
  echo >&2 "[ERROR] Insufficient parameters!"
  echo >&2 "./word_stats.sh Cc|Pp|Tt INPUT [iso3166]"
  exit 1
fi

mode="$1"
filepath="$2"
filename="$(basename "$2")"
filenameNoExt="${filename%.*}"

# If the user specifies the Stop Words language
if [ "$3" ]; then
  stopwordsLang="$3"
else
  # Assumes English by default
  stopwordsLang="en"
fi

stopwordsPath="StopWords/$stopwordsLang.stop_words.txt"

# File path validation
if ! test -f "$filepath"; then
  echo >&2 "[ERROR] File '$filename' not found!"
  exit 1
fi

# File type validation
if [[ $filename == *.txt ]]; then
  echo >&2 "'$filename': Text file"
else
  # Makes a new temporary text file from the PDF file
  echo >&2 "'$filename': PDF file"
  isPdf=true
  pdftotext "$filepath" "temp---$filenameNoExt".txt
  filepath="temp---$filenameNoExt".txt
fi

# Stop Words validation
if [ "$mode" == 'c' ] || [ "$mode" == 'p' ] || [ "$mode" == 't' ]; then
  echo >&2 "[INFO] STOP WORDS will be filtered out"
  case "$stopwordsLang" in
  pt) # Portuguese Stop Words file
    echo >&2 "Stop Words file 'pt': '$stopwordsPath' ($(wc -l "$stopwordsPath" | cut -d'S' -f1)words)"
    ;;
  en) # English Stop Words file
    echo >&2 "Stop Words file 'en': '$stopwordsPath' ($(wc -l "$stopwordsPath" | cut -d'S' -f1)words)"
    ;;
  *)
    echo "[ERROR] Invalid language"
    exit 1
    ;;
  esac
fi

# Output the number of distinct words and the details of the "result" file
details_output() {
  totalWords=$(wc -l <result---"$filenameNoExt".txt)
  case "$mode" in
  c | C)
    echo "RESULTS: 'result---$filenameNoExt.txt'" &&
      ls -al result---"$filenameNoExt".txt
    echo "$totalWords distinct words"
    ;;
  *)
    # If the WORD_STATS_TOP environment variable exists but isn't a positive integer
    if ! [[ -z "$WORD_STATS_TOP" || ($WORD_STATS_TOP =~ ^[0-9]+$) && ($WORD_STATS_TOP -gt 0) ]]; then
      top=10
      echo "'$WORD_STATS_TOP' not a positive number (using default 10)"
      echo "WORD_STATS_TOP=$top"
    else
      # If the WORD_STATS_TOP environment variable doesn't exist
      if ! [ "$WORD_STATS_TOP" ]; then
        top=10
        echo "Environment variable 'WORD_STATS_TOP' is empty (using default 10)"
        echo "WORD_STATS_TOP=$top"
      # If the WORD_STATS_TOP environment variable is correct
      else
        top=$WORD_STATS_TOP
        echo "WORD_STATS_TOP=$top"
      fi
    fi
    echo "RESULTS: 'result---$filenameNoExt.txt'" &&
      ls -al result---"$filenameNoExt".txt
    ;;
  esac
}

case "$mode" in
c) # Count words excluding Stop Words
  echo >&2 "[INFO] Processing '$filename'"
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | grep -vwif "$stopwordsPath" | sort | uniq -c |
    sort -nr | cut -c 5- | nl >result---"$filenameNoExt".txt
  details_output
  ;;
C) # Count words including Stop words
  echo >&2 "[INFO] Processing '$filename'"
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | tr -d ' ' | sort | uniq -c |
    sort -nr | cut -c 5- | nl >result---"$filenameNoExt".txt
  details_output
  ;;
p) # Bar graph of the top WORD_STATS_TOP words excluding Stop Words
  echo >&2 "[INFO] Processing '$filename'"
  details_output
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | grep -vwif "$stopwordsPath" | sort | uniq -c |
    sort -nr | cut -c 5- | head -n "$top" | nl >result---"$filenameNoExt".txt
  # gnuplot -e "filepath='$filename.png'" bar.gp
  gnuplot <bar.gp
  # display out.png
  ;;
P) # Bar graph of the top WORD_STATS_TOP words including Stop Words
  echo >&2 "[INFO] Processing '$filename'"
  details_output
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | tr -d ' ' | sort | uniq -c |
    sort -nr | cut -c 5- | nl | head -n "$top" >result---"$filenameNoExt".txt
  gnuplot <bar.gp
  # display out.png
  ;;
t) # Top WORD_STATS_TOP words excluding Stop Words
  echo >&2 "[INFO] Processing '$filename'"
  details_output
  echo "-------------------------------------"
  echo "# TOP $top elements"
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | grep -vwif "$stopwordsPath" | sort | uniq -c |
    sort -nr | cut -c 5- | head -n "$top" | nl | tee result---"$filenameNoExt".txt
  echo "-------------------------------------"
  ;;
T) # Top WORD_STATS_TOP words including Stop Words
  echo >&2 "[INFO] Processing '$filename'"
  details_output
  echo "-------------------------------------"
  echo "# TOP $top elements"
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | tr -d ' ' | sort | uniq -c |
    sort -nr | cut -c 5- | nl | head -n "$top" | tee result---"$filenameNoExt".txt
  echo "-------------------------------------"
  ;;
*)
  echo >&2 "[ERROR] Unknown command '$mode'"
  exit 1
  ;;
esac

# Deletes the temporary file created by pdftotext
if [ $isPdf ]; then rm "$filepath"; fi
