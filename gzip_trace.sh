#!/bin/bash
for i in `find . | grep .pcap | grep -v .gz`; do gzip $i ; done &
