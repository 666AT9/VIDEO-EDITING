I_Icon = C:\Users\666AT9\Documents\AHK\PLAYHEAD.png
IfExist, %I_Icon%
Menu, Tray, Icon, %I_Icon%
return

#IfWinActive ahk_exe Adobe Premiere Pro.exe
{
~LButton::/
}

