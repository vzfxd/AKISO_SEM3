#!/bin/bash

function avg {
	sum=0
	arr=("$@")
	for i in "${arr[@]}"
	do
		sum=$(($sum+$i))
	done
	avg=$(echo "$sum/${#arr[@]}" | bc)
	echo "$avg"
}

function chart_generator {

}


bytes_sent=()
bytes_recieved=()

download_speed_arr=()
upload_speed_arr=()

avg_download_speed_arr=()
avg_upload_speed_arr=()

counter=0

while true
do

	bytes_sent+=($(cat /proc/net/dev | grep wlo1: | awk '{print $10}'))
	bytes_recieved+=($(cat /proc/net/dev | grep wlo1: | awk '{print $2}'))
	bytes_sent_avg+=($(avg "${bytes_sent[@]}"))
	bytes_recieved_avg+=($(avg "${bytes_recieved[@]}"))

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

	if [ ${#bytes_sent[@]} -gt 1 ] && [ ${#bytes_recieved[@]} -gt 1 ]
	then
		upload_speed=$(( ${bytes_sent[$counter]} - ${bytes_sent[$(($counter-1))]} ))
		download_speed=$(( ${bytes_recieved[$counter]} - ${bytes_recieved[$(($counter-1))]} ))

		download_speed_arr+=($download_speed)
		upload_speed_arr+=($upload_speed)

		avg_download_speed=$(avg "${download_speed_arr[@]}")
		avg_upload_speed=$(avg "${upload_speed_arr[@]}")

		avg_download_speed_arr+=($avg_download_speed)
		avg_upload_speed_arr+=($avg_upload_speed)

	fi

	echo "download speed: ${download_speed}   ||  upload speed: ${upload_speed}"
	echo "average download: ${avg_download_speed}  ||  average upload: ${avg_upload_speed}"

	counter=$((${counter}+1))
	sleep 1
	clear
done

