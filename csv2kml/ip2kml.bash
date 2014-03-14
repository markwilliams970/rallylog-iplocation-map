#!/bin/bash

# Turn on debugging if user specified "-x" or "-xtrace" as arg 1.
if [[ "-x" == "${1}" || "-xtrace" == "${1}" ]]; then shift; PS4='$LINENO: '; set -x; fi

# Report Subscription Variables
CUSTOMER_NAME="Awesome Customer"
SUBSCRIPTION_NAME="Customer Rally Subscription"
SUBSCRIPTION_ID="100"

# Google Maps API Key
GMAPS_API_KEY="crEhaMa-cHuBepr7stEP-Bru89bechaFrep7UTRA"

# Locations of language runtime setup files
# Python: virtual-env
export VIRTUAL_ENV="/home/username/virtualenv-1.10.1/my-python/bin/activate"
export PYTHONPATH="/home/username/Documents/splunk-sdk-python-1.2.1/"

# Perl: perlbrew
export PERLBREW="/home/username/perl5/perlbrew/etc/bashrc"

# Setup language runtimes
source ${VIRTUAL_ENV}
source ${PERLBREW}

# Date parameters
REPORT_DATE=`date +"%Y%m%d"`
YEAR=`date +"%Y"`
END_DAY=`date +"%d"`
START_DAY=`expr $END_DAY - 7`
MONTH_STRING=`date +"%B"`
REPORT_RANGE="${MONTH_STRING} ${START_DAY}-${END_DAY}, ${YEAR}"

# Output CSV File
CSV_FILE="${REPORT_DATE}_count_by_ipaddress.csv"

# Run python script to poll IP/Count information from splunk
echo "Running python to query Splunk using the following Search:"
echo ${SEARCH_STRING}
echo "This could take some time..."
python ./oneshot_timebox_csv.py ${SUBSCRIPTION_ID} > ${CSV_FILE}

# Template values
TEMPLATE_DATE="YYYYMMDD"

# Template HTML file location
TEMPLATE_HTML="template.html"

TEMPLATE_DATE_RANGE="Month Day PP - QQ, YYYY"
TEMPLATE_SUBSCRIPTION_ID="SUBSCRIPTION_ID_VALUE"
TEMPLATE_SUBSCRIPTION_NAME="SUBSCRIPTION_NAME"
TEMPLATE_CUSTOMER_NAME="CUSTOMER_NAME"
TEMPLATE_GMAPS_API_KEY="GMAPS_API_KEY"
TEMPLATE_FQ_SERVER_URL="FQ_SERVER_URL"

# Output Parameters

# Fully-qualified server URL where report will reside
FQ_SERVER_URL="https:\/\location.f4tech.com\/username\/reportdir\/"

# File outputs
FILE_PREFIX=${REPORT_DATE}
KML_OUT_MAJOR="${FILE_PREFIX}_major.kml"
KML_OUT_MINOR="${FILE_PREFIX}_minor.kml"
PROCESSED_CSV="${FILE_PREFIX}_noquotes.csv"
CSV_HTML="${FILE_PREFIX}_table.html"
OUTPUT_HTML="${FILE_PREFIX}_geoIPReport.html"
OUTPUT_DIRECTORY_HTML="../html"
OUTPUT_DIRECTORY_KML="${OUTPUT_DIRECTORY_HTML}/kml"

# SCP Parameters
SCP_HOST="server.company.com"
SCP_USER_ID="username"
SCP_REMOTE_DIRECTORY_HTML="/home/username/html_dir/report_dir"
SCP_REMOTE_DIRECTORY_KML="${SCP_REMOTE_DIRECTORY_HTML}/kml"

SCP_TARGET_HTML="${SCP_REMOTE_DIRECTORY_HTML}/geoIPReport.html"
SCP_TARGET_KML_MAJOR="${SCP_REMOTE_DIRECTORY_KML}/requests_major.kml"
SCP_TARGET_KML_MINOR="${SCP_REMOTE_DIRECTORY_KML}/requests_minor.kml"

echo "CSV Input File: ${CSV_FILE}"
echo "Pre-processing CSV..."

# Remove empty lines and un-needed double-quotes, skip first row
cat ${CSV_FILE} | sed -e 's/"//g' -e '/^\s*$/d' | tail -n +2 > ${PROCESSED_CSV}

# Run GeoIP Perl Script
echo "Processing IP Address data to KML..."

perl ip2kml_major.pl -i ${PROCESSED_CSV} -o ${KML_OUT_MAJOR} -s col:1 -c col:2 -d "\s" -n "\s" -e sep:, # > /dev/null 2>&1
perl ip2kml_minor.pl -i ${PROCESSED_CSV} -o ${KML_OUT_MINOR} -s col:1 -c col:2 -d "\s" -n "\s" -e sep:, # > /dev/null 2>&1

echo "KML Output File: ${KML_OUT}"

echo "Processing summary HTML Table..."

cat ${PROCESSED_CSV} | \
    sort --field-separator="," --key=2,1 -n -r | \
    awk -F, -f csv2html.awk > ${CSV_HTML}

# Convert HTML Template using current values
echo "Preparing Report HTML Map...."

echo "s/${TEMPLATE_CUSTOMER_NAME}/${CUSTOMER_NAME}/g"
echo "s/${TEMPLATE_DATE_RANGE}/${REPORT_RANGE}/g"
echo "s/${TEMPLATE_SUBSCRIPTION_ID}/${SUBSCRIPTION_ID}/g"
echo "s/${TEMPLATE_SUBSCRIPTION_NAME}/${SUBSCRIPTION_NAME}/g"
echo "s/${TEMPLATE_DATE}/${REPORT_DATE}/g"
echo "s/${TEMPLATE_GMAPS_API_KEY}/${GMAPS_API_KEY}/g"
echo "s/${TEMPLATE_FQ_SERVER_URL}/${FQ_SERVER_URL}/g"

cat ${TEMPLATE_HTML} | sed \
	-e "s/${TEMPLATE_CUSTOMER_NAME}/${CUSTOMER_NAME}/g" \
	-e "s/${TEMPLATE_DATE_RANGE}/${REPORT_RANGE}/g"   \
    -e "s/${TEMPLATE_SUBSCRIPTION_ID}/${SUBSCRIPTION_ID}/g" \
    -e "s/${TEMPLATE_SUBSCRIPTION_NAME}/${SUBSCRIPTION_NAME}/g" \
    -e "s/${TEMPLATE_DATE}/${REPORT_DATE}/g" \
    -e "s/${TEMPLATE_GMAPS_API_KEY}/${GMAPS_API_KEY}/g" \
	-e "s/${TEMPLATE_FQ_SERVER_URL}/${FQ_SERVER_URL}/g" > ${OUTPUT_HTML}

# Move report to final location
FINAL_HTML="${OUTPUT_DIRECTORY_HTML}/geoIPReport.html"
FINAL_KML_MAJOR="${OUTPUT_DIRECTORY_KML}/requests_major.kml"
FINAL_KML_MINOR="${OUTPUT_DIRECTORY_KML}/requests_minor.kml"

echo "Moving files to local output locations"
mv ${OUTPUT_HTML} ${FINAL_HTML}
mv ${KML_OUT_MAJOR} ${FINAL_KML_MAJOR}
mv ${KML_OUT_MINOR} ${FINAL_KML_MINOR}

echo "Copying files to remote webserver"
scp ${FINAL_HTML} "${SCP_USER_ID}@${SCP_HOST}:${SCP_TARGET_HTML}"
scp ${FINAL_KML_MAJOR} "${SCP_USER_ID}@${SCP_HOST}:${SCP_TARGET_KML_MAJOR}"
scp ${FINAL_KML_MINOR} "${SCP_USER_ID}@${SCP_HOST}:${SCP_TARGET_KML_MINOR}"

# Cleanup
echo "Cleaning up temp files..."
rm ${CSV_FILE}
rm ${PROCESSED_CSV}
rm ${CSV_HTML}

echo "Report done!"