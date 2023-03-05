
# iOS 15-16 iCloud Bypass

if ! which curl >> /dev/null; then
    echo "Error: curl not found"
    exit 1
fi
if ! which iproxy >> /dev/null; then
    echo "Error: iproxy not found"
    exit 1
fi

rm -rf ~/.ssh/known_hosts
clear

# Change the current working directory
cd "`dirname "$0"`"


echo 'Starting iproxy...'

killall iproxy
idevicepair pair
#iproxy 2222:22 > /dev/null 2>&1 &
iproxy 2222 22 &>/dev/null &
echo ""
echo "
░░░░░░░░░░░░░░░░░░▄░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░▌▄▄▄▀█▄░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░█░░░░██░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░█▄▄█▀▀░░░░░░░░░░░░░░░░
░░░░░░░░░░░░▄▄░░░░▌░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░██▀░░▀▀█▐░░░░▄▄▄░░░░░░░░░░░░░░░
░░░░░░░█░░░░░░░░░█▌░█░░░░▀█░░░░░░░░░░░░░
░░░░░░░▌░░░░░░░░░▐█▀░░░░░░░░█░░░░░░░░░░░
░░░░░░█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░▌░░░░░░░░░░░░░░░░░░░░░░▌░░░░░░░░░░
░░░░░░▌░░░░░░░░░░░░░░░░░░░░░░█░░░░░░░░░░
░░░░░░▌░░░░░░░░░░░░░░░░░░░░░░▐░░░░░░░░░░
░░░░░░▌░░░░░░░░░░░░░░░░░░░░░░▐░░░░░░░░░░
░░░░░░▌░░░░░░░░░░░░░░░░░░░░░░█░░░░░░░░░░
░░░░░░█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░▐░░░░░░░░░░░░░░░░░░░░░█░░░░░░░░░░░
░░░░░░░█▄░░░░░░░░░░░░░░░░░░░▌░░░░░░░░░░░
░░░░░░░░░▀▄▄░░░░░░▀█░░░░░░░█░░░░░░░░░░░░
░░░░░░░░░░░░▀▀▄▄▄▄▌▐▄▄▄▄▄█░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

"
echo ""

sleep 2
    
echo 'Mounting filesystem as read-write'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p2222 'mount_filesystems'

echo 'Running iOS 15-16 iCloud Bypass...'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p2222 'mv -v /mnt1/usr/libexec/mobileactivationd /mnt1/usr/libexec/mobileactivationdBackup'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p2222 'ldid -e /mnt1/usr/libexec/mobileactivationdBackup > /mnt1/usr/libexec/mob.plist'
#upload new mobileactivationd
sshpass -p 'alpine' scp -rP 2222 -o StrictHostKeyChecking=no ./droplet root@localhost:/mnt1/usr/libexec/mobileactivationd
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p2222 'chmod 755 /mnt1/usr/libexec/mobileactivationd'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p2222 'ldid -S/mnt1/usr/libexec/mob.plist /mnt1/usr/libexec/mobileactivationd'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p2222 'rm -v /mnt1/usr/libexec/mob.plist'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p2222 '/usr/sbin/nvram allow-root-hash-mismatch=1'



#echo "Pushing new data_ark.plist..."
#sshpass -p 'alpine' scp -rP 2222 -o StrictHostKeyChecking=no ./uploadAFTER_ACTIVATION/data_ark.plist root@localhost:/var/root/Library/Lockdown/data_ark.plist
#sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p 2222 "root@localhost" 'chmod 755 /var/root/Library/Lockdown/data_ark.plist'
#sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p 2222 "root@localhost" 'chflags uchg /var/root/Library/Lockdown/data_ark.plist'



echo 'booting device...'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p2222 /sbin/reboot
echo 'Device is now booting...'


sleep 2

# Kill iproxy
kill %1 > /dev/null 2>&1

echo 'bypass Done!'

echo ''
