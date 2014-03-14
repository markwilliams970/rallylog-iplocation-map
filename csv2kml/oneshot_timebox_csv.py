#!/usr/bin/env python
#
# Copyright 2011-2014 Splunk, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"): you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

"""A command line utility for executing oneshot Splunk searches."""

from pprint import pprint
from datetime import date, timedelta
import socket
import sys, os
import datetime
import time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from splunklib.client import connect
import splunklib.results as results

try:
    import utils
except ImportError:
    raise Exception("Add the SDK repository to your PYTHONPATH to run the examples "
                    "(e.g., export PYTHONPATH=~/splunk-sdk-python.")

def pretty(response):
    reader = results.ResultsReader(response)
    for result in reader:
        if isinstance(result, dict):
            pprint(result)

def main():
    usage = "usage: oneshot.py <search>"
    opts = utils.parse(sys.argv[1:], {}, ".splunkrc", usage=usage)
    if len(opts.args) == 0:
        utils.error("Search expression required", 2)
        
    datetime_format_string = "%Y-%m-%dT%H:%M:%S"
    
    today_string = datetime.datetime.now().strftime(datetime_format_string)
    week_ago_date = date.today()-timedelta(days=7)
    week_ago_string = week_ago_date.strftime(datetime_format_string)
    sort_key = "count"
    sort_mode = "num"
    sort_dir = "desc"
    
    output_mode = "csv"
    max_records =  10000
    
    sub_id = opts.args[0]
    
    # Splunk search string
    search_string = "search sourcetype=alm-spans requestSpan.stack=prod subscriptionId=%s | stats count by javaRequestSpan.remoteHost" % sub_id
     
    service = connect(**opts.kwargs)
    socket.setdefaulttimeout(None)
    kwargs_oneshot = {"earliest_time": week_ago_string,
                      "latest_time": today_string,
                      "output_mode": output_mode,
                      "sort_key": sort_key,
                      "sort_mode": sort_mode,
                      "sort_dir": sort_dir,
                      "count": max_records
                      }
    response = service.jobs.oneshot(search_string, **kwargs_oneshot)
    
    # Print the raw results (they're CSV-formatted already anyway so we don't need to use a reader)
    print response

if __name__ == "__main__":
    main()
