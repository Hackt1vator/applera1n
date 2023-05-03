#!/usr/bin/env bash

#set -e

#change script activated working directory to current directory
cd "$(dirname "$0")"

echo 'MiniKick working...'


#now kick the detected UDID device into recovery mode!
./irecovery -n
