#Requires AutoHotkey v2.0
#HotIf WinActive("ahk_exe Adobe Premiere Pro.exe")
#SingleInstance Force

A_MaxHotkeysPerInterval := 120
ProcessSetPriority "H"
SendMode "Input"

; === Accelerated Scrolling Settings ===
tooltips := 0    ; Show scroll velocity as a tooltip while scrolling. 1 or 0
timeout := 700   ; The length of a scrolling session
boost := 110     ; Additional boost factor for long distance scrolling
limit := 50      ; Maximum scroll velocity

; Runtime variables
distance := 0
vmax := 1

; === Key Bindings ===
WheelUp::Scroll("WheelUp")
WheelDown::Scroll("WheelDown")
F11::{
    Suspend
    QuickToolTip("Script Suspended", 1000)
}
F12::{
    Quit()
}

; === Timeline Zoom ===
^WheelUp::Send "{Ctrl down}{Shift down}{WheelUp}{Shift up}{Ctrl up}"    ; Zoom in
^WheelDown::Send "{Ctrl down}{Shift down}{WheelDown}{Shift up}{Ctrl up}" ; Zoom out

; === Accelerated Scrolling Function ===
Scroll(direction) {
    global distance, vmax, timeout, boost, limit, tooltips
    
    t := A_TimeSincePriorHotkey
    if (A_PriorHotkey = direction && t < timeout) {
        distance++
        
        ; Calculate acceleration factor using a 1/x curve
        v := (t < 80 && t > 1) ? (250.0 / t) - 1 : 1
        
        ; Apply boost
        if (boost > 1 && distance > boost) {
            if (v > vmax)
                vmax := v
            else
                v := vmax
            v *= distance / boost
        }
        
        ; Validate
        v := (v > 1) ? ((v > limit) ? limit : Floor(v)) : 1
        
        if (v > 1 && tooltips)
            QuickToolTip("×" v, timeout)
        
        MouseClick direction,,, v
    } else {
        ; Reset session variables
        distance := 0
        vmax := 1
        MouseClick direction
    }
}

; === Exit Function ===
Quit() {
    QuickToolTip("Exiting Accelerated Scrolling...", 1000)
    Sleep 1000
    ExitApp
}

; === Tooltip Function ===
QuickToolTip(text, delay) {
    ToolTip text
    SetTimer () => ToolTip(), -delay
}