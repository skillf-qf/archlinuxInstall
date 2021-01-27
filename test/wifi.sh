#!/bin/bash


read -r -p "input your wifi ssid: " wifiSSID
read -r -p "input your wifi psk: " wifiPSK
cat > wifi.conf <<EOF
ctrl_interface=/run/wpa_supplicant
update_config=1

network={
	ssid="$wifiSSID"
	psk="$wifiPSK"
}
EOF
