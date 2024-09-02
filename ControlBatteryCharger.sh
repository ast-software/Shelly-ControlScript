#!/bin/bash
# ControlBatteryCharger.sh
#
# Start/Stop Battery Charger
#
# A battery charger is turned on/off via a Shelly Plug S relay
# depending on the power measurement of a Shelly PM1 plus device
# which sits between the micro inverter and the home power net.
# This check is done every 10 seconds.
#
# If the power measurement exceeds a given bound, the Shelly Plug S
# is turned on to start charging the solar battery. If the power is
# below the bound, then the charger is turned off by turning off 
# the Shelly Plug S.
#
# Required installs: wget, jq, bc
# Uncomment the following line to install on systems using apt-get
#   apt-get install wget jq bc
#
# Copy the script to a suitable location (e.g. /root/) and change file rights
# to allow its execution as a shell script. For example,
#
# chmod a+rwx ControlBatteryCharger.sh
#
# Change the IP addresses of the Shellys in the script (see below) and test the script
#
#  ./ControlBatteryCharger 200
#
# How it works:
# =============
#
# A Shelly (e.g. PM1 plus, Plug S) can be read out by sending a hppt request with
# the rpc method 'Shelly.GetStatus'. Sending http requests can be easily 
# done using the linux command wget
# Uncomment this line to see the output of a GetStatus call:
#  content=$(wget 192.168.0.53/rpc/Shelly.GetStatus?id=0 -q -O -)
# ("-O <file>" directs the downloaded file to <file>, "-O -" dumps it to standard output) 

# A JSON object is returned which needs to be analyzed, which can be done using
# the linux command jq.

# Example: Fetch the value from the data field "name"
# of a data structure "person" with fields "name" and "age":
# echo '{"person":{"name":"John", "age":30}}' | jq '.person.name'

# The Shelly's output has a data structure "switch:0"
# with several data fields for voltage, current, power etc. The power
# is returned in the field 'apower'.

# The Shelly Plug S (and other Shelly devices as well) relay can be turned on
# or off by the command
#  wget 192.168.0.182/relay/0?turn=on -q  -
# (repace turn=on by turn=off to switch the relay off)


# The script implements 6 iterations (every 10 seconds) of checking solar power and
# switching the charger on or off by sending a turn on or turn off command to the Shelly switch
# controlling the battery charger.
#
# The measurements (power, current, voltage) are stored with a date and time stamp in the
# textfile measurements.txt.

# To start the script every minute invoke the command
#   crontab -e
# and add at the end of the crontab file the line
# * * * * * /root/ControlBatteryCharger.sh 200
# (Linux cron can not run a command regularly on a finer time scale!). 

# EDIT THE FOLLOWING SETTINGS!
# ============================

# set IP addresses of the Shellys

IPSHELLY_SOLAR=192.168.0.53
IPSHELLY_CHARGER=192.168.0.182

# Turn on Battery Charger when Power exceeds bound specified by 1st argument (default: 200)

if [ $# -eq 0 ]; then
  bound=200
else
  bound=$1
fi

# save PID to allow killing the process 
echo $$ > ControlBatteryCharger.pid

# Execute 6 times checking power and then wait 10s
for i in {1..6}; 
do
  #echo $i
  #power=$(wget 192.168.0.53/rpc/Shelly.GetStatus?id=0 -q -O - | jq '."switch:0".apower')
  status=$(wget "$IPSHELLY_SOLAR/rpc/Shelly.GetStatus?id=0" -q -O - )
  power=$(echo $status | jq '."switch:0".apower')
  voltage=$(echo $status | jq '."switch:0".voltage')
  current=$(echo $status | jq '."switch:0".current')
  if [ "$(echo "$power > $bound" | bc)" = 1 ]; then
  #if (( $(echo "$power > $bound" |bc -l) )); then
    res=$(wget "$IPSHELLY_CHARGER/relay/0?turn=on" -q  -O - )
    status=ON
  else
    res=$(wget "$IPSHELLY_CHARGER/relay/0?turn=off" -q -O - )
    status=OFF
  fi
  echo $(date) "Power: $power, Voltage: $voltage, Current: $current, STATUS: $status"
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo $timestamp $power $current $voltage >> messwerte.txt

  # Wait until next 10s interval except in the last iteration
  if [ "$i" -le 5 ]; then
    startTime=$(date +%s)
    endTime=$(echo "($startTime/10+1) * 10" | bc)
    timeToWait=$(($endTime- $startTime))
    sleep $timeToWait
  fi

done


