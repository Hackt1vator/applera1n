#!/usr/bin/env bash

echo 'THIS MAY TAKE SOME TIME TO INSTALL. JUST WAIT...'
echo 'If you have a slow Mac computer, I do not recommend it!!!'
sudo -v  
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
echo ''
sleep 3
echo 'You may need to enter your mac password...'
sudo xattr -rd com.apple.quarantine ./*
sudo xattr -d com.apple.quarantine ./*
sudo chmod 755 ./*
#uncomment these 2 lines if you're trying to install brew but 
#its failing with a git error for whatever reason
#rm -rf /opt/homebrew
#rm -rf /etc/homebrew

#Uninstalls brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"

echo "Installing homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

git -C "/usr/local/Homebrew" remote set-url origin https://github.com/Homebrew/brew

rm -rf "/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core"
brew tap homebrew/core
brew update
brew update-reset

brew install libusb
brew install libtool
brew install automake
brew install curl

echo "Running part 2 of dependencies..."
sleep 2

echo ""
echo ""
echo ""
echo "INSTALLING DEPENDENCIES 2..."
echo ""

echo "Installing sshpass..."
brew install esolitos/ipa/sshpass
echo "Installing libmobiledevice..."
brew install libimobiledevice
echo "Installing brew python..."
brew install python@3.10
echo ""
echo "Installing tk for GUI..."
pip3 install tk
pip install tk
brew install python-tk@3.10
echo ""
echo "Installing pillow for GUI..."
pip3 install Pillow
pip install Pillow
echo ""
echo "FINISHED INSTALLING DEPENDECIES!!!"
echo ""
echo "DONE!!!"
echo ""
exit 1
