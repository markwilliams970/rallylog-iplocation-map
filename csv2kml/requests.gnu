set term png size 1024, 768
set output 'requests.png'
set timefmt '%Y-%m-%d
set xdata time
set datafile sep ','
set grid layerdefault   linetype 0 linewidth 1.000,  linetype 0 linewidth 1.000
set title "Subscription 2028 Rally Usage"
set ylabel "Requests by Site"
set lmargin  16
set rmargin  9
set tmargin  4
set yrange [0:*]
plot 'requests.csv' u 1:2 w linesp title "Site1" linewidth 2 smooth csplines, 'requests.csv' u 1:3 w linesp title "Site2" linewidth 2 smooth csplines, 'requests.csv' u 1:4 w linesp title "Site3" linewidth 2 smooth csplines, 'requests.csv' u 1:5 w linesp title "Site4" linewidth 2 smooth csplines