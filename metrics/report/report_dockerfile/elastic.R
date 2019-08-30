#!/usr/bin/env Rscript
# Copyright (c) 2018-2019 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

# Example of doing a double-search request from elasticsearch -
#  first, extract the most recent entry from a dataset so we can find
#  the unique set identifier (date stamp in this case), and then send
#  another request to extract the complete dataset with that identifier.
#
# In this example, we are trying to work out the most recent 'pods per gigabyte'
# value by pulling the most recent result (sort by date), and then finding all
# its brethren, and then doing the math between the first (0 pods) and last
# (largest n'th pod) memory values.

library('elastic')
suppressMessages(library(jsonlite))			# to load the data.

# local test ELK setup
elastic_host="192.168.0.111"
elastic_port="9200"
elastic_transport="http"
elastic_index="logtest"

# let's try to get data for the two runtimes
runtimes=c("kata-qemu", "default")

# Generate our elasticsearch connection point
el=connect(elastic_host, elastic_port, elastic_transport, path="")


# Template for extracting the last result
last_scaling_entry_template='{
  "size": 1,
  "sort": [
    { "date.Date" : { "order" : "desc"}}
  ],
  "query": {
    "bool": {
      "must": [
	{ "match_phrase": {
          "test.testname.keyword": {
		  "query" : "k8s scaling"
		}
        } },
	{ "match_phrase": {
          "test.runtime.keyword": {
		  "query" : "@runtime@"
		}
        } }
       ]
     }
  },
  "_source": [
    "date.Date",
    "test.runtime",
    "k8s-scaling.BootResults.launch_time.Result",
    "k8s-scaling.BootResults.n_pods.Result"
    ]
}'


# for each of our runtimes...
for (runtime in runtimes) {

	cat("processing runtime: ", runtime, "\n")

	# massage the template query to match our runtime
	q=gsub("@runtime@", runtime, last_scaling_entry_template)
	# and search....
	results=Search(el,
		index=elastic_index,
		body=q
		)

	# If we got no results, report that, and carry on
	if ( length(results$hits$hits) == 0 ) {
		cat("Failed to get any hits for runtime [", runtime, "]\n")
		next
	}
	
	# We just want the most recent result
	result=results$hits$hits[[1]]$`_source`
	
	cat("Got initial hit of: ", result$date$Date, "\n")
	
	# and we use the data stamp as the unique dataset identifier
	date_stamp=result$date$Date
	
	# Template query to pull a whole dataset that matches the datestamp
	last_scaling_series_template='{
	  "size": 100,
	  "sort": [
	    { "date.Date" : { "order" : "desc"}}
	  ],
	  "query": {
	        "term": {
	          "date.Date": "@date_stamp@"
	        }
	  },
	  "_source": [
	    "date.Date",
	    "test.runtime",
	    "k8s-scaling.BootResults.launch_time.Result",
	    "k8s-scaling.BootResults.n_pods.Result",
	    "k8s-scaling.BootResults.node_util"
	    ]
	}'
	
	# And slide our date stamp into the query
	q2=gsub("@date_stamp@", date_stamp, last_scaling_series_template)
	
	# and do the search...
	results2=Search(el,
		index=elastic_index,
		body=q2
		)
	
	cat("Got total hits: ", length(results2$hits$hits), "\n")

	# And now 'all' we have to do is convert that list based data down to some
	# data frames and tibbles, extract the 0't and n'th entry (maybe using some which() magic),
	# and do the math...
	#
	# which I may have done, if my brain had not apparently turned to cheese.....
	# what we need to do is very similar to the lapply/rbind work we do in the tidy_scaling.R file
	# - but, subtly different.... something like....
	hits=results2$hits$hits
	items=do.call("rbind", lapply(hits, "["))
}
