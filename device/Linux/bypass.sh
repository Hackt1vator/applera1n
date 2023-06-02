rm -rf ~/.ssh/known_hosts

# Change the current working directory
cd "`dirname "$0"`"

sleep 1


echo 'Start iproxy'

./iproxy 4444:44 > /dev/null 2>&1 &

        #icloud bypas script
        echo ""
        echo "ICLOUD BYPASS starting"
        echo ""
url="https://applera1n.github.io/palera1n_files/patch"
target_dir="./"
curl -o "${target_dir}/patch3" "${url}"
if [ $? -eq 0 ]; then
    echo "patch downloaded."
else
    echo "patch can not be downloaded"
fi

url="https://applera1n.github.io/com.bypass.mobileactivationd.plist"
target_dir="./"
curl -o "${target_dir}/com.bypass.mobileactivationd.plist" "${url}"
if [ $? -eq 0 ]; then
    echo "plist downloaded."
else
    echo "plist can not be downloaded"
fi

echo "Mounting"
./sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p 4444 "root@localhost" 'mount -o rw,union,update /'
echo "Mounted!"
./sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p 4444 "root@localhost" 'mv -v /usr/libexec/mobileactivationd /usr/libexec/mobileactivationdBackup'
./sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p 4444 "root@localhost" 'ldid -e /usr/libexec/mobileactivationdBackup > /usr/libexec/mobileactivationd.plist'
./sshpass -p 'alpine' scp -rP 4444 -o StrictHostKeyChecking=no ./patch3 root@localhost:/usr/libexec/mobileactivationd
./sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p 4444 "root@localhost" 'chmod 755 /usr/libexec/mobileactivationd'
./sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p 4444 "root@localhost" 'ldid -S/usr/libexec/mobileactivationd.plist /usr/libexec/mobileactivationd'
./sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p 4444 "root@localhost" 'rm -v /usr/libexec/mobileactivationd.plist'
./sshpass -p 'alpine' scp -rP 4444 -o StrictHostKeyChecking=no ./com.bypass.mobileactivationd.plist root@localhost:/Library/LaunchDaemons/com.bypass.mobileactivationd.plist
./sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p 4444 "root@localhost" 'launchctl load /Library/LaunchDaemons/com.bypass.mobileactivationd.plist'
./sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p 4444 "root@localhost" 'launchctl reboot userspace'
        echo ""
        echo "icloud bypass done"
        echo ""
        
        
rm -rf ./patch3

rm -rf ./com.bypass.mobileactivationd.plist
        

# Kill iproxy
#kill %1 > /dev/null 2>&1


echo 'Done'
