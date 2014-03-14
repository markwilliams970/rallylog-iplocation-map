#!/usr/bin/perl -w

########################################
#
# IP2KML
# By Florian Roth
# 2008
#
# v 0.3
#
#########################################
#
# Uses Geo::IP:PurePerl
# http://www.maxmind.com/app/perl
#
# Uses MaxMind GeoIP Database
# http://www.maxmind.com/app/geolitecity
#

use strict;
use HTML::Entities;
use Getopt::Std;
use Geo::IP::PurePerl;
use POSIX qw(ceil floor);

# Configuration 
my $gi = Geo::IP::PurePerl->open("/usr/local/share/GeoIP/GeoLiteCity.dat", GEOIP_STANDARD);

# Max Symbol Size
my $maxsym = 5;

# Parameters
my %opts=();
getopt ('iostndec',\%opts);

my $inputfile = $opts{i};
my $outputfile = $opts{o};
my $iploc_in = $opts{s};
my $name_in = $opts{n};
my $description_in = $opts{d};

my $printhelp = 0;

if ( ! $opts{i} || ! $opts{o} || ! $opts{s} || ! $opts{t} || ! $opts{n} || ! $opts{d} ) { $printhelp = 1; }

# Check
if ( $printhelp ) {
print<<HELP

#########################################################
# IP2KML                                                #
# by Florian Roth 2008                                  #
# v 0.3                                                 #
#########################################################
        
ip2kml.pl inputfile outputfile ip* name* description* separator*
        
   -i inputfile       	Logfile to read
   -o outputfile      	KML file to write
   -s ip		ip address to extract (see definition below)
   [-t ip]		target ip address to extract (see definition below)
   -n name		name of the node (see definition below)
   -d description	description to set (see definition below)
   [-e separator] 	used for column extraction
   [-c count]           if there is a column that contains a count
        
   Field definition
   --------------------------------
   col:x for column 
   regex:x for regex extraction, parenthesis as mark
 
   (see examples below, dont use blank but \\s instead)
        
   # Regex definition example 
   perl ip2kml.pl -i modsec_audit.log -o geoip.kml -s col:3 -n regex:\\[msg\\s\\"(.*?)\\"\\] -d regex:^(.*?)\$ -e sep:\\s
        
   # Column definition
   perl ip2kml.pl -i logfile.txt -o geoips.kml -s col:3 -n col:4 -d col:5 -e sep:,
   
   # with count column
   perl ip2kml.pl -i netflow_tcp.log.csv -o storm.kml -s col:4 -t col:2 -n col:4 -d col:6 -e sep:\\" -c col:8
        
HELP
}

open IN,"<$inputfile" or die "Cant open file";
open OUT,">$outputfile" or die "Cant open file";

my @iploc = split(/:/,$iploc_in,2);
my @name = split(/:/,$name_in,2);
my @desc = split(/:/,$description_in,2);

my $separator = "\\s";
my @count;

# If column mode
if ( $iploc[0] eq "col" || $name[0] eq "col" || $desc[0] eq "col" ) {
        if ( ! $opts{e} ) { die "Column mode but no separator defined."; }
        my $sep_in = $opts{e};
        my @sep = split(/:/,$sep_in,2);
        print "\nSeparator = ".$sep[1];
        $separator = $sep[1];
        if ( $opts{c} ) {
                my $count_in = $opts{c};
                @count = split(/:/,$count_in,2);
        }
}

# If destination ip mode
our @iptar;
if ( $opts{t} ) {
      my $iptar_in = "";
      $iptar_in = $opts{t};
      @iptar = split(/:/,$iptar_in,2);
}

# Vars
my %ips;
my %ipcons;
my $latitude;
my $longitude;

# Count lines of file
    my $lines = 0;
    open(FILE, $inputfile) or die "Can't open `$inputfile': $!";
    while (sysread FILE, my $buffer, 4096) {
        $lines += ($buffer =~ tr/\n//);
    }
    close FILE;

# Count
my $count = 1;

# LOOP #######################################################################
while ( <IN> ) {
	my $ip;
        my $ip1;
        my $ip2;
        my $name;
	my $desc;
	
	# Status Message
	#print "### Reading line number ".$count." of ".$lines." ###\n\n";
	
	# Split Columns
	my @resu = split(/$separator/, $_);
	
        # MODE SELECT
        if ( ! @iptar ) {
        # SINGLE IP MODE #####################################################
                # COL MODE IP
                if ( $iploc[0] eq "col" ) {
                        
                        # Split the line
                        my $colpos = $iploc[1]-1;
                        $ip = $resu[$colpos];
                        
                        # Check the IP
                        # existant
                        if ( $ips{$ip} ) {
                                $ips{$ip}{count}++; 
                        # non-existant
                        } else {
                                # Get Geo Location
                               my ($latitude,$longitude ) = getLATLONlocal($ip);
                               if ( ! $latitude || ! $longitude ) { next; }
                               
                               # Increment
                               $ips{$ip}{count} = 1; 
                               
                               #print "\nIP = ".$ip." / LON ".$longitude." LAT ".$latitude."\n";
                               $ips{$ip}{latitude} = $latitude;
                               $ips{$ip}{longitude} = $longitude;
                               
                               # Setting the eventcount = 0
                               $ips{$ip}{eventcount} = 0;                       
                               
                        }          
                        
                        # Check count column if defined
                        if ( @count ) {
                                my $countpos = $count[1];
                                $ips{$ip}{count} = $resu[$countpos-1];
                        }
                                
                # REGEX MODE IP      
                } else {
                        if ( $_ =~ /$iploc[1]/ ) {
                                
                                # Found in Regex
                                $ip = $1;
                                
                                # Check the IP
                                # existant
                                if ( $ips{$ip} ) {
                                        $ips{$ip}{count}++; 
                                # non-existant
                                } else {
                                        # Get Geo Location
                                       my ($latitude,$longitude ) = getLATLONlocal($ip);
                                       if ( ! $latitude || ! $longitude ) { next; }
                                       
                                       # Increment
                                       $ips{$ip}{count} = 1;                                
                                       
                                       #print "\nIP = ".$ip." / LON ".$longitude." LAT ".$latitude."\n";
                                       $ips{$ip}{latitude} = $latitude;
                                       $ips{$ip}{longitude} = $longitude;
                                       
                                       # Setting the eventcount = 0
                                       $ips{$ip}{eventcount} = 0;
                                       
                                } 
                                
                                # Check count column if defined
                                if ( @count ) {
                                        my $countpos = $count[1];
                                        $ips{$ip}{count} = $resu[$countpos-1];
                                }                                        
                                
                        }               
                }
        } else {
        #### MULTI IP MODE ##########################################
                 # COL MODE IP SOURCE
                if ( $iploc[0] eq "col" ) {
                        
                        # Split the line
                        my $colpos = $iploc[1]-1;
                        $ip1 = $resu[$colpos];
                                                        
                # REGEX MODE IP      
                } else {
                        if ( $_ =~ /$iploc[1]/ ) {
                                
                                # Found in Regex
                                $ip1 = $1;                                      
                                
                        }               
                }
                # COL MODE IP
                if ( $iptar[0] eq "col" ) {
                        
                        # Split the line
                        my $colpos = $iptar[1]-1;
                        $ip2 = $resu[$colpos];
                                                        
                # REGEX MODE IP      
                } else {
                        if ( $_ =~ /$iptar[1]/ ) {
                                
                                # Found in Regex
                                $ip2 = $1;                                      
                                
                        }               
                }
                
                print "ip1 = $ip1 - ip2 = $ip2\n";
                
                # Check the IP
                $ips{$ip1}++;
                $ips{$ip2}++;
                # existant
                if ( $ipcons{$ip1.":".$ip2} ) {
                        $ipcons{$ip1.":".$ip2}{count}++; 
                # non-existant
                } else {
                        # Get Geo Location Source
                       my ($latitude_s,$longitude_s ) = getLATLONlocal($ip1);
                       if ( ! $latitude_s || ! $longitude_s ) { next; }
                                             
                        # Get Geo Location Target
                       my ($latitude_t,$longitude_t ) = getLATLONlocal($ip2);
                       if ( ! $latitude_t || ! $longitude_t ) { next; }
                       
                       $ipcons{$ip1.":".$ip2}{s}{lon} = $longitude_s;
                       $ipcons{$ip1.":".$ip2}{s}{lat} = $latitude_s;
                       $ipcons{$ip1.":".$ip2}{t}{lon} = $longitude_t;
                       $ipcons{$ip1.":".$ip2}{t}{lat} = $latitude_t;
                       
                       # Set 1
                       $ipcons{$ip1.":".$ip2}{count} = 1; 
                                              
                       # Setting the eventcount = 0
                       $ipcons{$ip1.":".$ip2}{eventcount} = 0;                       
                       
                }          
                
                # Check count column if defined
                if ( @count ) {
                        my $countpos = $count[1];
                        $ipcons{$ip1.":".$ip2}{count} = $resu[$countpos-1];
                }
                
        }

        #######################################################################
        # SINGLE
        my $ec;
        if ( ! @iptar ) {
                # Events
                $ips{$ip}{eventcount}++;
                $ec = $ips{$ip}{eventcount};
        # MULTI
        } else {
                 # Events
                $ipcons{$ip1.":".$ip2}{eventcount}++;
                $ec = $ipcons{$ip1.":".$ip2}{eventcount};                 
        }
        
        #######################################################################
        # SINGLE
        if ( ! @iptar ) {
                # COL MODE NAME
                if ( $name[0] eq "col" ) {
                        
                        my $colpos = $name[1]-1;
                        $name = $resu[$colpos];
                                                
                        $ips{$ip}{events}{"$ec"}{name} = encode_entities($name);
                
                # REGEX MODE NAME     
                } else {
                        $name = "-";
                        if ( $_ =~ /$name[1]/ ) {  
                                $name = $1;
                        }
                       
                        $ips{$ip}{events}{"$ec"}{name} = encode_entities($name);
                }
        } else {
                 # COL MODE NAME
                if ( $name[0] eq "col" ) {
                        
                        my $colpos = $name[1]-1;
                        $name = $resu[$colpos];
                                                
                        $ipcons{$ip1.":".$ip2}{events}{"$ec"}{name} = encode_entities($name);
                
                # REGEX MODE NAME     
                } else {
                        $name = "-";
                        if ( $_ =~ /$name[1]/ ) {  
                                $name = $1;
                        }
                        
                        $ipcons{$ip1.":".$ip2}{events}{"$ec"}{name} = encode_entities($name);
                }               
        }
        
        #######################################################################
        # SINGLE
        if ( ! @iptar ) {
                # COL MODE DESC
                if ( $desc[0] eq "col" ) {
                        
                        my $colpos = $desc[1]-1;
                        $desc = $resu[$colpos];
                                                
                        $ips{$ip}{events}{"$ec"}{description} = encode_entities($desc);
                
                # REGEX MODE DESC    
                } else {
                        $desc = "-";                
                        if ( $_ =~ /$desc[1]/ ) {
                                $desc = $1;      
                        }
                        
                        $ips{$ip}{events}{"$ec"}{description} = encode_entities($desc);                
                        
                }
        # MULTI
        } else {
                # COL MODE DESC
                if ( $desc[0] eq "col" ) {
                        
                        my $colpos = $desc[1]-1;
                        $desc = $resu[$colpos];
                                                
                        $ipcons{$ip1.":".$ip2}{events}{"$ec"}{description} = encode_entities($desc);
                
                # REGEX MODE DESC    
                } else {
                        $desc = "-";                
                        if ( $_ =~ /$desc[1]/ ) {
                                $desc = $1;      
                        }
                        
                        $ipcons{$ip1.":".$ip2}{events}{"$ec"}{description} = encode_entities($desc);                
                        
                }                
        }
        
        #######################################################################       
}

# Evaluate the one that appeared most
my $highestcount = 0;
my $highestcount_ips = 0;
# SINGLE
if ( ! @iptar ) {
        foreach my $host ( keys %ips ) {
                if ( $ips{$host}{count} > $highestcount ) {
                        $highestcount = $ips{$host}{count};
                }
        }
        print "\nHighestCount = ".$highestcount."\n";
# MULTI
} else {
        foreach my $con ( keys %ipcons ) {
                if ( $ipcons{$con}{count} > $highestcount ) {
                        $highestcount = $ipcons{$con}{count};
                }
        }
        foreach my $ip( keys %ips ) {
                if ( $ips{$ip} > $highestcount_ips ) {
                        $highestcount_ips = $ips{$ip};
                }
        }
        print "\nHighestCount = ".$highestcount."\n";
        print "\nHighestCount_ips = ".$highestcount_ips."\n";
}

# Generating the KML File
my $kml_header = '<?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
        <Style id="warning1">
		<IconStyle>
			<scale>1</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/blu-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="warning2">
		<IconStyle>
			<scale>2</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/blu-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="warning3">
		<IconStyle>
			<scale>3</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/blu-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="warning4">
		<IconStyle>
			<scale>4</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/blu-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="warning5">
		<IconStyle>
			<scale>5</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/blu-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="target1">
		<IconStyle>
			<scale>1</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/ylw-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="target2">
		<IconStyle>
			<scale>2</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/ylw-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="target3">
		<IconStyle>
			<scale>3</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/ylw-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="target4">
		<IconStyle>
			<scale>4</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/ylw-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="target5">
		<IconStyle>
			<scale>5</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/ylw-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="earthquake1">
		<IconStyle>
			<scale>1</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/pink-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="earthquake2">
		<IconStyle>
			<scale>2</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/pink-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="earthquake3">
		<IconStyle>
			<scale>3</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/pink-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="earthquake4">
		<IconStyle>
			<scale>4</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/pink-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="earthquake5">
		<IconStyle>
			<scale>5</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/pink-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="caution1">
		<IconStyle>
			<scale>1</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/red-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="caution2">
		<IconStyle>
			<scale>2</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/red-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="caution3">
		<IconStyle>
			<scale>3</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/red-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="caution4">
		<IconStyle>
			<scale>4</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/red-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>
        <Style id="caution5">
		<IconStyle>
			<scale>5</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/paddle/red-circle.png</href>
			</Icon>
			<hotSpot x="32" y="1" xunits="pixels" yunits="pixels"/>
		</IconStyle>
	</Style>    
        <Style id="lines1">
		<IconStyle>
			<scale>1.3</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>
			</Icon>
			<hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
		</IconStyle>
		<LineStyle>
			<color>ff000000</color>
			<width>1</width>
		</LineStyle>
	</Style>
        <Style id="lines2">
		<IconStyle>
			<scale>1.1</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>
			</Icon>
			<hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
		</IconStyle>
		<LineStyle>
			<color>ff000033</color>
			<width>3</width>
		</LineStyle>
	</Style>
        <Style id="lines3">
		<IconStyle>
			<scale>1.1</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>
			</Icon>
			<hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
		</IconStyle>
		<LineStyle>
			<color>ff000066</color>
			<width>9</width>
		</LineStyle>
	</Style>
        <Style id="lines4">
		<IconStyle>
			<scale>1.1</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>
			</Icon>
			<hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
		</IconStyle>
		<LineStyle>
			<color>ff000099</color>
			<width>16</width>
		</LineStyle>
	</Style>
        <Style id="lines5">
		<IconStyle>
			<scale>1.1</scale>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>
			</Icon>
			<hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
		</IconStyle>
		<LineStyle>
			<color>ff0000CC</color>
			<width>25</width>
		</LineStyle>
	</Style>
	<StyleMap id="line1">
		<Pair>
			<key>normal</key>
			<styleUrl>lines1</styleUrl>
		</Pair>
		<Pair>
			<key>highlight</key>
			<styleUrl>lines1</styleUrl>
		</Pair>
	</StyleMap>
        	<StyleMap id="line2">
		<Pair>
			<key>normal</key>
			<styleUrl>lines2</styleUrl>
		</Pair>
		<Pair>
			<key>highlight</key>
			<styleUrl>lines2</styleUrl>
		</Pair>
	</StyleMap>
        	<StyleMap id="line3">
		<Pair>
			<key>normal</key>
			<styleUrl>lines3</styleUrl>
		</Pair>
		<Pair>
			<key>highlight</key>
			<styleUrl>lines3</styleUrl>
		</Pair>
	</StyleMap>
        	<StyleMap id="line4">
		<Pair>
			<key>normal</key>
			<styleUrl>lines4</styleUrl>
		</Pair>
		<Pair>
			<key>highlight</key>
			<styleUrl>lines4</styleUrl>
		</Pair>
	</StyleMap>
        	<StyleMap id="line5">
		<Pair>
			<key>normal</key>
			<styleUrl>lines5</styleUrl>
		</Pair>
		<Pair>
			<key>highlight</key>
			<styleUrl>lines5</styleUrl>
		</Pair>
	</StyleMap>
        ';
                
my $kml_footer =  '</Document></kml>';

print OUT $kml_header;

my $c = 1;

# LOOP #######################################################################
# SINGLE
if ( ! @iptar ) {
        foreach my $ip ( sort keys %ips ) {
                
                my $placemark;
                
                # Calculate size
                my $num = ceil($ips{$ip}{count} / $highestcount * $maxsym);
                
                # Skip if empty values
                if ( ! $ips{$ip}{longitude} && ! $ips{$ip}{latitude} ) { next; }
                
                # Skip if there are more than 10000 hits
                if ($ips{$ip}{count} >= 10000) {
                        next;
                }
                
                
                # Multi-Type or Single-Type
                my $type = "warning";
                if ($ips{$ip}{count} > 100000) {
                        $type = "caution";
                } elsif ( ($ips{$ip}{count} > 10000) && ($ips{$ip}{count} < 100000) ) {
                        $type = "earthquake";
                } elsif ( ($ips{$ip}{count} > 1000) && ($ips{$ip}{count} < 10000)) {
                        $type = "target";
                } else {
                        $type = "warning";
                }
                
                # Loop Events
                for my $evt ( sort keys %{ $ips{$ip}{events} } ) {
                
                        print "NODE:".$c." / IP:".$ip." / EVT:".$evt." / NAME:".substr($ips{$ip}{events}{$evt}{name},0,20)." / DESC:".substr($ips{$ip}{events}{$evt}{description},0,20)."... / LON:".$ips{$ip}{longitude}." / LAT:".$ips{$ip}{latitude}."\n"; 
                        
                        # $placemark = "\n<Placemark>\n<name>".$ips{$ip}{events}{$evt}{name}."</name>\n<description>".$ips{$ip}{events}{$evt}{description}."</description>\n<Point>\n<coordinates>".$ips{$ip}{longitude}.",".$ips{$ip}{latitude}."</coordinates>\n</Point>\n";
                        # Let's modify this a bit so it adds extended attributes for IP Address and Request Count
                        $placemark = "\n<Placemark>\n";
                        # $placemark .= "<name>".$ip."</name>\n"
                        # $placemark .= "<description>Requests: ".$ips{$ip}{count}."</description>\n"
                        $placemark .= "<ExtendedData>\n";
                        $placemark .= "<Data name=\"IPAddress\">\n";
                        $placemark .= "  <displayName>IP Address</displayName>\n";
                        $placemark .= "  <value>".$ip."</value>\n";
                        $placemark .= "</Data>\n";
                        $placemark .= "<Data name=\"RequestCount\">\n";
                        $placemark .= "  <displayName>Request Count</displayName>\n";
                        $placemark .= "  <value>".$ips{$ip}{count}."</value>\n";
                        $placemark .= "</Data>\n";
                        $placemark .= "</ExtendedData>\n";
                        $placemark .=" <Point>\n<coordinates>".$ips{$ip}{longitude}.",".$ips{$ip}{latitude}."</coordinates>\n</Point>\n";
                        
                        $placemark .= "<styleUrl>#$type$num</styleUrl>\n";
                        $placemark .= "</Placemark>\n";
                        
                        print OUT $placemark;
                        
                }
                
                $c++;
                
        }
# MULTI
} else {
        foreach my $con ( sort keys %ipcons ) {
                
                my $placemark_s;
                my $placemark_t;
                my $placemark_c;
                
                # Calculate size
                my $num_con = ceil($ipcons{$con}{count} / $highestcount * $maxsym);
                
                # Skip if empty values
                if ( ! $ipcons{$con}{s}{lon} || ! $ipcons{$con}{s}{lat} || ! $ipcons{$con}{t}{lon} || ! $ipcons{$con}{t}{lat} ) { next; }
                
                # The ips
                my $type_s = "warning";
                my $type_t = "target";
                my($ip1,$ip2) = split(":",$con);
                if ( $ips{$ip1} > 1 ) {
                        $type_s = "earthquake";
                }
                
                my $num_s = ceil($ips{$ip1} / $highestcount_ips * $maxsym);
                my $num_t = ceil($ips{$ip2} / $highestcount_ips * $maxsym);
                
                # Loop Events
                for my $evt ( sort keys %{ $ipcons{$con}{events} } ) {
                
                        #print "NODE:".$c." / IP:".$ip." / EVT:".$evt." / NAME:".substr($ips{$ip}{events}{$evt}{name},0,20)." / DESC:".substr($ips{$ip}{events}{$evt}{description},0,20)."... / LON:".$ips{$ip}{longitude}." / LAT:".$ips{$ip}{latitude}."\n"; 
                        
                        # SOURCE        
                        $placemark_s = "\n<Placemark>\n<name>".$ipcons{$con}{events}{$evt}{name}."</name>\n<description>".$ipcons{$con}{events}{$evt}{description}."</description>\n<Point>\n<coordinates>".$ipcons{$con}{s}{lon}.",".$ipcons{$con}{s}{lat}."</coordinates>\n</Point>\n";
                        $placemark_s .= "<styleUrl>#$type_s$num_s</styleUrl>\n";
                        $placemark_s .= "</Placemark>\n";
                        
                        # TARGET                        
                        $placemark_t = "\n<Placemark>\n<name>Target of Attack: ".$ip2."</name>\n<description>Target of attack: ".$ipcons{$con}{events}{$evt}{description}."</description>\n<Point>\n<coordinates>".$ipcons{$con}{t}{lon}.",".$ipcons{$con}{t}{lat}."</coordinates>\n</Point>\n";
                        $placemark_t .= "<styleUrl>#$type_t$num_t</styleUrl>\n";
                        $placemark_t .= "</Placemark>\n";
                        
                        # CONNECTION
                        $placemark_c = "\n<Placemark><name>".$ip1." -> ".$ip2."</name><styleUrl>line".$num_con."</styleUrl><LineString><tessellate>1</tessellate><coordinates> ".$ipcons{$con}{s}{lon}.",".$ipcons{$con}{s}{lat}.",0 ".$ipcons{$con}{t}{lon}.",".$ipcons{$con}{t}{lat}.",0 </coordinates></LineString></Placemark>\n";
                        
                        print OUT $placemark_s;
                        print OUT $placemark_t;
                        print OUT $placemark_c;
                        
                }
                
                $c++;
                
        }          
}

print OUT $kml_footer;

close OUT;
close IN;

### SUBROUTINES ###############################################

# IP Lookup
sub getLATLONlocal {
        
    my ($ipadr) = @_;
        
    my @r = $gi->get_city_record($ipadr);

    return ($r[6], $r[7]);
        
}

