#HotIf WinActive("ahk_exe Adobe Premiere Pro.exe")
~MButton::{
    Send "{f12}{LButton Down}"
    KeyWait "MButton"
    Send "{LButton Up}{v}"
}
#HotIf  ; Reset context sensitivity