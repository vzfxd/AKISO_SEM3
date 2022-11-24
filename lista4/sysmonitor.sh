#!/bin/bash

net

while true
do

	total_uptime=$(cat /proc/uptime | sed 's/\s.*$//')
	uptime_day=$(echo "${total_uptime}/86400" | bc)
	uptime_hr=$(echo "${total_uptime}/3600 % 24" | bc)
	uptime_min=$(echo "${total_uptime}/60 % 60" | bc)
	uptime_sec=$(echo "${total_uptime} % 60" | bc)

	battery=$(echo "100 * $(cat /sys/class/power_supply/BAT1/energy_now) / $(cat /sys/class/power_supply/BAT1/energy_full)" | bc)
	memory=$(cat /proc/meminfo | grep -i -w active: | sed 's/.*://' | sed 's/ //g')
	load=$(cat /proc/loadavg | cut -d ' ' -f -3)

	cpu_usage=()
	cpu_freq=()

	for i in {0..7}
	do
		cpu_usage+=($(grep cpu$i /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}'))
		cpu_freq+=($(sudo cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_cur_freq))
	done

	echo "${cpu_usage[*]}"

	sleep 1
	clear
done
