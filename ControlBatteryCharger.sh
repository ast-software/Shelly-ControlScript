#!/bin/bash
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
# A Shelly PM1 plus can be read out by sending a hppt request with
# the rpc method 'Shelly.GetStatus'. Sending http requests can be easily 
# done using the linu command wget
# Uncomment this line to see the output of a GetStatus call:
#  content=$(wget 192.168.0.53/rpc/Shelly.GetStatus?id=0 -q -O -)
# ("-O <file>" directs the downloaded file to <file>, "-O -" dumps it to standard output) 

# A JSON object is returned which needs to be analyzed.
# the linux command wget. JSON objects can be read out and analyzed using
# the linux command jq.

# An illustrative example how to fetch the value from the data field "name"
# of a data structure "person":
# echo '{"person":{"name":"John", "age":30}}' | jq '.person.name'

# By using a pipe command, the output from wget is
# used as input for jq. The Shelly's output has a data structure "switch:0"
# with several data fields for voltage, current, power etc. The power
# is returned in the field 'apower'.

# The Shelly Plug S (and other Shelly devices as well) relay can be turned on
# or off by the command
#  wget 192.168.0.182/relay/0?turn=on -q  -
# (repace turn=on by turn=off to switch the relay off)


# An endless loop is implemented which fetches the current power of the PV
# modules and sends a turn on or turn off command to the Shelly Plug S.
# The power measurements are stored with a date and time stamp in the
# textfile measurements.txt.

# Turn on Battery Charger when Power exceeds bound
bound=200

# save PID to allow killing the process 
echo $$ > ControlBatteryCharger.pid

# Execute 6 times checking power and then wait 10s
for i in {1..6}; 
do
  echo $i
  #power=$(wget 192.168.0.53/rpc/Shelly.GetStatus?id=0 -q -O - | jq '."switch:0".apower')
  status=$(wget 192.168.0.53/rpc/Shelly.GetStatus?id=0 -q -O - )
  power=$(echo $status | jq '."switch:0".apower')
  voltage=$(echo $status | jq '."switch:0".voltage')
  current=$(echo $status | jq '."switch:0".current')
  echo $(date) "Power: $power, Voltage: $voltage, Current: $current"
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "$power > $bound" | bc 
  if [ "$(echo "$power > $bound" | bc)" = 1 ]; then
  #if (( $(echo "$power > $bound" |bc -l) )); then
    echo "battery charger on"
    #echo $(wget 192.168.0.182/rpc/Switch.GetStatus?id=0 -q -O - )
    #echo $(wget 192.168.0.182/relay/0?turn=on -q -O - )
    res=$(wget 192.168.0.182/relay/0?turn=on -q  -O - )
    status=1
  else
    echo "battery charger off"
    #echo $(wget 192.168.0.182/relay/0?turn=off -q -O - )
    res=$(wget 192.168.0.182/relay/0?turn=off -q -O - )
    status=0
  fi
  echo $timestamp $power $current $voltage >> messwerte.txt
  echo $timestamp $power $current $voltage >> /media/Ansgar/Solardaten/messwerte.txt

  # copy data file every minute 
  # get current minute, compute remainder with respect to 3
  # and copy the file if the remainder is 1
  min=$(date '+%M')
  min_mod_3=$(echo "scale=0; $min%3" | bc -l)

  # Wait until next 10s interval except in the last iteration
  if [ "$i" -le 5 ]; then
    echo waiting $i
    startTime=$(date +%s)
    endTime=$(echo "($startTime/10+1) * 10" | bc)
    timeToWait=$(($endTime- $startTime))
    sleep $timeToWait
  fi

done


