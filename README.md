rallylog-iplocation-map
=======================

A combination of scripts that create a Google Map of Rally Usage by IP address location for a particular Rally Subscription.

![Sample IP Location Map](https://raw.github.com/markwilliams970/rallylog-iplocation-map/master/img/screenshot.png)
![Sample Requests Graph](https://raw.githubusercontent.com/markwilliams970/rallylog-iplocation-map/master/html/img/requests.png)

[Example Map](https://people.rallydev.com/markwilliams/rally1-b1f17b6/geoIPReport.html)

Dependencies:

1. Python (tested using [Virtual Env](http://www.virtualenv.org/en/latest/) and Python 2.7)
	1. Python modules: 
	2. [Splunk API for Python](http://dev.splunk.com/view/python-sdk/SP-CAAAEBB)
2. Perl (tested using [Perlbrew](http://perlbrew.pl/) and Perl 5.18.2)
	1. Perl modules: 
	2. Geo::IP::PurePerl
	3. HTML::Entities
	4. [GeoIP Cities database](http://dev.maxmind.com/geoip/legacy/install/city/)
3. GnuPlot (tested using [GnuPlot](http://www.gnuplot.info/) 4.6 patchlevel 5) 
