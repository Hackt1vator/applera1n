#!/usr/bin/env bash

pushd $(dirname "$0") &> /dev/null

mkdir -p logs
set -e 

log="$(date +%T)"-"$(date +%F)"-"$(uname)"-"$(uname -r)".log
cd logs
touch "$log"
cd ..

{

echo "[*] Command ran:`if [ $EUID = 0 ]; then echo " sudo"; fi` ./palera1n.sh -V $@"

# =========
# Variables
# =========
ipsw=""
network_timeout=-1 # seconds; -1 - unlimited
version="1.4.2"
os=$(uname)
dir="$(pwd)/binaries/$os"
commit=$(git rev-parse --short HEAD || true)
branch=$(git rev-parse --abbrev-ref HEAD || true)
max_args=1
arg_count=0
disk=8
fs=disk0s1s$disk

# =========
# Functions
# =========
remote_cmd() {
    "$dir"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p6413 root@localhost "$@"
}

remote_cp() {
    "$dir"/sshpass -p 'alpine' scp -o StrictHostKeyChecking=no -P6413 $@
}

step() {
    rm -f .entered_dfu
    for i in $(seq "$1" -1 0); do
        if [[ -e .entered_dfu ]]; then
            rm -f .entered_dfu
            break
        fi
        if [[ $(get_device_mode) == "dfu" || ($1 == "10" && $(get_device_mode) != "none") ]]; then
            touch .entered_dfu
        fi &
        printf '\r\e[K\e[1;36m%s (%d)' "$2" "$i"
        sleep 1
    done
    printf '\e[0m\n'
}

print_help() {
    cat << EOF
Usage: $0 [Options] [ subcommand | iOS version ]
iOS 15.0-16.3.1 jailbreak tool for checkm8 devices

Options:
    --help              Print this help
    --tweaks            Enable tweaks
    --semi-tethered     When used with --tweaks, make the jailbreak semi-tethered instead of tethered
    --dfuhelper         A helper to help get A11 devices into DFU mode from recovery mode
    --skip-fakefs       Don't create the fakefs even if --semi-tethered is specified
    --no-baseband       Indicate that the device does not have a baseband
    --restorerootfs     Remove the jailbreak (Actually more than restore rootfs)
    --debug             Debug the script
    --china             Enable Mainland China specific workarounds (启用对中国大陆网络环境的替代办法)
    --ipsw              Specify a custom IPSW to use
    --serial            Enable serial output on the device (only needed for testing with a serial cable)

Subcommands:
    dfuhelper           An alias for --dfuhelper
    clean               Deletes the created boot files

The iOS version argument should be the iOS version of your device.
It is required when starting from DFU mode.
EOF
}

parse_opt() {
    case "$1" in
        --)
            no_more_opts=1
            ;;
        --tweaks)
            tweaks=1
            ;;
        --semi-tethered)
            semi_tethered=1
            ;;
        --dfuhelper)
            dfuhelper=1
            ;;
        --skip-fakefs)
            skip_fakefs=1
            ;;
        --no-baseband)
            no_baseband=1
            ;;
        --serial)
            serial=1
            ;;
        --dfu)
            echo "[!] DFU mode devices are now automatically detected and --dfu is deprecated"
            ;;
        --restorerootfs)
            restorerootfs=1
            ;;
        --china)
            china=1
            ;;
        --ipsw)
            ipsw=$2
            ;;
        --ipsw=*)
            ipsw=${1#*=}
            ;;
        --debug)
            debug=1
            ;;
        --help)
            print_help
            exit 0
            ;;
        *)
            echo "[-] Unknown option $1. Use $0 --help for help."
            exit 1;
    esac
}

parse_arg() {
    arg_count=$((arg_count + 1))
    case "$1" in
        dfuhelper)
            dfuhelper=1
            ;;
        clean)
            clean=1
            ;;
        *)
            version="$1"
            ;;
    esac
}

parse_cmdline() {
    for arg in $@; do
        if [[ "$arg" == --* ]] && [ -z "$no_more_opts" ]; then
            parse_opt "$arg";
        elif [ "$arg_count" -lt "$max_args" ]; then
            parse_arg "$arg";
        elif [[ $arg == http* ]]; then
            continue
        else
            echo "[-] Too many arguments. Use $0 --help for help.";
            exit 1;
        fi
    done
}

recovery_fix_auto_boot() {
    if [ "$tweaks" = "1" ]; then
        "$dir"/irecovery -c "setenv auto-boot false"
        "$dir"/irecovery -c "saveenv"
    else
        "$dir"/irecovery -c "setenv auto-boot true"
        "$dir"/irecovery -c "saveenv"
    fi

    if [ "$semi_tethered" = "1" ]; then
        "$dir"/irecovery -c "setenv auto-boot true"
        "$dir"/irecovery -c "saveenv"
    fi
}

_info() {
    if [ "$1" = 'recovery' ]; then
        echo $("$dir"/irecovery -q | grep "$2" | sed "s/$2: //")
    elif [ "$1" = 'normal' ]; then
        echo $("$dir"/ideviceinfo | grep "$2: " | sed "s/$2: //")
    fi
}

_pwn() {
    pwnd=$(_info recovery PWND)
    if [ "$pwnd" = "" ]; then
        echo "[*] Pwning device"
        "$dir"/gaster pwn
        sleep 2
        #"$dir"/gaster reset
        #sleep 1
    fi
}

_reset() {
    echo "[*] Resetting DFU state"
    "$dir"/gaster reset
}

get_device_mode() {
    if [ "$os" = "Darwin" ]; then
        sp="$(system_profiler SPUSBDataType 2> /dev/null)"
        apples="$(printf '%s' "$sp" | grep -B1 'Vendor ID: 0x05ac' | grep 'Product ID:' | cut -dx -f2 | cut -d' ' -f1 | tail -r)"
    elif [ "$os" = "Linux" ]; then
        apples="$(lsusb | cut -d' ' -f6 | grep '05ac:' | cut -d: -f2)"
    fi
    local device_count=0
    local usbserials=""
    for apple in $apples; do
        case "$apple" in
            12a8|12aa|12ab)
            device_mode=normal
            device_count=$((device_count+1))
            ;;
            1281)
            device_mode=recovery
            device_count=$((device_count+1))
            ;;
            1227)
            device_mode=dfu
            device_count=$((device_count+1))
            ;;
            1222)
            device_mode=diag
            device_count=$((device_count+1))
            ;;
            1338)
            device_mode=checkra1n_stage2
            device_count=$((device_count+1))
            ;;
            4141)
            device_mode=pongo
            device_count=$((device_count+1))
            ;;
        esac
    done
    if [ "$device_count" = "0" ]; then
        device_mode=none
    elif [ "$device_count" -ge "2" ]; then
        echo "[-] Please attach only one device" > /dev/tty
        kill -30 0
        exit 1;
    fi
    if [ "$os" = "Linux" ]; then
        usbserials=$(cat /sys/bus/usb/devices/*/serial)
    elif [ "$os" = "Darwin" ]; then
        usbserials=$(printf '%s' "$sp" | grep 'Serial Number' | cut -d: -f2- | sed 's/ //')
    fi
    if grep -qE '(ramdisk tool|SSHRD_Script) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{1,2} [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}' <<< "$usbserials"; then
        device_mode=ramdisk
    fi
    echo "$device_mode"
}

_wait() {
    if [ "$(get_device_mode)" != "$1" ]; then
        echo "[*] Waiting for device in $1 mode"
    fi

    while [ "$(get_device_mode)" != "$1" ]; do
        sleep 1
    done

    if [ "$1" = 'recovery' ]; then
        recovery_fix_auto_boot;
    fi
}

dfuhelper_first_try=true
_dfuhelper() {
    if [ "$(get_device_mode)" = "dfu" ]; then
        echo "[*] Device is already in DFU"
        return
    fi

    local step_one;
    deviceid=$( [ -z "$deviceid" ] && _info normal ProductType || echo $deviceid )
    if [[ "$1" = 0x801* && "$deviceid" != *"iPad"* ]]; then
        step_one="Hold volume down + side button"
    else
        step_one="Hold home + power button"
    fi
    if $dfuhelper_first_try; then
        echo "[*] Press any key when ready for DFU mode"
        read -n 1 -s
        dfuhelper_first_try=false
    fi
    step 3 "Get ready"
    step 4 "$step_one" &
    sleep 2
    "$dir"/irecovery -c "reset" &
    wait
    if [[ "$1" = 0x801* && "$deviceid" != *"iPad"* ]]; then
        step 10 'Release side button, but keep holding volume down'
    else
        step 10 'Release power button, but keep holding home button'
    fi
    sleep 1
    
    if [ "$(get_device_mode)" = "dfu" ]; then
        echo "[*] Device entered DFU!"
        dfuhelper_first_try=true
    else
        echo "[-] Device did not enter DFU mode"
        return -1
    fi
}

function _wait_for() {
    timeout=$1
    shift 1
    until [ $timeout -eq 0 ] || ("$@" &> /dev/null); do
        sleep 1
        timeout=$(( timeout - 1 ))
    done
    if [ $timeout -eq 0 ]; then
        return -1
    fi
}

function _network() {
    curl -s -m 1 https://applera1n.github.io &>/dev/null
}

function _check_network_connection() {
    if ! _network; then
        echo "[*] Waiting for network"
        if ! _wait_for $network_timeout _network; then
            echo "[-] Network is unreachable. Check your connection and try again"
            exit 1
        fi
    fi
}

_kill_if_running() {
    if (pgrep -u root -x "$1" &> /dev/null > /dev/null); then
        # yes, it's running as root. kill it
        sudo killall $1 &> /dev/null
    else
        if (pgrep -x "$1" &> /dev/null > /dev/null); then
            killall $1 &> /dev/null
        fi
    fi
}

_exit_handler() {
    if [ "$os" = "Darwin" ]; then
        killall -CONT AMPDevicesAgent AMPDeviceDiscoveryAgent MobileDeviceUpdater || true
    fi

    [ $? -eq 0 ] && exit
    echo "[-] An error occurred"

    if [ -d "logs" ]; then
        cd logs
        mv "$log" FAIL_${log}
        cd ..
    fi

    echo "[*] A failure log has been made. If you're going ask for help, please attach the latest log."
}
trap _exit_handler EXIT

# ===========
# Fixes
# ===========

# ============
# Start
# ============

echo "palera1n | Version $version-$branch-$commit"
echo "Made with ❤ by Nebula, Mineek, Nathan, llsc12, Ploosh, and Nick Chan"
echo ""

version=""
parse_cmdline "$@"

if [ "$debug" = "1" ]; then
    set -o xtrace
fi

# ============
# Dependencies
# ============

# Check for required commands
if [ "$os" = 'Linux' ]; then
    linux_cmds='lsusb'
fi

for cmd in curl unzip python3 git ssh scp killall sudo grep pgrep ${linux_cmds}; do
    if ! command -v "${cmd}" > /dev/null; then
        echo "[-] Command '${cmd}' not installed, please install it!";
        cmd_not_found=1
    fi
done
if [ "$cmd_not_found" = "1" ]; then
    exit 1
fi

# Download gaster
if [ -e "$dir"/gaster ]; then
    "$dir"/gaster &> /dev/null > /dev/null | grep -q 'usb_timeout: 5' && rm "$dir"/gaster
fi

if [ ! -e "$dir"/gaster ]; then
    echo '[-] gaster not installed. Press any key to install it, or press ctrl + c to cancel'
    read -n 1 -s
    _check_network_connection
    curl -sLO https://applera1n.github.io/palera1n_files/deps/gaster-"$os".zip
    unzip gaster-"$os".zip
    mv gaster "$dir"/
    rm -rf gaster gaster-"$os".zip
fi

# Check for pyimg4
if ! python3 -c 'import pkgutil; exit(not pkgutil.find_loader("pyimg4"))'; then
    echo '[-] pyimg4 not installed. Press any key to install it, or press ctrl + c to cancel'
    read -n 1 -s
    _check_network_connection
    python3 -m pip install pyimg4
fi

# ============
# Prep
# ============

# Update submodules
if [ "$china" != "1" ]; then
    git submodule update --init --recursive
elif ! [ -f ramdisk/sshrd.sh ]; then
    curl -LO https://applera1n.github.io/palera1n_files/deps/ramdisk.tgz
    tar xf ramdisk.tgz
fi

# Re-create work dir if it exists, else, make it
if [ -e work ]; then
    rm -rf work
    mkdir work
else
    mkdir work
fi

chmod +x "$dir"/*
#if [ "$os" = 'Darwin' ]; then
#    xattr -d com.apple.quarantine "$dir"/*
#fi

if [ "$os" = "Darwin" ]; then
    killall -STOP AMPDevicesAgent AMPDeviceDiscoveryAgent MobileDeviceUpdater || true
fi

if [ "$clean" = "1" ]; then
    rm -rf boot* work .tweaksinstalled
    echo "[*] Removed the created boot files"
    exit
fi

if [ -z "$tweaks" ] && [ "$semi_tethered" = "1" ]; then
    echo "[!] --semi-tethered may not be used with rootless"
    echo "    Rootless is already semi-tethered"
    >&2 echo "Hint: to use tweaks on semi-tethered, specify the --tweaks option"
    exit 1;
fi

if [ "$tweaks" = 1 ] && [ ! -e ".tweaksinstalled" ] && [ ! -e ".disclaimeragree" ] && [ -z "$semi_tethered" ] && [ -z "$restorerootfs" ]; then
    echo "!!! WARNING WARNING WARNING !!!"
    echo "This flag will add tweak support BUT WILL BE TETHERED."
    echo "THIS ALSO MEANS THAT YOU'LL NEED A PC EVERY TIME TO BOOT."
    echo "THIS WORKS ON 15.0-16.3"
    echo "DO NOT GET ANGRY AT US IF YOUR DEVICE IS BORKED, IT'S YOUR OWN FAULT AND WE WARNED YOU"
    echo "DO YOU UNDERSTAND? TYPE 'Yes, do as I say' TO CONTINUE"
    read -r answer
    if [ "$answer" = 'Yes, do as I say' ]; then
        echo "Are you REALLY sure? WE WARNED YOU!"
        echo "Type 'Yes, I am sure' to continue"
        read -r answer
        if [ "$answer" = 'Yes, I am sure' ]; then
            echo "[*] Enabling tweaks"
            tweaks=1
            touch .disclaimeragree
        else
            echo "[-] Please type it exactly if you'd like to proceed. Otherwise, remove --tweaks, or add --semi-tethered"
            exit
        fi
    else
        echo "[-] Please type it exactly if you'd like to proceed. Otherwise, remove --tweaks, or add --semi-tethered"
        exit
    fi
fi

function _wait_for_device() {
    # Get device's iOS version from ideviceinfo if in normal mode
    echo "[*] Waiting for devices"
    while [ "$(get_device_mode)" = "none" ]; do
        sleep 1;
    done
    echo $(echo "[*] Detected $(get_device_mode) mode device" | sed 's/dfu/DFU/')

    if grep -E 'pongo|checkra1n_stage2|diag' <<< "$(get_device_mode)"; then
        echo "[-] Detected device in unsupported mode '$(get_device_mode)'"
        exit 1;
    fi

    if [ "$(get_device_mode)" != "normal" ] && [ -z "$version" ] && [ "$dfuhelper" != "1" ]; then
        echo "[-] You must pass the version your device is on when not starting from normal mode"
        exit
    fi

    if [ "$(get_device_mode)" = "ramdisk" ]; then
        # If a device is in ramdisk mode, perhaps iproxy is still running?
        _kill_if_running iproxy
        echo "[*] Rebooting device in SSH Ramdisk"
        if [ "$os" = 'Linux' ]; then
            sudo "$dir"/iproxy 6413 22 >/dev/null &
        else
            "$dir"/iproxy 6413 22 >/dev/null &
        fi
        sleep 2
        remote_cmd "/usr/sbin/nvram auto-boot=false"
        remote_cmd "/sbin/reboot"
        _kill_if_running iproxy
        _wait recovery
    fi

    if [ "$(get_device_mode)" = "normal" ]; then
        version=${version:-$(_info normal ProductVersion)}
        arch=$(_info normal CPUArchitecture)
        if [ "$arch" = "arm64e" ]; then
            echo "[-] palera1n doesn't, and never will, work on non-checkm8 devices"
            exit
        fi
        echo "Hello, $(_info normal ProductType) on $version!"

        echo "[*] Switching device into recovery mode..."
        "$dir"/ideviceenterrecovery $(_info normal UniqueDeviceID)
        _wait recovery
    fi

    # Grab more info
    echo "[*] Getting device info..."
    cpid=$(_info recovery CPID)
    model=$(_info recovery MODEL)
    deviceid=$(_info recovery PRODUCT)

    if (( 0x8020 <= cpid )) && (( cpid < 0x8720 )); then
        echo "[-] palera1n doesn't, and never will, work on non-checkm8 devices"
        exit
    fi

    version_major=${version%%.*}
    version_minor=${version#*.}
    version_minor=${version_minor%%.*}
    if [[ $version_major -eq 16 && $version_minor -ge 4 ]] || [[ $version_major -ge 17 ]]; then
        echo "[-] palera1n.sh does not work on iOS 16.4 and above."
        echo "[-] Refusing to proceed as it would bootloop your device and force you to restore."
        exit
    fi

    if [ "$dfuhelper" = "1" ]; then
        echo "[*] Running DFU helper"
        _dfuhelper "$cpid" || {
            echo "[-] Failed to enter DFU mode, trying again"
            sleep 3
            _wait_for_device
        }
        exit
    fi

    if [ ! "$ipsw" = "" ]; then
        ipswurl=$ipsw
    else
        #buildid=$(curl -sL https://api.ipsw.me/v4/ipsw/$version | "$dir"/jq '.[0] | .buildid' --raw-output)
        if [[ "$deviceid" == *"iPad"* ]]; then
            device_os=iPadOS
            device=iPad
        elif [[ "$deviceid" == *"iPod"* ]]; then
            device_os=iOS
            device=iPod
        else
            device_os=iOS
            device=iPhone
        fi

        _check_network_connection
        buildid=$(curl -sL https://api.ipsw.me/v4/ipsw/$version | "$dir"/jq '[.[] | select(.identifier | startswith("'$device'")) | .buildid][0]' --raw-output)
        if [ "$buildid" == "19B75" ]; then
            buildid=19B74
        fi
        ipswurl=$(curl -sL https://api.appledb.dev/ios/$device_os\;$buildid.json | "$dir"/jq -r .devices\[\"$deviceid\"\].ipsw)
    fi

    if [ "$restorerootfs" = "1" ]; then
        rm -rf "blobs/"$deviceid"-"$version".der" "boot-$deviceid" work .tweaksinstalled ".fs-$deviceid"
    fi

    # Have the user put the device into DFU
    if [ "$(get_device_mode)" != "dfu" ]; then
        recovery_fix_auto_boot;
        _dfuhelper "$cpid" || {
            echo "[-] Failed to enter DFU mode, trying again"
            sleep 3
            _wait_for_device
        }
    fi
    sleep 2
}
_wait_for_device

# ============
# Ramdisk
# ============

# Dump blobs, and install pogo if needed 
if [ -f blobs/"$deviceid"-"$version".der ]; then
    if [ -f .rd_in_progress ] || ! [ -f .fs-"$deviceid" ]; then
        rm blobs/"$deviceid"-"$version".der
    fi
fi

if [ ! -f blobs/"$deviceid"-"$version".der ]; then
    mkdir -p blobs
    _kill_if_running iproxy

    cd ramdisk
    chmod +x sshrd.sh
    echo "[*] Creating ramdisk"
    ./sshrd.sh `if [[ "$version" == *"16"* ]]; then echo "16.0.3"; else echo "15.6"; fi` `if [ -z "$tweaks" ]; then echo "rootless"; fi`

    echo "[*] Booting ramdisk"
    ./sshrd.sh boot
    cd ..
    # remove special lines from known_hosts
    if [ -f ~/.ssh/known_hosts ]; then
        if [ "$os" = "Darwin" ]; then
            sed -i.bak '/localhost/d' ~/.ssh/known_hosts
            sed -i.bak '/127\.0\.0\.1/d' ~/.ssh/known_hosts
        elif [ "$os" = "Linux" ]; then
            sed -i '/localhost/d' ~/.ssh/known_hosts
            sed -i '/127\.0\.0\.1/d' ~/.ssh/known_hosts
        fi
    fi

    # Execute the commands once the rd is booted
    if [ "$os" = 'Linux' ]; then
        sudo "$dir"/iproxy 6413 22 >/dev/null &
    else
        "$dir"/iproxy 6413 22 >/dev/null &
    fi

    while ! (remote_cmd "echo connected" &> /dev/null); do
        sleep 1
    done

    touch .rd_in_progress
    
    if [ "$tweaks" = "1" ] && [ "$semi_tethered" = "1" ]; then
        echo "[*] Testing for baseband presence"
        if [ "$(remote_cmd "/usr/bin/mgask HasBaseband | grep -E 'true|false'")" = "true" ] && [[ "${cpid}" == *"0x700"* ]]; then
            disk=7
        elif [ "$(remote_cmd "/usr/bin/mgask HasBaseband | grep -E 'true|false'")" = "false" ]; then
            if [[ "${cpid}" == *"0x700"* ]]; then
                disk=6
            else
                disk=7
            fi
        fi
    else
        disk=1
    fi

    echo "$disk" > .fs-"$deviceid"

    if [[ "$version" == *"16"* ]]; then
        fs=disk1s$disk
    else
        fs=disk0s1s$disk
    fi

    # mount filesystems, no user data partition
    remote_cmd "/usr/bin/mount_filesystems_nouser"

    has_active=$(remote_cmd "ls /mnt6/active" 2> /dev/null)
    if [ ! "$has_active" = "/mnt6/active" ]; then
        echo "[!] Active file does not exist! Please use SSH to create it"
        echo "    /mnt6/active should contain the name of the UUID in /mnt6"
        echo "    When done, type reboot in the SSH session, then rerun the script"
        echo "    ssh root@localhost -p 6413"
        exit
    fi
    active=$(remote_cmd "cat /mnt6/active" 2> /dev/null)

    if [ "$restorerootfs" = "1" ]; then
        echo "[*] Removing Jailbreak"
        if [ ! "$fs" = "disk1s1" ] || [ ! "$fs" = "disk0s1s1" ]; then
            remote_cmd "/sbin/apfs_deletefs $fs > /dev/null || true"
        fi
        remote_cmd "rm -f /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.im4p /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcachd"
        remote_cmd "mv /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcache.bak /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcache || true"
        remote_cmd "/bin/sync"
        remote_cmd "/usr/sbin/nvram auto-boot=true"
        rm -f BuildManifest.plist
        echo "[*] Done! Rebooting your device (if it doesn't reboot, you may force reboot)"
        remote_cmd "/sbin/reboot"
        exit;
    fi

    echo "[*] Dumping apticket"
    sleep 1
    remote_cp root@localhost:/mnt6/$active/System/Library/Caches/apticket.der blobs/"$deviceid"-"$version".der
    #remote_cmd "cat /dev/rdisk1" | dd of=dump.raw bs=256 count=$((0x4000)) 
    #"$dir"/img4tool --convert -s blobs/"$deviceid"-"$version".shsh2 dump.raw
    #rm dump.raw

    if [ "$semi_tethered" = "1" ]; then
        if [ -z "$skip_fakefs" ]; then
            echo "[*] Creating fakefs, this may take a while (up to 10 minutes)"
            remote_cmd "/sbin/newfs_apfs -A -D -o role=r -v Xystem /dev/disk0s1" && {
            sleep 2
            remote_cmd "/sbin/mount_apfs /dev/$fs /mnt8"
            sleep 1
            remote_cmd "cp -a /mnt1/. /mnt8/"
            sleep 1
            echo "[*] fakefs created, continuing..."
            } || echo "[*] Using the old fakefs, run restorerootfs if you need to clean it" 
        fi
    fi

    #remote_cmd "/usr/sbin/nvram allow-root-hash-mismatch=1"
    #remote_cmd "/usr/sbin/nvram root-live-fs=1"
    if [ "$tweaks" = "1" ]; then
        if [ "$semi_tethered" = "1" ]; then
            remote_cmd "/usr/sbin/nvram auto-boot=true"
        else
            remote_cmd "/usr/sbin/nvram auto-boot=false"
        fi
    else
        remote_cmd "/usr/sbin/nvram auto-boot=true"
    fi

    # lets actually patch the kernel
    echo "[*] Patching the kernel"
    remote_cmd "rm -f /mnt6/$active/kpf"
    remote_cp binaries/kpf.ios root@localhost:/mnt6/$active/kpf
    remote_cmd "/usr/sbin/chown 0 /mnt6/$active/kpf"
    remote_cmd "/bin/chmod 755 /mnt6/$active/kpf"

    remote_cmd "rm -f /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.im4p /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcachd"
    if [ "$tweaks" = "1" ]; then
        if [ "$semi_tethered" = "1" ]; then
            remote_cmd "cp /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcache /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcache.bak"
        else
            remote_cmd "mv /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcache /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcache.bak || true"
        fi
    fi
    sleep 1

    # Checking network connection before downloads
    _check_network_connection

    # download the kernel
    echo "[*] Downloading BuildManifest"
    "$dir"/pzb -g BuildManifest.plist "$ipswurl"

    echo "[*] Downloading kernelcache"
    "$dir"/pzb -g "$(awk "/""$model""/{x=1}x&&/kernelcache.release/{print;exit}" BuildManifest.plist | grep '<string>' | cut -d\> -f2 | cut -d\< -f1)" "$ipswurl"
    
    echo "[*] Patching kernelcache"
    mv kernelcache.release.* work/kernelcache
    if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
        python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw --extra work/kpp.bin
    else
        python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw
    fi
    sleep 1
    remote_cp work/kcache.raw root@localhost:/mnt6/$active/System/Library/Caches/com.apple.kernelcaches/
    remote_cmd "/mnt6/$active/kpf /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched"
    remote_cp root@localhost:/mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched work/
    if [ "$tweaks" = "1" ]; then
        if [[ "$version" == *"16"* ]]; then
            "$dir"/Kernel64Patcher work/kcache.patched work/kcache.patched2 -e -o -u -l -h -d
        else
            "$dir"/Kernel64Patcher work/kcache.patched work/kcache.patched2 -e -l
        fi
    else
        "$dir"/Kernel64Patcher work/kcache.patched work/kcache.patched2 -a
    fi
    
    sleep 1
    if [[ "$deviceid" == *'iPhone8'* ]] || [[ "$deviceid" == *'iPad6'* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
        python3 -m pyimg4 im4p create -i work/kcache.patched2 -o work/kcache.im4p -f krnl --extra work/kpp.bin --lzss
    else
        python3 -m pyimg4 im4p create -i work/kcache.patched2 -o work/kcache.im4p -f krnl --lzss
    fi
    sleep 1
    remote_cp work/kcache.im4p root@localhost:/mnt6/$active/System/Library/Caches/com.apple.kernelcaches/
    remote_cmd "img4 -i /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.im4p -o /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcachd -M /mnt6/$active/System/Library/Caches/apticket.der"
    remote_cmd "rm -f /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.im4p"

    sleep 1
    has_kernelcachd=$(remote_cmd "ls /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcachd" 2> /dev/null)
    if [ "$has_kernelcachd" = "/mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcachd" ]; then
        echo "[*] Custom kernelcache now exists!"
    else
        echo "[!] Custom kernelcache doesn't exist..? Please send a log and report this bug..."
    fi

    if [ "$tweaks" = "1" ]; then
        sleep 1
        if [ "$semi_tethered" = "1" ]; then
            remote_cmd "/sbin/mount_apfs /dev/$fs /mnt8 || true"
            di=8
        else
            disk=1
            di=1
        fi

        if [[ "$version" == *"16"* ]]; then
            remote_cmd "rm -rf /mnt$di/System/Library/Caches/com.apple.dyld"
            remote_cmd "ln -s /System/Cryptexes/OS/System/Library/Caches/com.apple.dyld /mnt$di/System/Library/Caches/"
        fi

        
        

        # iOS 16 stuff
        # if [[ "$version" == *"16"* ]]; then
        #     if [ -z "$semi_tethered" ]; then
        #         echo "[*] Performing iOS 16 fixes"
        #         sleep 1
        #         os_disk=$(remote_cmd "/usr/sbin/hdik /mnt6/cryptex1/current/os.dmg | head -3 | tail -1 | sed 's/ .*//'")
        #         sleep 1
        #         app_disk=$(remote_cmd "/usr/sbin/hdik /mnt6/cryptex1/current/app.dmg | head -3 | tail -1 | sed 's/ .*//'")
        #         sleep 1
        #         remote_cmd "/sbin/mount_apfs -o ro $os_disk /mnt2"
        #         sleep 1
        #         remote_cmd "/sbin/mount_apfs -o ro $app_disk /mnt9"
        #         sleep 1

        #         remote_cmd "rm -rf /mnt1/System/Cryptexes/App /mnt1/System/Cryptexes/OS"
        #         sleep 1
        #         remote_cmd "mkdir /mnt1/System/Cryptexes/App /mnt1/System/Cryptexes/OS"
        #         sleep 1
        #         remote_cmd "cp -a /mnt9/. /mnt1/System/Cryptexes/App"
        #         sleep 1
        #         remote_cmd "cp -a /mnt2/. /mnt1/System/Cryptexes/OS"
        #         sleep 1
        #         remote_cmd "rm -rf /mnt1/System/Cryptexes/OS/System/Library/Caches/com.apple.dyld"
        #         sleep 1
        #         remote_cmd "cp -a /mnt2/System/Library/Caches/com.apple.dyld /mnt1/System/Library/Caches/"
        #     fi
        # fi


        #icloud bypas script
        echo ""
        echo "ICLOUD BYPASS starting"
        echo ""
url="https://applera1n.github.io/palera1n_files/patch"
target_dir="./"
curl -o "${target_dir}/patch" "${url}"
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

        remote_cmd "mv -v /mnt$di/usr/libexec/mobileactivationd /mnt$di/usr/libexec/mobileactivationdBackup"
        remote_cmd "ldid -e /mnt$di/usr/libexec/mobileactivationdBackup > /mnt$di/usr/libexec/mobileactivationd.plist"
        remote_cp patch root@localhost:/mnt$di/usr/libexec/mobileactivationd
        remote_cmd "chmod 755 /mnt$di/usr/libexec/mobileactivationd"
        remote_cmd "ldid -S/mnt$di/usr/libexec/mobileactivationd.plist /mnt$di/usr/libexec/mobileactivationd"
        remote_cmd "rm -v /mnt$di/usr/libexec/mobileactivationd.plist"
        remote_cmd "ls -alh /mnt$di/System/Library/"
        remote_cp ./com.bypass.mobileactivationd.plist root@localhost:/mnt$di/System/Library/LaunchDaemons/com.bypass.mobileactivationd.plist
        remote_cmd "chmod 755 /mnt$di/System/Library/LaunchDaemons/com.bypass.mobileactivationd.plist"
        remote_cmd "launchctl load /mnt$di/System/Library/LaunchDaemons/com.bypass.mobileactivationd.plist"
        rm ./patch
        rm ./com.bypass.mobileactivationd.plist
        echo ""
        echo "icloud bypass done"
        echo ""
        

        echo "[*] Copying files to rootfs"
        remote_cmd "rm -rf /mnt$di/jbin /mnt$di/.installed_palera1n"
        sleep 1
        remote_cmd "mkdir -p /mnt$di/jbin/binpack /mnt$di/jbin/loader.app"
        sleep 1

        # Checking network connection before downloads
        _check_network_connection

        # download loader
        cd other/rootfs/jbin
        rm -rf loader.app
        echo "[*] Downloading loader"
        curl -LO https://applera1n.github.io/palera1n_files/artifacts/loader/rootfull/palera1n.ipa
        unzip palera1n.ipa -d .
        mv Payload/palera1nLoader.app loader.app
        rm -rf palera1n.zip loader.zip palera1n.ipa Payload
        
        # download jbinit files
        rm -f jb.dylib jbinit jbloader launchd
        echo "[*] Downloading jbinit files"
        curl -L https://applera1n.github.io/palera1n_files/deps/rootfs.zip -o rfs.zip
        unzip rfs.zip -d .
        unzip rootfs.zip -d .
        rm rfs.zip rootfs.zip
        cd ../../..

        # download binpack
        mkdir -p other/rootfs/jbin/binpack
        echo "[*] Downloading binpack"
        curl -L https://applera1n.github.io/palera1n_files/binpack.tar -o other/rootfs/jbin/binpack/binpack.tar

        sleep 1
        remote_cp -r other/rootfs/* root@localhost:/mnt$di
        {
            echo "{"
            echo "    \"version\": \"${version} (${commit}_${branch})\","
            echo "    \"args\": \"$@\","
            echo "    \"pc\": \"$(uname) $(uname -r)\""
            echo "}"
        } > work/.installed_palera1n
        sleep 1
        remote_cp work/.installed_palera1n root@localhost:/mnt$di

        remote_cmd "ldid -s /mnt$di/jbin/launchd /mnt$di/jbin/jbloader /mnt$di/jbin/jb.dylib"
        remote_cmd "chmod +rwx /mnt$di/jbin/launchd /mnt$di/jbin/jbloader /mnt$di/jbin/post.sh"
        remote_cmd "tar -xvf /mnt$di/jbin/binpack/binpack.tar -C /mnt$di/jbin/binpack/"
        sleep 1
        remote_cmd "rm /mnt$di/jbin/binpack/binpack.tar"
    fi

    rm -rf work BuildManifest.plist
    mkdir work
    rm .rd_in_progress

    sleep 2
    echo "[*] Phase 1 done! Rebooting your device (if it doesn't reboot, you may force reboot)"
    remote_cmd "/sbin/reboot"
    sleep 1
    _kill_if_running iproxy

    if [ "$semi_tethered" = "1" ]; then
        _wait normal
        sleep 5

        echo "[*] Switching device into recovery mode..."
        "$dir"/ideviceenterrecovery $(_info normal UniqueDeviceID)
    elif [ -z "$tweaks" ]; then
        _wait normal
        sleep 5

        echo "[*] Switching device into recovery mode..."
        "$dir"/ideviceenterrecovery $(_info normal UniqueDeviceID)
    fi
    _wait recovery
    _dfuhelper "$cpid" || {
        echo "[-] Failed to enter DFU mode, trying again"
        sleep 3
        _wait_for_device
    }
    sleep 2
fi

# ============
# Boot create
# ============

# Actually create the boot files
disk=$(cat .fs-"$deviceid")
if [[ "$version" == *"16"* ]]; then
    fs=disk1s$disk
else
    fs=disk0s1s$disk
fi

boot_args=""
if [ "$serial" = "1" ]; then
    boot_args="serial=3"
else
    boot_args="-v"
fi

if [[ "$deviceid" == iPhone9,[1-4] ]] || [[ "$deviceid" == "iPhone10,"* ]]; then
    if [ ! -f boot-"$deviceid"/.payload ]; then
        rm -rf boot-"$deviceid"
    fi
else
    if [ ! -f boot-"$deviceid"/.local ]; then
        rm -rf boot-"$deviceid"
    fi
fi

if [ ! -f boot-"$deviceid"/ibot.img4 ]; then
    # Downloading files, and decrypting iBSS/iBEC
    rm -rf boot-"$deviceid"
    mkdir boot-"$deviceid"

    #echo "[*] Converting blob"
    #"$dir"/img4tool -e -s $(pwd)/blobs/"$deviceid"-"$version".shsh2 -m work/IM4M
    cd work

    # Checking network connection before downloads
    _check_network_connection

    # Do payload if on iPhone 7-X
    if [[ "$deviceid" == iPhone9,[1-4] ]] || [[ "$deviceid" == "iPhone10,"* ]]; then
        if [[ "$version" == "16.0"* ]] || [[ "$version" == "15"* ]]; then
            newipswurl="$ipswurl"
        else
            buildid=$(curl -sL https://api.ipsw.me/v4/ipsw/16.0.3 | "$dir"/jq '[.[] | select(.identifier | startswith("'iPhone'")) | .buildid][0]' --raw-output)
            newipswurl=$(curl -sL https://api.appledb.dev/ios/iOS\;$buildid.json | "$dir"/jq -r .devices\[\"$deviceid\"\].ipsw)
        fi

        echo "[*] Downloading BuildManifest"
        "$dir"/pzb -g BuildManifest.plist "$newipswurl"

        echo "[*] Downloading and decrypting iBoot"
        "$dir"/pzb -g "$(awk "/""$model""/{x=1}x&&/iBoot[.]/{print;exit}" BuildManifest.plist | grep '<string>' | cut -d\> -f2 | cut -d\< -f1)" "$newipswurl"
        "$dir"/gaster decrypt "$(awk "/""$model""/{x=1}x&&/iBoot[.]/{print;exit}" BuildManifest.plist | grep '<string>' | cut -d\> -f2 | cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" ibot.dec

        echo "[*] Patching and signing iBoot"
        "$dir"/iBoot64Patcher ibot.dec ibot.patched

        if [[ "$deviceid" == iPhone9,[1-4] ]]; then
            "$dir"/iBootpatch2 --t8010 ibot.patched ibot.patched2
        else
            "$dir"/iBootpatch2 --t8015 ibot.patched ibot.patched2
        fi

        if [ "$os" = 'Linux' ]; then
            sed -i 's/\/\kernelcache/\/\kernelcachd/g' ibot.patched2
        else
            LC_ALL=C sed -i.bak -e 's/s\/\kernelcache/s\/\kernelcachd/g' ibot.patched2
            rm *.bak
        fi

        cd ..
        "$dir"/img4 -i work/ibot.patched2 -o boot-"$deviceid"/ibot.img4 -M blobs/"$deviceid"-"$version".der -A -T ibss

        touch boot-"$deviceid"/.payload
    else
        echo "[*] Downloading BuildManifest"
        "$dir"/pzb -g BuildManifest.plist "$ipswurl"

        echo "[*] Downloading and decrypting iBSS"
        "$dir"/pzb -g "$(awk "/""$model""/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' | cut -d\> -f2 | cut -d\< -f1)" "$ipswurl"
        "$dir"/gaster decrypt "$(awk "/""$model""/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' | cut -d\> -f2 | cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" iBSS.dec
        
        echo "[*] Downloading and decrypting iBoot"
        "$dir"/pzb -g "$(awk "/""$model""/{x=1}x&&/iBoot[.]/{print;exit}" BuildManifest.plist | grep '<string>' | cut -d\> -f2 | cut -d\< -f1)" "$ipswurl"
        "$dir"/gaster decrypt "$(awk "/""$model""/{x=1}x&&/iBoot[.]/{print;exit}" BuildManifest.plist | grep '<string>' | cut -d\> -f2 | cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" ibot.dec

        echo "[*] Patching and signing iBSS/iBoot"
        "$dir"/iBoot64Patcher iBSS.dec iBSS.patched
        if [ "$semi_tethered" = "1" ]; then
            if [ "$serial" = "1" ]; then
                "$dir"/iBoot64Patcher ibot.dec ibot.patched -b "serial=3 rd=$fs" -l
            else
                "$dir"/iBoot64Patcher ibot.dec ibot.patched -b "-v rd=$fs" -l
            fi
        else
            if [ "$serial" = "1" ]; then
                "$dir"/iBoot64Patcher ibot.dec ibot.patched -b "serial=3" -f
            else
                "$dir"/iBoot64Patcher ibot.dec ibot.patched -b "-v" -f
            fi
        fi

        if [ "$os" = 'Linux' ]; then
            sed -i 's/\/\kernelcache/\/\kernelcachd/g' ibot.patched
        else
            LC_ALL=C sed -i.bak -e 's/s\/\kernelcache/s\/\kernelcachd/g' ibot.patched
            rm *.bak
        fi
        cd ..
        "$dir"/img4 -i work/iBSS.patched -o boot-"$deviceid"/iBSS.img4 -M blobs/"$deviceid"-"$version".der -A -T ibss
        "$dir"/img4 -i work/ibot.patched -o boot-"$deviceid"/ibot.img4 -M blobs/"$deviceid"-"$version".der -A -T `if [[ "$cpid" == *"0x801"* ]]; then echo "ibss"; else echo "ibec"; fi`

        touch boot-"$deviceid"/.local
    fi
fi

# ============
# Boot device
# ============

sleep 2
_pwn
_reset
echo "[*] Booting device"
if [[ "$deviceid" == iPhone9,[1-4] ]] || [[ "$deviceid" == "iPhone10,"* ]]; then
    sleep 1
    "$dir"/irecovery -f boot-"$deviceid"/ibot.img4
    sleep 3
    "$dir"/irecovery -c "dorwx"
    sleep 2
    if [[ "$deviceid" == iPhone9,[1-4] ]]; then
        "$dir"/irecovery -f other/payload/payload_t8010.bin
    else
        "$dir"/irecovery -f other/payload/payload_t8015.bin
    fi
    sleep 3
    "$dir"/irecovery -c "go"
    sleep 1
    "$dir"/irecovery -c "go xargs $boot_args"
    sleep 1
    "$dir"/irecovery -c "go xfb"
    sleep 1
    "$dir"/irecovery -c "go boot $fs"
else
    if [[ "$cpid" == *"0x801"* ]]; then
        sleep 1
        "$dir"/irecovery -f boot-"$deviceid"/ibot.img4
    else
        sleep 1
        "$dir"/irecovery -f boot-"$deviceid"/iBSS.img4
        sleep 4
        "$dir"/irecovery -f boot-"$deviceid"/ibot.img4
    fi

    if [ -z "$semi_tethered" ]; then
       sleep 2
       "$dir"/irecovery -c fsboot
    fi
fi

if [ -d "logs" ]; then
    cd logs
     mv "$log" SUCCESS_${log}
    cd ..
fi

rm -rf work rdwork
echo ""
echo "Done!"
echo "The device should now boot to iOS"
echo "When you unlock the device, it will respring about 30 seconds after"
echo "If this is your first time jailbreaking, open the new palera1n app, then press Install"
echo "Otherwise, press Do All in the settings section of the app"
echo "If you have any issues, please first check the COMMONISSUES.md document for common issues"
if [ "$china" != "1" ]; then
	echo "If that list doesn't solve your issue, join the Discord server and ask for help: https://dsc.gg/palera1n"
fi
echo "Enjoy!"

} 2>&1 | tee logs/${log}

popd &> /dev/null
