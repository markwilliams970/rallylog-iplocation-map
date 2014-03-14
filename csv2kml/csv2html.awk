BEGIN {
	print "<html>"
	print "<head>"
	print "<title>Request Count by IP Address</title>"
	print "<style>"
	print ".table-cell {"
	print "border-style: solid;"
	print "border-width: 1px;"
	print "}"
	print "</style>"
	print "</head>"
	print "<body style=\"font-family: sans-serif\">"
	print "<table style=\"border-style: solid; border-width: 1px\">"
	print "<tr>"
	print "<td class=\"table-cell\">Source IP Address</td>"
	print "<td class=\"table-cell\">Request Count</td>"
	print "</tr>"
}
{
	print "<tr>"
	printf("<td class=\"table-cell\">%s</td>\n", $1)
	printf("<td class=\"table-cell\">%d</td>\n", $2)
	print "</tr>"
}
END {
	print "</table></body></html>"
}