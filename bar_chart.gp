set terminal png size 00,700
set output output_file
set title noenhanced "Top words for '" . original_file . "'\nCreated: " . date_time . "\n(" . stopwords . " stop words)" font ",11"
set grid
set boxwidth 0.6
set style fill solid
set style textbox opaque
set autoscale x
set yrange [0:*]
set offsets graph 0, 0, 0.05, 0.05
set ylabel "number of occurrences"
set xlabel "words"
set label sprintf("Authors: Alexandre Jerónimo, Rafael Amaral\nCreated: %s", date_time) at graph -0.11,-0.20 font ",9"
set bmargin 7
set rmargin 25
set tmargin 15
set size square 1.3,1.3
set xtics rotate by 45 right
plot input_file using 1:2:xtic(3) title "# of occurrences" with boxes linecolor rgb "#026440",\
"" using 1:2:2 with labels boxed offset char 0.1,0 notitle 