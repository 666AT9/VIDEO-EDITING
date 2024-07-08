I_Icon = C:\Users\666AT9\Documents\AHK\MIDDLE MOUSE AND SCROLL BUG.png
IfExist, %I_Icon%
Menu, Tray, Icon, %I_Icon%
return

#IfWinActive ahk_exe Adobe Premiere Pro.exe
{
~MButton:: 
Send,{f12}{LButton Down}
KeyWait, MButton
Send, {LButton Up}{v}

Return
}

#IfWinActive ahk_exe Adobe Premiere Pro.exe
 
~LButton::
If WinActive("ahk_exe Adobe Premiere Pro.exe")
    DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, 11, UInt, 0) ; Slightly Faster then Windows default
Return
 
~LButton Up::
DllCall("SystemParametersInfo", UInt, 0x70, UInt, 0, UInt, MOUSE_NOW, UInt, 0)
If MOUSE_NOW != 10 ; Check if the speed is not default, adjust this as needed.
    DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, 10, UInt, 0) ; Default Windows 6 Ticks [10], adjust this as needed. 
Return

