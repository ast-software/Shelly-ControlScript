Shelly Control Battery Charger

This bash script controls a battery charger connected via a Shelly Plug S by monitoring
the power output of a PV system measured by a Shelly PM1 plus device. The script uses
the Shellys functionality to read out their status via a http request.

YOU NEED TO CHANGE THE IP-ADDRESSES OF THE SCRIPT TO MATCH THE IP-ADRESSES OF YOUR SHELLYS!

If the power is larger than 200 W, then the Shelly Plug S is turned on, otherwise it is 
turned off.

By modfying the threshold (default: 200) you can adapt the script to your needs.

