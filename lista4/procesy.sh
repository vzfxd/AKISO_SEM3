#!/bin/bash

result="PID PPID PGID SID COMM STATE TTY RSS FILE_COUNT\n"

for process in /proc/[0-9]*
do
	stats=($(cat ${process}/stat))
	result="${result}${stats[0]} ${stats[3]} ${stats[4]} ${stats[5]} ${stats[1]} ${stats[2]} ${stats[6]} ${stats[23]} $(sudo ls ${process}/fd/ | wc -l)\n"
done
result=$(printf "${result}" | column -t)
printf "${result}\n"
