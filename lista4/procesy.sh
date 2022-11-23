#!/bin/bash

result="PID PPID PGID SID COMM STATE TTY RSS FILE_COUNT\n"

for process in /proc/[0-9]*
do
	stats=($(cat ${process}/stat | sed 's/([^*]*)//g' ))
	comm=$(cat ${process}/stat | sed 's/.* (\(.*\)) .*/\1/g' | sed 's/ /-/g')
	result="${result}${stats[0]} ${stats[2]} ${stats[3]} ${stats[4]} ${comm} ${stats[1]} ${stats[5]} ${stats[22]} $(sudo ls ${process}/fd/ | wc -l)\n"
done
result=$(printf "${result}" | column -t)
printf "${result}\n"
