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

# Designed and developed by @laurin2261

# frame settings
root = tk.Tk()
frame = tk.Frame(root, width="500", height="250")
frame.pack(fill=BOTH,expand=True)
#tk.Entry(root).pack(fill='x')

# uses current directory to load the image file for the icon
root.iconphoto(False, tk.PhotoImage(file='apple.gif'))

LAST_CONNECTED_UDID = ""
LAST_CONNECTED_IOS_VER = ""


def showDFUMessage():
    messagebox.showinfo("Step 1","Put your iDevice into DFU mode.\n\nClick Ok once its ready in DFU mode to proceed.")
    
def startpalera1n():
    global LAST_CONNECTED_UDID, LAST_CONNECTED_IOS_VER

    root.iconphoto(False, tk.PhotoImage(file='checkra1nicon.png'))
    messagebox.showinfo("Enter DFU Mode",
                        "Get ready...\n\nFirst, press Ok button.\n\nThen, put the device into DFU mode. The jailbreak will automatically complete afterwards.")

    print("Loading jb script...")
    os.system("./checkra1n/checkra1n -c -V -E")
    print("Ran jb script.\n")
    # show message to jb
    messagebox.showinfo("Jailbreak Ran", "Jailbreak done!\n\nNow bypass")
    root.iconphoto(False, tk.PhotoImage(file='checkra1nicon.png'))


def showDFUMessage():
    messagebox.showinfo("Step 1", "Put your iDevice into DFU mode.\n\nClick Ok once its ready in DFU mode to proceed.")


def startpalera1n():

    os.system("palera1n -cf")



def quitProgram():
    print("Exiting...")
    os.system("exit")
    
def opentwitter():
    webbrowser.open('https://www.twitter.com/laurin2261', new=2)
    
def startbypass():
    global LAST_CONNECTED_UDID, LAST_CONNECTED_IOS_VER


    # iOSVER = str(LAST_CONNECTED_IOS_VER)

    os.system("palera1n -cf")

    print("Device is jailbroken!\n")
    showinfo('jailbreak Success!', 'Device is now jailbroken!')

    # device in normal mode. boot into recovery

    # show dfu message
    # clean files for new build
    print("Cleaning old files...")
    os.system("bash ./SSHRD_Script/sshrd.sh clean")
    print("Cleaned!\n")
    messagebox.showinfo("DFU Mode", "Please put the device into DFU mode.\n\nThen click Ok to begin the bypass!")
    # build IPSW
    print("Building SSHRD...")
    os.system("bash ./SSHRD_Script/sshrd.sh 15.6")  # +str(LAST_CONNECTED_IOS_VER))
    print("Built SSHRD!\n")
    # boot IPSW
    print("Booting SSHRD...")
    os.system("bash ./SSHRD_Script/sshrd.sh boot")  # +str(LAST_CONNECTED_IOS_VER))
    print("Booted SSHRD!\n")
    # wait 10 seconds
    time.sleep(10)
    # execute darkra1n clouds
    print("Loading bypass script...")
    os.system("bash ./bypass.sh")
    print("iCloud bypass complete!\n")
    # show message to jb
    messagebox.showinfo("bypass Done!", "Now the device will jailbreak again!")


    print("Starting jailbreak...")
    os.system("palera1n -f")

    print("Device is bypassed!\n")
    showinfo('bypass Success!', 'Device is now bypassed!')

def bypassnojailbreak():



    # device in normal mode. boot into recovery

    # show dfu message
    # clean files for new build
    print("Cleaning old files...")
    os.system("bash ./SSHRD_Script/sshrd.sh clean")
    print("Cleaned!\n")
    messagebox.showinfo("DFU Mode", "Please put the device into DFU mode.\n\nThen click Ok to begin the bypass!")
    # build IPSW
    print("Building SSHRD...")
    os.system("bash ./SSHRD_Script/sshrd.sh 15.6")  # +str(LAST_CONNECTED_IOS_VER))
    print("Built SSHRD!\n")
    # boot IPSW
    print("Booting SSHRD...")
    os.system("bash ./SSHRD_Script/sshrd.sh boot")  # +str(LAST_CONNECTED_IOS_VER))
    print("Booted SSHRD!\n")
    # wait 10 seconds
    time.sleep(10)
    # execute darkra1n clouds
    print("Loading bypass script...")
    os.system("bash ./bypass.sh")
    print("iCloud bypass complete!\n")
    # show message to jb
    messagebox.showinfo("bypass Done!", "bypass Done!\n\nFinal step, Re-Jailbreak the iOS device!")
    
def enterRecMode():
    print("Kicking device into recovery mode...")
    os.system("./recovery/enterrecovery.sh")
    
def exitRecMode():
    print("Kicking device out recovery mode...")
    os.system("./recovery/exitrecovery.sh")

root.title('applera1n bypass - Made by @laurin2261')
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
                 text = "Designed to run on devices on ios 15-16")
my_label2.place(x=130, y=130)

#label
my_label3 = Label(frame,
                 text = "ver 1.1")
my_label3.place(x=10, y=220)


cButton2 = tk.Button(frame,
                   text="Run Palera1n",
                   command=startpalera1n,
                   state="normal")
cButton2.place(x=180, y=160)
cButton3 = tk.Button(frame,
                   text="start bypass",
                   command=startbypass,
                   state="normal")
cButton3.place(x=307, y=160)
cButton6 = tk.Button(frame,
                   text="bypass(no Jailbreak)",
                   command=bypassnojailbreak,
                   state="normal")
cButton6.place(x=200, y=10)
#Create a Label to display the link
link = Label(root, text="Made this tool @laurin2261",font=('Helveticabold', 12), cursor="hand2")
link.place(x=165, y=220)
link.bind("<Button-1>", lambda e:
callback("https://twitter.com/laurin2261"))

cbeginExploit2 = tk.Button(frame,
                   text="Twitter!",
                   command=opentwitter,
                   state="normal")
cbeginExploit2.place(x=380, y=210)

root.geometry("500x250")

root.resizable(False, False)

root.eval('tk::PlaceWindow . center')

#make message box popup on load start
#messagebox.showinfo("Hello!","Device must be jailbroken before running Make it Sn0w!")
#song = AudioSegment.from_mp3("./extras/euphoria_scripts/success.mp3")
#messagebox.showinfo("Warning!","Make sure you have wiped the locked iDevice with iTunes using DFU mode before you begin...")

root.mainloop()

