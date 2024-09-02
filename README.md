Shelly Control Battery Charger
(C) ast-software
Published under the GPL License V3

This bash script controls a battery charger connected via a Shelly Plug S by monitoring
the power output of a PV system measured by a Shelly PM1 plus device. The script uses
the Shellys functionality to read out their status via a http request.

YOU NEED TO CHANGE THE IP-ADDRESSES OF THE SCRIPT TO MATCH THE IP-ADRESSES OF YOUR SHELLYS!

If the power is larger than 200 W, then the Shelly Plug S is turned on, otherwise it is 
turned off. The threshold can be specified as an argument to the command.

HOW TO INSTALL:
Download the project and copy the file(s) to a suitable location (e.g. /root/). Invoke

chmod a+rwx ControlBatteryCharger.sh

so that it can be executed as a command. Edit the file, scroll down and set the IP addresses
of your Shellys!

Invoke the script by

./ControlBatteryCharger.sh

to test it. Take a look at measurements.txt to check

less measurements.txt

Add the script to the crontab. Invoke

crontab -e

and add the line

"* * * * * /root/ControlBatteryCharger.sh 200"
       
(without quotes!) at the end of the file.

