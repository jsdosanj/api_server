#!/bin/bash

firewall-cmd  --permanent --add-port 8000/tcp     # plain-HTTP version of service
firewall-cmd  --permanent --add-port 2022/tcp     # encrypted debug/inspection manhole
firewall-cmd  --permanent --add-forward-port=port=443:proto=tcp:toport=4433
firewall-cmd  --reload
