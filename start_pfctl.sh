#!/bin/bash

# Wait 30 seconds
sleep 30

# Start pf
pfctl -e -f /etc/pf.conf
