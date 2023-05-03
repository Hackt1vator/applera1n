#!/usr/bin/env bash

#set -e

#change script activated working directory to current directory
cd "$(dirname "$0")"

os=$(uname)
dir="$(pwd)/binaries/$os"

deviceUDID = null
outputConsole = null

echo 'MiniKick working...'
echo $("$dir"/ideviceinfo | grep "$2: " | sed "s/$2: //")

killall iproxy

idevicepair pair

#write temp file with the device info
ideviceinfo > outputConsole

#find the UDID in the temp file
grabbedUDIDinfo=$(grep 'UniqueDeviceID:' outputConsole)
#echo "$grabbedUDIDinfo"

#search and fix UDID
fixedUDID=${grabbedUDIDinfo/UniqueDeviceID: /}

echo 'Great success!'
echo 'Detected UDID: '$fixedUDID

#now kick the detected UDID device into recovery mode!
./ideviceenterrecovery $fixedUDID
