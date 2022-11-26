#!/bin/bash

bytes_sent=()
bytes_recieved=()

download_speed_arr=()
upload_speed_arr=()

avg_download_speed_arr=()
avg_upload_speed_arr=()

cpu=()
core_num=$(($(cat /proc/stat | grep cpu | wc -l)-1))


counter=0

function avg {
	local sum=0
	local arr=("$@")
	for i in "${arr[@]}"
	do
		sum=$(($sum+$i))
	done
	local avg=$(echo "$sum/${#arr[@]}" | bc)
	echo "$avg"
}

function chart_generator {
	if [ $(( ${#download_speed_arr[@]}-5 )) -lt 0 ]
	then
		local slice=0
	else
		local slice=$(( ${#download_speed_arr[@]}-5 ))
	fi

	local dow_jump=50000
	local up_jump=1000

	local d_speed=(${download_speed_arr[@]:$slice})
	local u_speed=(${upload_speed_arr[@]:$slice})
	local avg_d_speed=(${avg_download_speed_arr[@]:$slice})
	local avg_u_speed=(${avg_upload_speed_arr[@]:$slice})

	tput setaf 1
	printf "\nDOWNLOAD SPEED HISTORY\n"
	for i in "${!d_speed[@]}"
	do
		printf "█%.0s" $(seq 0 $dow_jump ${d_speed[$i]}) ; local bytes=$(bytes_convert "${d_speed[$i]}") ; printf " ${bytes}\n"
	done

	tput setaf 5
	printf "\nAVERAGE DOWNLOAD SPEED HISTORY\n"
	for i in "${!avg_d_speed[@]}"
	do
		printf "█%.0s" $(seq 0 $dow_jump ${avg_d_speed[$i]}) ; local bytes=$(bytes_convert "${avg_d_speed[$i]}") ; printf " ${bytes}\n"
	done

	tput setaf 4
	printf "\nUPLOAD SPEED HISTORY\n"
	for i in "${!u_speed[@]}"
	do
		printf "█%.0s" $(seq 0 $up_jump ${u_speed[$i]}) ; local bytes=$(bytes_convert "${u_speed[$i]}") ; printf " ${bytes}\n"
	done

	tput setaf 6
	printf "\nAVERAGE UPLOAD SPEED HISTORY\n"
	for i in "${!avg_u_speed[@]}"
	do
		printf "█%.0s" $(seq 0 $up_jump ${avg_u_speed[$i]}) ; local bytes=$(bytes_convert "${avg_u_speed[$i]}") ; printf " ${bytes}\n"
	done
	tput setaf 231
}

function cpu_load_generator {
	local cpu_freq=($(cat /proc/cpuinfo | grep MHz | awk '{print $4}'))
	local cpu_usage=()

	for i in $(seq 0 $((${core_num}-1)))
	do
		local c_idle=$(cat /proc/stat | grep cpu${i} | awk '{print $5}')
		local c_iowait=$(cat /proc/stat | grep cpu${i} | awk '{print $6}')
		local c_user=$(cat /proc/stat | grep cpu${i} | awk '{print $2}')
		local c_nice=$(cat /proc/stat | grep cpu${i} | awk '{print $3}')
		local c_system=$(cat /proc/stat | grep cpu${i} | awk '{print $4}')
		local c_irq=$(cat /proc/stat | grep cpu${i} | awk '{print $7}')
		local c_softirq=$(cat /proc/stat | grep cpu${i} | awk '{print $8}')
		local c_steal=$(cat /proc/stat | grep cpu${i} | awk '{print $9}')

		if [ ${counter} -gt 0 ]
		then
			local prev_idle=${cpu[$i]}
			local prev_non_idle=${cpu[$(($i+${core_num}))]}
			local prev_total=$((${prev_idle}+${prev_non_idle}))
		fi

		local total_idle=$((${c_idle}+${c_iowait}))
		local total_non_idle=$(("${c_user}+${c_nice}+${c_system}+${c_irq}+${c_softirq}+${c_steal}"))
		local total=$((${total_idle}+${total_non_idle}))

		cpu[$i]=${total_idle}
		cpu[$(($i+${core_num}))]=${total_non_idle}


		if [ ${counter} -gt 0 ]
		then
			local totald=$((${total}-${prev_total}))
			local idled=$((${total_idle}-${prev_idle}))
			cpu_usage[$i]=$(echo "scale=2 ; (${totald}-${idled})*100/${totald}" | bc)
		fi
	done

	for i in "${!cpu_usage[@]}"
	do
		local usage=$(echo "${cpu_usage[$i]} - (${cpu_usage[$i]} % 1)" | bc )
		local rest=$(echo "100-${usage}" | bc)
		local freq=$(echo "scale=2 ; ${cpu_freq[$i]}/1000" | bc)
		printf "core$i ${cpu_usage[$i]}%% [" ; tput setaf 2 ; printf "+%.0s" $(seq 1 "${cpu_usage[$i]}") ; tput setaf 231 ; printf ".%.0s" $(seq 1 ${rest} ) ; \
		printf "] ${freq} Ghz\n"
	done
}

function bytes_convert {
	if [ $(($1/1000000)) -gt 0 ]
	then
		local result=$(echo "scale=2 ; $1/1000000" | bc) ; echo "${result} MB"
	elif [ $(($1/1000)) -gt 0 ]
	then
		local result=$(echo "scale=2 ; $1/1000" | bc) ; echo "${result} KB"
	else
		echo "${1} B"
	fi
}

function uptime_convert {
	local days=$(echo "${total_uptime}/86400" | bc)
	local hours=$(echo "${total_uptime}/3600 % 24"| bc)
	local mins=$(echo "${total_uptime}/60 % 60" | bc)
	local secs=$(echo "${total_uptime} % 60" | bc)
	echo "${days}d ${hours}h ${mins}m ${secs}s"
}

function generate_ui {
	local ds=$(bytes_convert "${download_speed}")
	local us=$(bytes_convert "${upload_speed}")
	local ads=$(bytes_convert "${avg_download_speed}")
	local aus=$(bytes_convert "${avg_upload_speed}")
	local uptime=$(uptime_convert "${total_uptime}")
	local result="DOWNLOAD_SPEED|AVG_DS|UPLOAD_SPEED|AVG_US|BATTERY|UPTIME|SYS_LOAD|MEM\n"
	result+="${ds}\\s|${ads}\\s|${us}\\s|${aus}\\s|${battery}%%|${uptime}|${load}|${memory}\n"
	result=$(printf "${result}" | column -t -s '|' )
	printf "\n${result}\n"
	chart_generator
}

while true
do
	bytes_sent+=($(cat /proc/net/dev | grep wlo1: | awk '{print $10}'))
	bytes_recieved+=($(cat /proc/net/dev | grep wlo1: | awk '{print $2}'))
	bytes_sent_avg+=($(avg "${bytes_sent[@]}"))
	bytes_recieved_avg+=($(avg "${bytes_recieved[@]}"))

	total_uptime=$(cat /proc/uptime | sed 's/\s.*$//')
	battery=$(echo "100 * $(cat /sys/class/power_supply/BAT1/energy_now) / $(cat /sys/class/power_supply/BAT1/energy_full)" | bc)
	memory=$(cat /proc/meminfo | grep -i -w active: | sed 's/.*://' | sed 's/ //g')
	load=$(cat /proc/loadavg | cut -d ' ' -f -3)

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

	clear
	cpu_load_generator
	if [ ${counter} -gt 0 ]
	then
		generate_ui
	fi

	counter=$((${counter}+1))
	sleep 1
done

