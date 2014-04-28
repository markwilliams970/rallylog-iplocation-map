$1=="_time" {
	gsub(/All/, "Other",$0);
	gsub(/_time/,"_date",$0);
	printf("%s\n", $0);
}
$1!="" && $2 ~ /[0-9]+/ {
	all=$NF;
	other=all;
	for(i=2;i<NF;i++) {
		other=other-$i;
	}
	$NF=other;
	gsub(/T00:00:00.000-06:00/,"",$1);
	for(i=1;i<=NF;i++) {
		if (i<NF) {
			printf("%s,", $i);
		} else {
			printf("%s\n", $i);
		}
	}
}