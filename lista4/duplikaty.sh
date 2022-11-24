#!/bin/bash

result=$(find $1 -type f -printf "%s\t%p\n" | sort -n -r | sed 's/^[^\/]*//' | xargs -d '\n' sha256sum | uniq -D --check-char=64)
echo "${result}"
