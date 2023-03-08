#!/usr/bin/env bash

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
echo "INSTALLING DEPENDENCIES required for applera1n..."
echo ""

#Part 1
export PATH=/usr/local/bin:$PATH
which brew > /dev/null
if [ $? -ne 0 ]; then
    # Check for Homebrew, install if we don't have it
    if test ! $(which brew); then
        echo "Installing homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo ''
    fi
fi

echo Enter your Mac login password:
sudo -v

sudo rm -rf dependencies
sudo mkdir dependencies
cd dependencies

echo "If Xcode launches... INSTALL IT!!!"
xcode-select --install
echo "Xcode done."

echo " "
echo Install the Command Line Tools if prompted.
echo If you see an xcode error ignore it.
echo " "

brew install libusb

echo "Running part 2 of dependencies..."
sleep 2

echo ""
echo ""
echo ""
echo "INSTALLING DEPENDENCIES PART 2..."
echo ""

# Check for sshpass, install if we don't have it
echo "Installing sshpass..."
brew install esolitos/ipa/sshpass
echo ''
# Check for iproxy, install if we don't have it
echo "Installing iproxy, ideviceinfo, ideviceenterrecovery..."
brew install libimobiledevice
echo ''

echo "Installing brew python..."
brew install python3
echo ""
# Install pyenv to control python versions on mac
echo "Installing pyenv..."
brew install pyenv
echo ""
echo "Also Installing Python 3.10 🐍..."
pyenv install 3.10
echo ""
echo "Installing tk for GUI..."
pip install tk
brew install python-tk@3.10
echo ""
echo "Installing pillow..."
pip3 install Pillow
echo ""
echo "Quarantine our files..."
sudo xattr -rd com.apple.quarantine ./
echo "Quarantined!"
echo ""
echo "Quarantine our files..."
sudo chmod 755 ./
echo "Quarantined!"
echo "FINISHED INSTALLING DEPENDECIES!!!"
echo ""
echo "DONE!!"
echo ""
cd /Users/iosexpert/Desktop/applera1n
echo ""
python3 applera1n.py
echo ""
exit 1
