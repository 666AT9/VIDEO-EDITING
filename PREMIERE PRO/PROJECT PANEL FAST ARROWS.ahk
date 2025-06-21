#HotIf WinActive("ahk_exe Adobe Premiere Pro.exe")

    ; Next Clip (F4)
    F5:: {
        Send("1")            ; Focus Project Panel
        Sleep(15)            ; Tiny reliability delay
        Send("{Down}")       ; Select next clip
        Sleep(15)
        Send("+y")           ; Shift+Y (opens AND focuses Source Monitor)
    }

    ; Previous Clip (F5)
    F4:: {
        Send("1")            ; Focus Project Panel
        Sleep(15)
        Send("{Up}")         ; Select previous clip
        Sleep(15)
        Send("+y")           ; Shift+Y
    }

#HotIf