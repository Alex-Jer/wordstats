#!/usr/bin/env bash

# Arguments validation
if ! [ "$1" ] || ! [ "$2" ]; then
  echo >&2 "[ERROR] Insufficient parameters!"
  echo >&2 "./word_stats.sh Cc|Pp|Tt INPUT [iso3166]"
  exit 1
fi

# Convert to lowercase and check whether the argument is correct
flagLower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
if [ "$flagLower" != 'c' ] && [ "$flagLower" != 'p' ] && [ "$flagLower" != 't' ]; then
  echo >&2 "[ERROR] Unknown command '$1'"
  exit 1
fi

mode="$1"
filepath="$2"
filename="$(basename "$2")"
filenameNoExt="${filename%.*}"

# If the user specifies the Stop Words language
if [ "$3" ]; then
  if [ "$3" != "pt" ] && [ "$3" != "en" ]; then
    echo "[ERROR] Invalid language"
    exit 1
  else
    stopwordsLang="$3"
  fi
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
  case "$stopwordsLang" in
  pt) # Portuguese Stop Words file
    echo >&2 "STOP WORDS will be filtered out"
    echo >&2 "Stop Words file 'pt': '$stopwordsPath' ($(wc -l "$stopwordsPath" | cut -d'S' -f1)words)"
    ;;
  en) # English Stop Words file
    echo >&2 "STOP WORDS will be filtered out"
    echo >&2 "Stop Words file 'en': '$stopwordsPath' ($(wc -l "$stopwordsPath" | cut -d'S' -f1)words)"
    ;;
  esac
else
  echo "STOP WORDS will be counted"
fi

# If the WORD_STATS_TOP environment variable exists but isn't a positive integer
if [ "$mode" != "c" ] && [ "$mode" != "C" ]; then
  if ! [[ -z "$WORD_STATS_TOP" || ($WORD_STATS_TOP =~ ^[0-9]+$) && ($WORD_STATS_TOP -gt 0) ]]; then
    top=10
    echo "'$WORD_STATS_TOP' not a positive number (using default 10)"
    echo "WORD_STATS_TOP=$top"
  else
    # If the WORD_STATS_TOP environment variable doesn't exist
    if ! [ "$WORD_STATS_TOP" ]; then
      top=10
      echo "Environment variable 'WORD_STATS_TOP' is empty (using default 10)"
    # If the WORD_STATS_TOP environment variable is correct
    else
      top=$WORD_STATS_TOP
      echo "WORD_STATS_TOP=$top"
    fi
  fi
fi

# Output the number of distinct words and the details of the "result" file
details_output() {
  totalWords=$(wc -l <result---"$filenameNoExt".txt)
  if [ "$mode" != "p" ] && [ "$mode" != "P" ]; then
    ls -al result---"$filenameNoExt".txt
    if [ "$mode" == "c" ] || [ "$mode" == "C" ]; then
      echo "RESULTS: 'result---$filenameNoExt.txt'"
      echo "$totalWords distinct words"
    fi
  else
    ls -al result---"$filenameNoExt".*
  fi
}

# Creates a bar graph with the specified gnuplot variables
gnuplot_chart() {
  # Checks for Stop Words and changes the graph's title accordingly
  if [ "$1" = true ]; then
    gnuplot \
      -e "output_image='result---$filenameNoExt.png'" \
      -e "output_html='result---$filenameNoExt.html'" \
      -e "input_file='result---$filenameNoExt.txt'" \
      -e "original_file='$filename'" \
      -e "date_time='$(date "+%Y.%m.%d-%Hh%M:%S")'" \
      -e "stopwords='with stop words'" \
      bar_chart.gp
  else
    gnuplot \
      -e "output_image='result---$filenameNoExt.png'" \
      -e "output_html='result---$filenameNoExt.html'" \
      -e "input_file='result---$filenameNoExt.txt'" \
      -e "original_file='$filename'" \
      -e "date_time='$(date "+%Y.%m.%d-%Hh%M:%S")'" \
      -e "stopwords='\"$stopwordsLang\" stop words removed'" \
      bar_chart.gp
  fi
  details_output
  display result---"$filenameNoExt".png &
}

# Outputs the details and ranking
ranking_output() {
  details_output
  echo "-------------------------------------"
  echo "# TOP $top elements"
  cat result---"$filenameNoExt".txt
  echo "-------------------------------------"
}

echo >&2 "[INFO] Processing '$filename'"

case "$mode" in
c) # Count words excluding Stop Words
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | grep -vwif "$stopwordsPath" | sort | uniq -c |
    sort -nr | cut -c 5- | nl >result---"$filenameNoExt".txt
  details_output
  ;;
C) # Count words including Stop words
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | tr -d ' ' | sort | uniq -c |
    sort -nr | cut -c 5- | nl >result---"$filenameNoExt".txt
  details_output
  ;;
p) # Bar char of the top WORD_STATS_TOP words excluding Stop Words
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | grep -vwif "$stopwordsPath" | sort | uniq -c |
    sort -nr | cut -c 5- | head -n "$top" | nl >result---"$filenameNoExt".txt
  gnuplot_chart false
  ;;
P) # Bar char of the top WORD_STATS_TOP words including Stop Words
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | tr -d ' ' | sort | uniq -c |
    sort -nr | cut -c 5- | nl | head -n "$top" >result---"$filenameNoExt".txt
  gnuplot_chart true
  ;;
t) # Top WORD_STATS_TOP words excluding Stop Words
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | grep -vwif "$stopwordsPath" | sort | uniq -c |
    sort -nr | cut -c 5- | head -n "$top" | nl >result---"$filenameNoExt".txt
  ranking_output
  ;;
T) # Top WORD_STATS_TOP words including Stop Words
  grep -oE '[[:alpha:]]*' <"$filepath" | tr -s ' ' '\n' | tr -d ' ' | sort | uniq -c |
    sort -nr | cut -c 5- | nl | head -n "$top" >result---"$filenameNoExt".txt
  ranking_output
  ;;
*)
  echo >&2 "[ERROR] Unknown command '$mode'"
  exit 1
  ;;
esac

# Deletes the temporary file created by pdftotext
if [ $isPdf ]; then rm "$filepath"; fi
