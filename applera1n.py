# import system functions
import os
import time
import re
import tkinter as tk
from tkinter import *
from tkinter import messagebox
from tkinter.simpledialog import askstring
from tkinter.messagebox import showinfo
from subprocess import run
import subprocess
# load images in Tkinter python
from PIL import ImageTk, Image
# web
import webbrowser
# sounds
# from pygame import mixer

# Designed and developed by @hackt1vator


# cd the folder
script_path = os.path.dirname(os.path.abspath(__file__))

os.chdir(script_path)


# frame settings
root = tk.Tk()
frame = tk.Frame(root, width="500", height="250")
frame.pack(fill=BOTH,expand=True)
#tk.Entry(root).pack(fill='x')

# uses current directory to load the image file for the icon
root.iconphoto(False, tk.PhotoImage(file='apple.gif'))

LAST_CONNECTED_UDID = ""
LAST_CONNECTED_IOS_VER = ""



#whats your os
system_name = os.name

if system_name == "nt":
    os_name = "Windows"
elif system_name == "darwin":
    os_name = "Darwin"  # macOS
elif system_name == "posix":
    if os.uname().sysname == "Linux":
        os_name = "Linux"
    else:
        os_name = "POSIX-compatible system"  # z.B. FreeBSD, OpenBSD, etc.
else:
    os_name = "unknown"





def showDFUMessage():
    messagebox.showinfo("Step 1","Put your iDevice into DFU mode.\n\nClick Ok once its ready in DFU mode to proceed.")
    



def clear():



    folders_to_delete = ['./palera1n/blobs', './palera1n/work']
    for folder in os.listdir('./palera1n'):
        if folder.startswith('boot'):
            folders_to_delete.append(f'./palera1n/{folder}')

    for folder in folders_to_delete:
        if os.path.exists(folder):
            os.system(f'rm -rf {folder}')
            print(f'{folder} deleted.')

    messagebox.showinfo("Done","applera1n files cleared")


def quitProgram():
    print("Exiting...")
    os.system("exit")
    
def opentwitter():
    webbrowser.open('https://www.twitter.com/hackt1vator', new=2)
    
def startbypass():
    global LAST_CONNECTED_UDID, LAST_CONNECTED_IOS_VER
    # step 1 technically
    print("Searching for connected device...")
    os.system("idevicepair unpair")
    os.system("idevicepair pair")
    if system_name == "posix":
        os.system("ideviceinfo > lastdevice.txt")
    elif system_name == "darwin":
        os.system("./device/Darwin/ideviceinfo > ./device/Darwin/lastdevice.txt")

    time.sleep(2)

    if system_name == "posix":
        f = open("lastdevice.txt", "r")
    elif system_name == "darwin":
        f = open("./device/Darwin/lastdevice.txt", "r")
    fileData = f.read()
    f.close()

    if ("ERROR:" in fileData):
        # no device was detected, so retry user!
        print("ERROR: No device found!")

        messagebox.showinfo("No device detected! 0x404", "Try disconnecting and reconnecting your device.")
    else:
        # we definitely have something connected...

        # find the UDID
        start = 'UniqueDeviceID: '
        end = 'UseRaptorCerts:'
        s = str(fileData)

        foundData = s[s.find(start) + len(start):s.rfind(end)]
        UDID = str(foundData)
        LAST_CONNECTED_UDID = str(UDID)

        # find the iOS
        # we definitely have something connected...
        start2 = 'ProductVersion: '
        end2 = 'ProductionSOC:'
        s2 = str(fileData)

        foundData2 = s2[s.find(start2) + len(start2):s2.rfind(end2)]
        deviceIOS = str(foundData2)
        LAST_CONNECTED_IOS_VER = str(deviceIOS)

        if (len(UDID) > 38):
            # stop automatic detection
            timerStatus = 0

            print("Found UDID: " + LAST_CONNECTED_UDID)
            messagebox.showinfo("iDevice is detected!", "Found iDevice on iOS " + LAST_CONNECTED_IOS_VER)
        #            cbeginExploit10["state"] = "normal"
        #            cbeginExploit2["state"] = "normal"

        # messagebox.showinfo("Ready to begin!","We are ready to start jailbreak!")

        # cbeginExploit10["state"] = "normal"

        else:
            print("Couldn't find your device")
            messagebox.showinfo("Somethings missing! 0x405", "Try disconnecting and reconnecting your device.")

    #check if theres a valid string to continue to reversing jb
    if(len(LAST_CONNECTED_IOS_VER) < 2):
        showinfo('jailbreak Failed', 'Give me a valid iOS version.')
    else:
        showinfo('Ready to Jailbreak...', 'Hi, iOS '+str(LAST_CONNECTED_IOS_VER)+'. \n\nWe will now bypass iOS '+str(LAST_CONNECTED_IOS_VER)+' Semi-Tethered.')
        print("Starting jailbreak...")
        os.system("idevicepair unpair")
        os.system("idevicepair pair")
        os.system(f"cd ./palera1n/ && ./palera1n.sh --tweaks --semi-tethered {LAST_CONNECTED_IOS_VER}")

        print("Device is bypassed!\n")
        showinfo('bypass Success!', 'Device is now bypassed!')


def enterRecMode():
    if system_name == "posix":
        os.system("./device/Linux/enterrecovery.sh")
    elif system_name == "darwin":
        os.system("./device/Darwin/enterrecovery.sh")
    print("Kicking device into recovery mode...")

def exitRecMode():
    if system_name == "posix":
        os.system("./device/Linux/exitrecovery.sh")
    elif system_name == "darwin":
        os.system("./device/Darwin/exitrecovery.sh")
    print("Kicking device out recovery mode...")
    


root.title('applera1n bypass - Made by @hackt1vator')
frame.pack()

#set image and resize it
#img2 = Image.open("racoon.png")
#frame2 = PhotoImage(file=imagefilename, format="gif -index 2")
#NewIMGSize2 = img2.resize((120,120), Image.ANTIALIAS)
#new_image2 = ImageTk.PhotoImage(NewIMGSize2)
#label = Label(frame, image = new_image2)
#label.place(x=235, y=10)

#BIG title on program
mainText = Label(root, text="applera1n bypass ",font=('Helveticabold', 24))
mainText.place(x=140, y=70)

#label
my_label2 = Label(frame,
                 text = "Designed to run on devices on ios 15-16.3")
my_label2.place(x=130, y=130)

#label
my_label3 = Label(frame,
                 text = "ver 1.5")
my_label3.place(x=10, y=220)



cButton1 = tk.Button(frame,
                   text="start bypass",
                   command=startbypass,
                   state="normal")
cButton1.place(x=180, y=160)
cButton2 = tk.Button(frame,
                   text="clear",
                   command=clear,
                   state="normal")
cButton2.place(x=295, y=160)
cButton3 = tk.Button(frame,
                   text="enter recovery",
                   command=enterRecMode,
                   state="normal")
cButton3.place(x=10, y=10)
cButton4 = tk.Button(frame,
                 text="exit recovery",
                 command=exitRecMode,
                 state="normal")
cButton4.place(x=380, y=10)
#Create a Label to display the link
link = Label(root, text="Made this tool @hackt1vator",font=('Helveticabold', 12), cursor="hand2")
link.place(x=165, y=220)
link.bind("<Button-1>", lambda e:
callback("https://twitter.com/hackt1vator"))

cbeginExploit2 = tk.Button(frame,
                   text="Twitter!",
                   command=opentwitter,
                   state="normal")
cbeginExploit2.place(x=380, y=210)

root.geometry("500x250")

root.resizable(False, False)

root.eval('tk::PlaceWindow . center')


root.mainloop()

