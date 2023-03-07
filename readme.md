# applera1n
<h1 align="center">
    <p>icloud bypass for ios 15-16(only macos)</p>


![alt text](https://github.com/Laurin226/applera1n_bypass/blob/main/demoing.png)

</h1>
<h3 align="center">This is a modded version of    <strong><a href="https://github.com/palera1n/palera1n">Palera1n jailbreak</a></strong></h3>
<p align="center">
    <strong><a href="CHANGELOG.md">Change Log</a></strong>
    •
    <strong><a href="https://twitter.com/laurin2261">Twitter</a></strong>
<h3 align="center">This is a no signal bypass</h3>
<h3 align="center">This gui was made with <strong><a href="https://github.com/bartektenDev/Python3MacApp-LearnerTemplate">Python3MacApp LearnerTemplate</a></strong> from @ios_euphoria </h3>
<h3 align="center">On A11 and A10 devices don´t set a passcode after bypass</h3>
<h3 align="center">Here you can download the Palera1n loader ipa: <strong><a href="https://nightly.link/palera1n/loader/workflows/build/main/palera1n.zip">Palera1n.ipa</a></strong></h3>
<h3 align="center">Here you can donate the Palera1n developers: <strong><a href="https://patreon.com/palera1n">Patreon</a></strong></h3>
<h3 align="center">How does it work: It boots the device with multiple patches required. On first run, it'll boot a ramdisk which dumps your onboard blob, creates a fakefs (if using semi tethered), installs the loader app, and patches your kernel. </h3>
<h3 align"center">Step 1. Run this in terminal:
cd DRAG_AND_DROP_applera1n_folder_here
<h3 align"center">Step 2. run sudo chmod 755 ./*
<h3 align"center">Step 3. Last to launch the app, run this in terminal:
python3 applera1n.py

# Credits

Python3MacApp LearnerTemplate creator: 
<strong><a href="https://github.com/bartektenDev">ios_euphoria</a></strong>

Original palera1n credits:
- [Nathan](https://github.com/verygenericname)
    - The ramdisk that dumps blobs, installs pogo to tips app, and duplicates rootfs is a slimmed down version of [SSHRD_Script](https://github.com/verygenericname/SSHRD_Script)
    - For modified [restored_external](https://github.com/verygenericname/sshrd_SSHRD_Script)
    - Also helped Mineek getting the kernel up and running and with the patches
    - Helping with adding multiple device support
    - Fixing issues relating to camera.. etc by switching to fsboot
    - [iBoot64Patcher fork](https://github.com/verygenericname/iBoot64Patcher)
- [Mineek](https://github.com/mineek)
    - For the patching and booting commands
    - Adding tweak support
    - For patchfinders for RELEASE kernels
    - [Kernel15Patcher](https://github.com/mineek/PongoOS/tree/iOS15/checkra1n/Kernel15Patcher)
    - [Kernel64Patcher](https://github.com/mineek/Kernel64Patcher)
- [Amy](https://github.com/elihwyma) for the [Pogo](https://github.com/elihwyma/Pogo) app
- [checkra1n](https://github.com/checkra1n) for the base of the kpf
- [nyuszika7h](https://github.com/nyuszika7h) for the script to help get into DFU
- [the Procursus Team](https://github.com/ProcursusTeam) for the amazing [bootstrap](https://github.com/ProcursusTeam/Procursus)
- [F121](https://github.com/F121Live) for helping test
- [m1sta](https://github.com/m1stadev) for [pyimg4](https://github.com/m1stadev/PyIMG4)
- [tihmstar](https://github.com/tihmstar) for [pzb](https://github.com/tihmstar/partialZipBrowser)/original [iBoot64Patcher](https://github.com/tihmstar/iBoot64Patcher)/original [liboffsetfinder64](https://github.com/tihmstar/liboffsetfinder64)/[img4tool](https://github.com/tihmstar/img4tool)
- [xerub](https://github.com/xerub) for [img4lib](https://github.com/xerub/img4lib) and [restored_external](https://github.com/xerub/sshrd) in the ramdisk
- [Cryptic](https://github.com/Cryptiiiic) for [iBoot64Patcher](https://github.com/Cryptiiiic/iBoot64Patcher) fork, and [liboffsetfinder64](https://github.com/Cryptiiiic/liboffsetfinder64) fork
- [libimobiledevice](https://github.com/libimobiledevice) for several tools used in this project (irecovery, ideviceenterrecovery etc), and [nikias](https://github.com/nikias) for keeping it up to date
- [Nick Chan](https://github.com/asdfugil) general help with patches.
- [Sam Bingner](https://github.com/sbingner) for [Substitute](https://github.com/sbingner/substitute)
- [Serena](https://github.com/SerenaKit) for helping with boot ramdisk.
</p>
