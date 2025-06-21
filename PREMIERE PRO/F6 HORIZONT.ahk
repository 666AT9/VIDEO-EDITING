#Requires AutoHotkey v2.0
#SingleInstance Force

; Only activate when Premiere Pro is the active window
#HotIf WinActive("ahk_exe Adobe Premiere Pro.exe")

*F6::
{
    ; Get precise initial mouse position
    CoordMode "Mouse", "Screen"
    MouseGetPos(, &startY)  ; We only need Y position
    
    ; Get screen dimensions
    screenWidth := SysGet(0)  ; Get full screen width
    
    ; Simulate left mouse button down
    Click "Down"
    
    ; Set horizontal restriction (full screen width, 1 pixel height)
    ClipCursor(1, 0, startY, screenWidth, startY+1)
    
    ; Wait for F6 to be released
    KeyWait "F6"
    
    ; Release left mouse button
    Click "Up"
    
    ; Release cursor restriction
    ClipCursor(0)
    return
}

; Function to restrict cursor movement
ClipCursor(restrict := 0, left := 0, top := 0, right := 0, bottom := 0) {
    static RECT := Buffer(16)
    if restrict {
        NumPut("Int", left, RECT, 0)
        NumPut("Int", top, RECT, 4)
        NumPut("Int", right, RECT, 8)
        NumPut("Int", bottom, RECT, 12)
        DllCall("ClipCursor", "Ptr", RECT)
    } else {
        DllCall("ClipCursor", "Ptr", 0)
    }
}

#HotIf  ; Reset context sensitivity