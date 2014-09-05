#!/bin/bash
find ~/ -user $USER -type f -printf "%s\n" | awk '{t+=$1}END{print t}'
