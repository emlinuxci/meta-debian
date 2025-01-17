#!/bin/sh
#
# Generate HTML output from test result.

THISDIR=$(dirname $(readlink -f "$0"))
LOGDIR=$THISDIR/logs
HTMLDIR=$THISDIR/html

GREEN="#2ecc71"
GREY="#bdc3c7"
RED="#e74c3c"

TESTING_LOGS="https://raw.githubusercontent.com/tswcos/meta-debian-test-logs/master"

for d in $LOGDIR/*; do
	test -d $d || continue

	distro=`basename $d`
	echo "DISTRO: $distro"

	for m in $LOGDIR/$distro/*; do
		test -d $m || continue

		machine=`basename $m`
		echo "Generating html for $machine..."

		mkdir -p $HTMLDIR/$distro/$machine
		index=$HTMLDIR/$distro/$machine/index.html
		cat > $index << EOF
<html>
<head><title>meta-debian Status</title>
<style>
.main_table table {
    counter-reset: rowNumber;
}.main_table tr {
    counter-increment: rowNumber;
}.main_table tr td:first-child::before {
    content: counter(rowNumber);
}
</style>
</head>

<body>
<h1>meta-debian Status</h1>
<br>
<table>
<tr><td><b>Built distro</b></td><td>$distro</td></tr>
<tr><td><b>Built machine</b></td><td>$machine</td></tr>
</table>
<br>
<br><table class="main_table">
<thead>
<tr bgcolor="$GREY">
<th></th>
<th>Package</th>
<th>Version</th>
<th>Build Status</th>
<th>Ptest Status<br/>(PASS/SKIP/FAIL)</th>
</tr></thead>
EOF
		if [ ! -f $LOGDIR/$distro/$machine/result.txt ]; then
			continue
		fi

		while read -r line; do
			recipe=`echo $line | awk '{print $1}'`
			version=`echo $line | awk '{print $2}'`
			build_status=`echo $line | awk '{print $3}'`
			ptest_status=`echo $line | awk '{print $4}'`

			build_log="$TESTING_LOGS/$distro/$machine/$recipe.build.log"
			ptest_log="$TESTING_LOGS/$distro/$machine/$recipe.ptest.log"

			if echo $build_status | grep -iq "PASS"; then
				bcolor=$GREEN
			elif echo $build_status | grep -iq "FAIL"; then
				bcolor=$RED
			else
				bcolor=$GREY
			fi

			html_ptest_status=$ptest_status
			if echo $ptest_status | grep -iq "NA"; then
				pcolor=$GREY
			else
				fail=`echo $ptest_status | cut -d/ -f3`

				pcolor=$RED
				test "$fail" = "0" && pcolor=$GREEN

				html_ptest_status="<a href=$ptest_log>$ptest_status</a>"
			fi

			html_build_status="<td bgcolor=\"$bcolor\"><a href=$build_log>$build_status</a></td>"
			html_ptest_status="<td bgcolor=\"$pcolor\">$html_ptest_status</td>"
			echo "<tr><td></td><td>$recipe</td><td>$version</td>${html_build_status}${html_ptest_status}</tr>" >> $index
		done < $LOGDIR/$distro/$machine/result.txt

		echo "</table></body></html>" >> $index
	done
done
