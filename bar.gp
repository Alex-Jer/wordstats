set terminal png
set output "out.png"
set boxwidth 0.5
set style fill solid
set autoscale y
set autoscale x
set offsets graph 0, 0, 0.05, 0.05
plot "result---exemplo_pt.txt" using 1:2:xtic(3) with boxes