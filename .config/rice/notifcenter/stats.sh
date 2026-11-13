#!/bin/sh
# Печатает одну строку: "<cpu%> <temp°C> <ram%> <disk%>"
s1=$(head -1 /proc/stat); sleep 0.4; s2=$(head -1 /proc/stat)
cpu=$(printf '%s\n%s\n' "$s1" "$s2" | awk 'NR==1{t1=$2+$3+$4+$5+$6+$7+$8; i1=$5+$6} NR==2{t2=$2+$3+$4+$5+$6+$7+$8; i2=$5+$6} END{d=t2-t1; printf "%d", (d>0 ? (d-(i2-i1))*100/d : 0)}')
temp=0
for h in /sys/class/hwmon/hwmon*; do
  [ "$(cat "$h/name" 2>/dev/null)" = k10temp ] && temp=$(( $(cat "$h/temp1_input") / 1000 )) && break
done
ram=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%d", (t-a)*100/t}' /proc/meminfo)
disk=$(df --output=pcent / | tail -1 | tr -dc '0-9')
echo "$cpu $temp $ram $disk"
