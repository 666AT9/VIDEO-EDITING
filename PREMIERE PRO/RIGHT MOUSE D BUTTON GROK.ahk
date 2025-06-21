#Requires AutoHotkey v2.0
#SingleInstance Force

; === GLOBAL CONFIGURATION ===
CoordMode "Mouse", "Screen"        ; Mouse coordinates relative to entire screen
CoordMode "Pixel", "Screen"        ; Pixel coordinates relative to entire screen
A_MaxHotkeysPerInterval := 120     ; Allow more hotkeys per interval for responsiveness
ProcessSetPriority "H"             ; Set script to high priority for better performance
SendMode "Input"                   ; Use fast, reliable input simulation

; === PLAYBACK CONTROL VARIABLES ===
global isPlaybackActive := true    ; Toggle to enable/disable the "d" key behavior
global isPlaying := false          ; Tracks playback state (false = paused, true = 2x speed)
global dWasLast := false           ; Tracks if "d" was last pressed before "s"
global leftMouseClicked := false   ; Tracks left mouse button state
global rightMouseClicked := false  ; Tracks right mouse button state
global shiftSpacePressed := false  ; Tracks if Shift+Space was pressed

; === TIMELINE SCROLLING VARIABLES ===
global timelineColors := []        ; Array of calibrated timeline colors
global isCalibrated := false       ; Tracks if calibration is complete
global colorCount := 0             ; Number of saved colors
global isCalibrating := false      ; Tracks calibration state
global playheadEnabled := true     ; Toggle for playhead functionality
playheadKey := "\"                 ; Key to move playhead
deselectKey := "{Esc}"             ; Key to deselect clips

; === PREMIERE PRO CONTEXT ===
#HotIf WinActive("ahk_exe Adobe Premiere Pro.exe")  ; All hotkeys below are Premiere-specific

; === TIMELINE SCROLLING AND CALIBRATION ===
^+v::CalibrateTimelineColors()     ; Ctrl+Shift+V to calibrate colors

^+t::{                             ; Ctrl+Shift+T to toggle playhead
    global playheadEnabled := !playheadEnabled
    MouseGetPos &x, &y
    ToolTip (playheadEnabled ? "Playhead On" : "Playhead Off"), x + 20, y + 20
    SetTimer () => ToolTip(), -1000
}

RButton::{
    ; Track right mouse button state for playback control
    global rightMouseClicked := true
    
    MouseGetPos &mouseX, &mouseY
    WinGetPos &winX, &winY, &winWidth, &winHeight, "ahk_exe Adobe Premiere Pro.exe"
    
    ; Check if mouse is outside Premiere Pro window
    if (mouseX < winX || mouseX > (winX + winWidth) || mouseY < winY || mouseY > (winY + winHeight)) {
        Send "{RButton down}"      ; Pass through right-click outside Premiere
        KeyWait "RButton"
        Send "{RButton up}"
        return
    }
    
    ; Check for timeline scrolling
    if (!isCalibrated) {
        MsgBox "Please calibrate at least one timeline color by pressing Ctrl+Shift+V over the timeline!"
        return
    }
    
    if (playheadEnabled && IsOverTimeline(mouseX, mouseY) && IsTimelinePosition(mouseX, mouseY)) {
        SetKeyDelay -1             ; Fast key repeat
        Send "+4"
        Send "+3"                  ; Focus timeline
        Sleep 1                    ; Short delay for focus
        while (GetKeyState("RButton", "P")) {
            Send playheadKey       ; Move playhead
            Sleep 1                ; Minimal delay for smoothness
            MouseGetPos &newX, &newY
            if (Abs(newX - mouseX) > 5) {
                mouseX := newX
            }
        }
        Sleep 10                   ; Delay after scrolling
        return
    }
    
    ; Normal right-click if not on timeline
    Send "{RButton down}"
    KeyWait "RButton"
    Send "{RButton up}"
}

RButton Up::{
    global rightMouseClicked, isPlaying, dWasLast
    if (rightMouseClicked && isPlaying) {
        MouseGetPos &mouseX, &mouseY
        WinGetPos &winX, &winY, &winWidth, &winHeight, "ahk_exe Adobe Premiere Pro.exe"
        timelineTop := winY + 300
        timelineBottom := winY + winHeight - 100
        if (mouseY > timelineTop && mouseY < timelineBottom) {
            isPlaying := false
            dWasLast := false
        }
        rightMouseClicked := false
    }
}

; === PLAYBACK CONTROL HOTKEYS ===
^!f::{                            ; Toggle playback mode (Ctrl+Alt+F)
    global isPlaybackActive
    isPlaybackActive := !isPlaybackActive
    SetTimer(UpdateTooltip, 10)    ; Start updating tooltip position
    SetTimer(RemoveTooltip, -500)  ; Remove tooltip after 0.5 seconds
}

+Space::{                         ; Shift+Space to send to Premiere, then disable playback
    global isPlaybackActive, shiftSpacePressed
    WinActivate "ahk_exe Adobe Premiere Pro.exe"
    SendEvent "{Shift down}"
    Sleep 5
    SendEvent "{Space down}"
    Sleep 5
    SendEvent "{Space up}"
    SendEvent "{Shift up}"
    Sleep 100
    isPlaybackActive := false
    shiftSpacePressed := true
}

SC020::{                          ; "D" key to toggle between 2x speed and pause
    global isPlaybackActive, isPlaying, dWasLast
    if (!isPlaybackActive) {
        Send "{d}"
        return
    }
    if (isPlaying) {
        Send "{s}"
        isPlaying := false
    } else {
        Send "="
        Sleep 50
        Send "="
        isPlaying := true
    }
    dWasLast := true
}

SC01F::{                          ; "S" key to pause
    global isPlaybackActive, isPlaying, dWasLast
    if (!isPlaybackActive) {
        Send "{s}"
        return
    }
    Send "{s}"
    isPlaying := false
    if (dWasLast) {
        dWasLast := false
    }
}

~LButton::{                       ; Left mouse button down
    global leftMouseClicked, isPlaybackActive, shiftSpacePressed
    leftMouseClicked := true
    if (shiftSpacePressed) {       ; Enable playback only if Shift+Space was pressed
        isPlaybackActive := true
        shiftSpacePressed := false
    }
}

~LButton Up::{                    ; Left mouse button up
    global leftMouseClicked, isPlaying, dWasLast
    if (leftMouseClicked && isPlaying) {
        MouseGetPos &mouseX, &mouseY
        WinGetPos &winX, &winY, &winWidth, &winHeight, "ahk_exe Adobe Premiere Pro.exe"
        timelineTop := winY + 300
        timelineBottom := winY + winHeight - 100
        if (mouseY > timelineTop && mouseY < timelineBottom) {
            isPlaying := false
            dWasLast := false
        }
        leftMouseClicked := false
    }
}

; === FUNCTIONS ===
UpdateTooltip() {
    global isPlaybackActive
    MouseGetPos &mouseX, &mouseY
    ToolTip("Playback: " . (isPlaybackActive ? "Active" : "Blocked"), mouseX + 20, mouseY + 20)
}

RemoveTooltip() {
    ToolTip() ; Clear tooltip
    SetTimer(UpdateTooltip, 0) ; Stop updating tooltip position
}

LoadColorsFromFile() {
    filePath := A_ScriptDir "\TIMELINE_COLORS.txt"
    if (FileExist(filePath)) {
        content := FileRead(filePath)
        colors := StrSplit(content, "`n", "`r")
        for color in colors {
            if (color != "") {
                timelineColors.Push(color)
                global colorCount := colorCount + 1
            }
        }
        if (colorCount > 0)
            global isCalibrated := true
    }
}

SaveColorsToFile() {
    filePath := A_ScriptDir "\TIMELINE_COLORS.txt"
    try FileDelete(filePath)
    file := FileOpen(filePath, "w")
    for color in timelineColors {
        file.WriteLine(color)
    }
    file.Close()
}

CalibrateTimelineColors() {
    result := MsgBox("Click OK, then move the mouse over a timeline area and press Enter to add a color. Cancel to abort.",, 4)
    if (result = "No")
        return
    global isCalibrating := true
    Hotkey "Enter", CaptureColor, "On"
    SetTimer CheckCalibrationTimeout, -10000
}

CaptureColor(*) {
    global isCalibrating := false
    Hotkey "Enter", "Off"
    MouseGetPos &sampleX, &sampleY
    newColor := PixelGetColor(sampleX, sampleY, "RGB")
    for color in timelineColors {
        if (IsColorSimilar(newColor, color)) {
            MsgBox "This color (" newColor ") is already close to an existing one!"
            return
        }
    }
    timelineColors.Push(newColor)
    global colorCount := colorCount + 1
    SaveColorsToFile()
    MsgBox "Color " newColor " added. Total: " colorCount
    global isCalibrated := true
}

CheckCalibrationTimeout() {
    global isCalibrating
    if (isCalibrating) {
        isCalibrating := false
        try Hotkey "Enter", "Off" ; Ensure hotkey is disabled safely
        MsgBox "Calibration timed out! (Enter not detected within 10 seconds)"
    }
}

IsOverTimeline(mouseX, mouseY) {
    currentColor := PixelGetColor(mouseX, mouseY, "RGB")
    for color in timelineColors {
        if (IsColorSimilar(currentColor, color, 50)) {
            return true
        }
    }
    return false
}

IsTimelinePosition(mouseX, mouseY) {
    WinGetPos &winX, &winY, &winWidth, &winHeight, "ahk_exe Adobe Premiere Pro.exe"
    timelineThreshold := winY + (winHeight * 0.6)
    return (mouseY > timelineThreshold)
}

IsColorSimilar(color1, color2, tolerance := 50) {
    r1 := (color1 >> 16) & 0xFF
    g1 := (color1 >> 8) & 0xFF
    b1 := color1 & 0xFF
    r2 := (color2 >> 16) & 0xFF
    g2 := (color2 >> 8) & 0xFF
    b2 := color2 & 0xFF
    return (Abs(r1 - r2) <= tolerance && Abs(g1 - g2) <= tolerance && Abs(b1 - b2) <= tolerance)
}

; Call LoadColorsFromFile at startup
LoadColorsFromFile()