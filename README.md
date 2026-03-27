# keepTheDarnScreenOn
Short powershell script that operates as a taskbar icon and basically presses shift+F15 every 60 seconds. Made to keep the screen on in environments that do not allow any third party executables.
## Usage
start-hidden.ps1 script will launch the script hidden so that there are no visible powershell or terminal windows. in order to make it more easy to launch it is advisable to create a lnk (shirtcut) file.
to configure the lnk file just use the powershell exe like so:
```
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File "C:\Users\lukautaa\Desktop\keepawake\start-hidden.ps1"
```
you may want to use normal.ico file to make the shortcut icon pretty.
