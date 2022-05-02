#!/bin/bash

log stream --info | /usr/local/bin/socat -dddd STDIN TCP4:{{ elasticsearch_server }}:{{ elasticsearch_port }},interval=4,reuseaddr,forever
