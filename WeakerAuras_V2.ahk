#Requires AutoHotkey v2.0

; Skill Timer Overlay v2.0
; Configurable on-screen skill icons with countdown timers

SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")

global timerXOffset := 0
global timerYOffset := 64

;================================================================
;                         Configuration
;================================================================

global CONFIG := {
    POEWindowTitle: "Path of Exile",
    MaxSkills: 5,
    TimerFontSize: 20,
    TimerFontColor: "FFFFFF",
    TimerBackgroundColor: "000000",
    IconSize: 64,
}

;================================================================
;                         Utility Functions
;================================================================

Range(start, stop?) {
    if !IsSet(stop) {
        stop := start
        start := 1
    }
    arr := []
    Loop stop - start + 1
        arr.Push(start + A_Index - 1)
    return arr
}

InitializeArray(array, size, defaultValue) {
    Loop size {
        array.Push(defaultValue)
    }
    return array
}

;[edited to make it x64/x32 compatible]
;Scrollable Gui - Proof of Concept - Scripts and Functions - AutoHotkey Community
;https://autohotkey.com/board/topic/26033-scrollable-gui-proof-of-concept/#entry168174
; MK_SHIFT = 0x0004, WM_MOUSEWHEEL = 0x020A, WM_MOUSEHWHEEL = 0x020E, WM_NCHITTEST = 0x0084
OnMessage(0x0115, OnScroll) ; WM_VSCROLL
OnMessage(0x0114, OnScroll) ; WM_HSCROLL
OnMessage(0x020A, OnWheel)  ; WM_MOUSEWHEEL
; ======================================================================================================================
ScrollGui_Size(GuiObj, MinMax, Width, Height) {
   If (MinMax != 1)
      UpdateScrollBars(GuiObj)
}
; ======================================================================================================================
ScrollGui_Close(*) {
   ExitApp
}
; ======================================================================================================================
UpdateScrollBars(GuiObj) {
   ; SIF_RANGE = 0x1, SIF_PAGE = 0x2, SIF_DISABLENOSCROLL = 0x8, SB_HORZ = 0, SB_VERT = 1
   ; Calculate scrolling area.
   WinGetClientPos( , , &GuiW, &GuiH, GuiObj.Hwnd)
   L := T := 2147483647   ; Left, Top
   R := B := -2147483648  ; Right, Bottom
   For CtrlHwnd In WinGetControlsHwnd(GuiObj.Hwnd) {
      ControlGetPos(&CX, &CY, &CW, &CH, CtrlHwnd)
      L := Min(CX, L)
      T := Min(CY, T)
      R := Max(CX + CW, R)
      B := Max(CY + CH, B)
   }
   L -= 8, T -= 8
   R += 8, B += 8
   ScrW := R - L ; scroll width
   ScrH := B - T ; scroll height
   ; Initialize SCROLLINFO.
   SI := Buffer(28, 0)
   NumPut("UInt", 28, "UInt", 3, SI, 0) ; cbSize , fMask: SIF_RANGE | SIF_PAGE
   ; Update horizontal scroll bar.
   NumPut("Int", ScrW, "Int", GuiW, SI, 12) ; nMax , nPage
   DllCall("SetScrollInfo", "Ptr", GuiObj.Hwnd, "Int", 0, "Ptr", SI, "Int", 1) ; SB_HORZ
   ; Update vertical scroll bar.
   ; NumPut("UInt", SIF_RANGE | SIF_PAGE | SIF_DISABLENOSCROLL, SI, 4) ; fMask
   NumPut("Int", ScrH, "UInt", GuiH,  SI, 12) ; nMax , nPage
   DllCall("SetScrollInfo", "Ptr", GuiObj.Hwnd, "Int", 1, "Ptr", SI, "Int", 1) ; SB_VERT
   ; Scroll if necessary
   X := (L < 0) && (R < GuiW) ? Min(Abs(L), GuiW - R) : 0
   Y := (T < 0) && (B < GuiH) ? Min(Abs(T), GuiH - B) : 0
   If (X || Y)
      DllCall("ScrollWindow", "Ptr", GuiObj.Hwnd, "Int", X, "Int", Y, "Ptr", 0, "Ptr", 0)
}
; ======================================================================================================================
OnWheel(W, L, M, H) {
   If !(HWND := WinExist()) || GuiCtrlFromHwnd(H)
      Return
   HT := DllCall("SendMessage", "Ptr", HWND, "UInt", 0x0084, "Ptr", 0, "Ptr", l) ; WM_NCHITTEST = 0x0084
   If (HT = 6) || (HT = 7) { ; HTHSCROLL = 6, HTVSCROLL = 7
      SB := (W & 0x80000000) ? 1 : 0 ; SB_LINEDOWN = 1, SB_LINEUP = 0
      SM := (HT = 6) ? 0x0114 : 0x0115 ;  WM_HSCROLL = 0x0114, WM_VSCROLL = 0x0115
      OnScroll(SB, 0, SM, HWND)
      Return 0
   }
}
; ======================================================================================================================
OnScroll(WP, LP, M, H) {
   Static SCROLL_STEP := 10
   If !(LP = 0) ; not sent by a standard scrollbar
      Return
   Bar := (M = 0x0115) ; SB_HORZ=0, SB_VERT=1
   SI := Buffer(28, 0)
   NumPut("UInt", 28, "UInt", 0x17, SI) ; cbSize, fMask: SIF_ALL
   If !DllCall("GetScrollInfo", "Ptr", H, "Int", Bar, "Ptr", SI)
      Return
   RC := Buffer(16, 0)
   DllCall("GetClientRect", "Ptr", H, "Ptr", RC)
   NewPos := NumGet(SI, 20, "Int") ; nPos
   MinPos := NumGet(SI,  8, "Int") ; nMin
   MaxPos := NumGet(SI, 12, "Int") ; nMax
   Switch (WP & 0xFFFF) {
      Case 0: NewPos -= SCROLL_STEP ; SB_LINEUP
      Case 1: NewPos += SCROLL_STEP ; SB_LINEDOWN
      Case 2: NewPos -= NumGet(RC, 12, "Int") - SCROLL_STEP ; SB_PAGEUP
      Case 3: NewPos += NumGet(RC, 12, "Int") - SCROLL_STEP ; SB_PAGEDOWN
      Case 4, 5: NewPos := WP >> 16 ; SB_THUMBTRACK, SB_THUMBPOSITION
      Case 6: NewPos := MinPos ; SB_TOP
      Case 7: NewPos := MaxPos ; SB_BOTTOM
      Default: Return
   }
   MaxPos -= NumGet(SI, 16, "Int") ; nPage
   NewPos := Min(NewPos, MaxPos)
   NewPos := Max(MinPos, NewPos)
   OldPos := NumGet(SI, 20, "Int") ; nPos
   X := (Bar = 0) ? OldPos - NewPos : 0
   Y := (Bar = 1) ? OldPos - NewPos : 0
   If (X || Y) {
      ; Scroll contents of window and invalidate uncovered area.
      DllCall("ScrollWindow", "Ptr", H, "Int", X, "Int", Y, "Ptr", 0, "Ptr", 0)
      ; Update scroll bar.
      NumPut("Int", NewPos, SI, 20) ; nPos
      DllCall("SetScrollInfo", "ptr", H, "Int", Bar, "Ptr", SI, "Int", 1)
   }
}

;================================================================
;                         Global Variables
;================================================================

global Skills := Map()
global SkillTimerStartTimes := []
InitializeArray(SkillTimerStartTimes, CONFIG.MaxSkills, 0)
global TimerGUIs := Map()
global IconGUIs := Map()
global MainGUI := 0
global SkillControls := Map()
global PickingPosition := 0
global PreviewIconGUI := 0
global PreviewTimerGUI := 0
global AllSkillPreviewIcons := Map()
global AllSkillPreviewTimers := Map()
global SkillIconPreviews := Map()

;================================================================
;                         Main Functions
;================================================================

Main() {
    LoadSettings()
    CreateMainGUI()
    SetupHotkeys()
}

CreateMainGUI() {
    global MainGUI, SkillControls
    
    MainGUI := Gui("+AlwaysOnTop +ToolWindow +Resize +0x300000", "Skill Timer Config")
    MainGUI.BackColor := "FFFFFF"
    MainGUI.OnEvent("Size", ScrollGui_Size)
    MainGUI.OnEvent("Close", ScrollGui_Close)
    
    ; Add skill configuration sections
    yOffset := 10
    for i in Range(1, CONFIG.MaxSkills) {
        yOffset := AddSkillConfigSection(i, yOffset)
    }
    
    ; Control buttons
    MainGUI.Add("Button", "x10 y" yOffset " w80 h30", "Save").OnEvent("Click", SaveSettings)
    MainGUI.Add("Button", "x100 y" yOffset " w80 h30", "Refresh").OnEvent("Click", RefreshSettings)
    
    MainGUI.OnEvent("Close", (*) => ExitApp())
    MainGUI.Show("w500 h" A_ScreenHeight*0.5)
    
    UpdateUIFromSettings()
}

AddSkillConfigSection(skillIndex, yOffset) {
    global MainGUI, SkillControls
    
    sectionY := yOffset
    
    ; Skill header
    MainGUI.Add("Text", "x10 y" sectionY " w380 h20", "Skill " skillIndex).SetFont("bold")
    sectionY += 25
    
    ; Enabled checkbox
    SkillControls["enabled" skillIndex] := MainGUI.Add("CheckBox", "x10 y" sectionY " w80 h20", "Enabled")
    sectionY += 25
    
    ; Icon file
    MainGUI.Add("Text", "x10 y" sectionY " w60 h20", "Icon:")
    SkillControls["icon" skillIndex] := MainGUI.Add("Edit", "x80 y" sectionY " w200 h20")
    SkillControls["icon" skillIndex].OnEvent("Change", UpdateIconPreview.Bind(skillIndex))
    MainGUI.Add("Button", "x290 y" sectionY " w80 h20", "Browse").OnEvent("Click", BrowseIcon.Bind(skillIndex))
    sectionY += 25
    SkillIconPreviews[skillIndex] := MainGUI.Add("Pic", "x80 y" sectionY " w" CONFIG.IconSize " h" CONFIG.IconSize)
    sectionY += CONFIG.IconSize + 10
    
    ; Hotkey
    MainGUI.Add("Text", "x10 y" sectionY " w60 h20", "Hotkey:")
    SkillControls["hotkey" skillIndex] := MainGUI.Add("Edit", "x80 y" sectionY " w100 h20")
    sectionY += 25
    
    ; Duration
    MainGUI.Add("Text", "x10 y" sectionY " w60 h20", "Duration:")
    SkillControls["duration" skillIndex] := MainGUI.Add("Edit", "x80 y" sectionY " w100 h20", "10.0")
    MainGUI.Add("Text", "x190 y" sectionY " w40 h20", "sec")
    sectionY += 25
    
    ; Position X
    MainGUI.Add("Text", "x10 y" sectionY " w60 h20", "Pos X:")
    SkillControls["posX" skillIndex] := MainGUI.Add("Edit", "x80 y" sectionY " w100 h20", "100")
    sectionY += 25
    
    ; Position Y
    MainGUI.Add("Text", "x10 y" sectionY " w60 h20", "Pos Y:")
    SkillControls["posY" skillIndex] := MainGUI.Add("Edit", "x80 y" sectionY " w100 h20", "100")
    MainGUI.Add("Button", "x190 y" sectionY " w80 h20", "Pick Pos").OnEvent("Click", PickPosition.Bind(skillIndex))
    sectionY += 25
    
    return sectionY
}

BrowseIcon(skillIndex, *) {
    selectedFile := FileSelect("1", A_WorkingDir "\resources\", "Image files (*.png; *.jpg; *.bmp)", "*.png")
    if selectedFile {
        SkillControls["icon" skillIndex].Value := selectedFile
        UpdateIconPreview(skillIndex)
    }
}

PickPosition(skillIndex, *) {
    global PickingPosition, MainGUI, AllSkillPreviewIcons, AllSkillPreviewTimers, PreviewIconGUI, PreviewTimerGUI
    PickingPosition := skillIndex
    MainGUI.Hide()
    ToolTip("Click anywhere on screen to set position for Skill " skillIndex)
    
    MouseGetPos(&x, &y)
    
    ; Create preview GUIs for all existing skills (fixed at their positions)
    for i in Range(1, CONFIG.MaxSkills) {
        if !SkillControls.Has("icon" i) {
            continue
        }
        
        iconPath := SkillControls["icon" i].Value
        posX := SkillControls["posX" i].Value
        posY := SkillControls["posY" i].Value
        
        ; Skip if no icon or position not set
        if !iconPath || !FileExist(iconPath) || !posX || !posY {
            continue
        }
        
        ; Create icon preview at fixed position
        previewIconGUI := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000")
        previewIconGUI.MarginX := 0
        previewIconGUI.MarginY := 0
        if iconPath {
            previewIconGUI.Add("Pic", "w" CONFIG.IconSize " h" CONFIG.IconSize, iconPath)
        } else {
            previewIconGUI.Add("Text", "w" CONFIG.IconSize " h" CONFIG.IconSize " Center", "Icon")
        }
        previewIconGUI.Show("x" posX " y" posY " NoActivate")
        WinSetTransparent(150, "ahk_id " previewIconGUI.Hwnd)
        AllSkillPreviewIcons[i] := previewIconGUI
        
        ; Create timer preview at fixed position
        previewTimerGUI := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000")
        previewTimerGUI.MarginX := 0
        previewTimerGUI.MarginY := 0
        previewTimerGUI.BackColor := CONFIG.TimerBackgroundColor
        durationText := SkillControls["duration" i].Value
        previewTimerGUI.Add("Text", "w64 h30 Center c" CONFIG.TimerFontColor, durationText).SetFont("s" CONFIG.TimerFontSize " bold")
        previewTimerGUI.Show("x" posX " y" (posY + timerYOffset) " NoActivate")
        WinSetTransparent(150, "ahk_id " previewTimerGUI.Hwnd)
        AllSkillPreviewTimers[i] := previewTimerGUI
    }
    
    ; Create preview GUIs for the skill being positioned (will follow cursor)
    iconPath := SkillControls["icon" skillIndex].Value
    if !iconPath || !FileExist(iconPath) {
        iconPath := ""
    }
    PreviewIconGUI := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000")
    PreviewIconGUI.MarginX := 0
    PreviewIconGUI.MarginY := 0
    if iconPath {
        PreviewIconGUI.Add("Pic", "w" CONFIG.IconSize " h" CONFIG.IconSize, iconPath)
    } else {
        PreviewIconGUI.Add("Text", "w" CONFIG.IconSize " h" CONFIG.IconSize " Center", "Icon")
    }
    PreviewIconGUI.Show("x" x " y" y " NoActivate")
    WinSetTransparent(200, "ahk_id " PreviewIconGUI.Hwnd)
    
    PreviewTimerGUI := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000")
    PreviewTimerGUI.MarginX := 0
    PreviewTimerGUI.MarginY := 0
    PreviewTimerGUI.BackColor := CONFIG.TimerBackgroundColor
    durationText := SkillControls["duration" skillIndex].Value
    PreviewTimerGUI.Add("Text", "w64 h30 Center c" CONFIG.TimerFontColor, durationText).SetFont("s" CONFIG.TimerFontSize " bold")
    PreviewTimerGUI.Show("x" x " y" (y + timerYOffset) " NoActivate")
    WinSetTransparent(200, "ahk_id " PreviewTimerGUI.Hwnd)
    
    SetTimer(CheckClick, 10)
}

CheckClick() {
    global PickingPosition, MainGUI, AllSkillPreviewIcons, AllSkillPreviewTimers, PreviewIconGUI, PreviewTimerGUI
    if GetKeyState("LButton", "P") {
        MouseGetPos(&x, &y)
        SkillControls["posX" PickingPosition].Value := x
        SkillControls["posY" PickingPosition].Value := y
        SetTimer(CheckClick, 0)
        ToolTip()
        MainGUI.Show()
        ; Hide and destroy all previews
        for i, previewIcon in AllSkillPreviewIcons {
            if previewIcon {
                previewIcon.Destroy()
            }
        }
        for i, previewTimer in AllSkillPreviewTimers {
            if previewTimer {
                previewTimer.Destroy()
            }
        }
        if PreviewIconGUI {
            PreviewIconGUI.Destroy()
            PreviewIconGUI := 0
        }
        if PreviewTimerGUI {
            PreviewTimerGUI.Destroy()
            PreviewTimerGUI := 0
        }
        AllSkillPreviewIcons := Map()
        AllSkillPreviewTimers := Map()
        PickingPosition := 0
    } else {
        ; Update only the positioned skill's preview to follow cursor
        MouseGetPos(&x, &y)
        if PreviewIconGUI {
            PreviewIconGUI.Show("x" x " y" y " NoActivate")
        }
        if PreviewTimerGUI {
            PreviewTimerGUI.Show("x" x " y" (y + timerYOffset) " NoActivate")
        }
    }
}

UpdateIconPreview(skillIndex, *) {
    global SkillIconPreviews
    iconPath := SkillControls["icon" skillIndex].Value
    if iconPath && FileExist(iconPath) {
        SkillIconPreviews[skillIndex].Value := iconPath
    } else {
        ; Clear or set to blank
        try {
            SkillIconPreviews[skillIndex].Value := ""
        }
    }
}

;================================================================
;                         Timer Functions
;================================================================

ShowSkillTimer(skillIndex, duration, posX, posY) {
    ; Show icon only if not already visible
    if !IconGUIs.Has(skillIndex) {
        CreateSkillIconGUI(skillIndex, posX, posY)
        SkillTimerStartTimes[skillIndex] := A_TickCount
        SetTimer(CountdownTimer.Bind(skillIndex, duration, true), 100)
    } else {
        IconGUIs[skillIndex].Show("NoActivate Autosize")
        TimerGUIs[skillIndex].Show("NoActivate Autosize")
        SkillTimerStartTimes[skillIndex] := A_TickCount
    }
}

CreateSkillIconGUI(skillIndex, x, y) {
    iconPath := Skills[skillIndex].icon
    
    if !IconGUIs.Has(skillIndex) {
        iconGUI := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000")
        iconGUI.MarginX := 0
        iconGUI.MarginY := 0
        iconGUI.Add("Pic", "w" CONFIG.IconSize " h" CONFIG.IconSize, iconPath)
        iconGUI.BackColor := CONFIG.TimerBackgroundColor
        IconGUIs[skillIndex] := iconGUI
    }
    
    IconGUIs[skillIndex].Show("x" x " y" y " NoActivate Autosize")
    WinSetTransparent(200, "ahk_id " IconGUIs[skillIndex].Hwnd)
}

CreateTimerGUI(skillIndex, text, x, y) {
    if !TimerGUIs.Has(skillIndex) {
        timerGUI := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000")
        timerGUI.MarginX := 0
        timerGUI.MarginY := 0
        timerGUI.BackColor := CONFIG.TimerBackgroundColor
        timerGUI.Add("Text", "w64 h30 Center c" CONFIG.TimerFontColor, text).SetFont("s" CONFIG.TimerFontSize " bold")
        TimerGUIs[skillIndex] := timerGUI
    }
    
    TimerGUIs[skillIndex].Show("x" x+timerXOffset " y" y+timerYOffset " NoActivate")
    WinSetTransparent(200, "ahk_id " TimerGUIs[skillIndex].Hwnd)
    for ctrl in TimerGUIs[skillIndex] {
        ctrl.Value := text
    }
}

CountdownTimer(skillIndex, totalDuration, isInitial) {
    elapsed := (A_TickCount - SkillTimerStartTimes[skillIndex]) / 1000
    remaining := Round(totalDuration - elapsed, 1)
    
    if !IsPOEActive() {
        HideSkillGUIs(skillIndex)
        return
    } else {
        if remaining <= 0 {
            HideSkillGUIs(skillIndex)
            return
        } else {
            ShowSkillGUIs(skillIndex)
        }
    }
    
    skill := Skills[skillIndex]
    if isInitial {
        CreateTimerGUI(skillIndex, remaining, skill.posX, skill.posY)
    }
}

HideSkillGUIs(skillIndex) {
    if IconGUIs.Has(skillIndex) {
        IconGUIs[skillIndex].Hide()
    }
    if TimerGUIs.Has(skillIndex) {
        TimerGUIs[skillIndex].Hide()
    }
}

ShowSkillGUIs(skillIndex) {
    if IconGUIs.Has(skillIndex) {
        IconGUIs[skillIndex].Show("NoActivate Autosize")
    }
    if TimerGUIs.Has(skillIndex) {
        TimerGUIs[skillIndex].Show("NoActivate Autosize")
    }
}

;================================================================
;                         Hotkey Functions
;================================================================

SetupHotkeys() {
    for skillIndex, skill in Skills {
        if skill.enabled && skill.hotkey {
            try {
                Hotkey("~" skill.hotkey, OnSkillHotkey.Bind(skillIndex))
            }
            catch Error as err {
                MsgBox("Invalid hotkey for Skill " skillIndex ": " skill.hotkey "`n`nError: " err.What)
            }
        }
    }
}

OnSkillHotkey(skillIndex, *) {
    if(!IsPOEActive()) {
        return
    }
    skill := Skills[skillIndex]
    if skill.enabled {
        ShowSkillTimer(skillIndex, skill.duration, skill.posX, skill.posY)
    }
}

;================================================================
;                         Settings Functions
;================================================================

LoadSettings() {
    settingsFile := A_WorkingDir "\settings.ini"
    
    if !FileExist(settingsFile) {
        CreateDefaultSettings()
        return
    }
    
    for i in Range(1, CONFIG.MaxSkills) {
        section := "Skill" i
        
        Skills[i] := {
            enabled: IniRead(settingsFile, section, "enabled", false),
            icon: IniRead(settingsFile, section, "icon", ""),
            hotkey: IniRead(settingsFile, section, "hotkey", ""),
            duration: IniRead(settingsFile, section, "duration", 10.0),
            posX: IniRead(settingsFile, section, "posX", 100),
            posY: IniRead(settingsFile, section, "posY", 100)
        }

        ;SetTimer(CountdownTimer.Bind(i, Skills[i].duration, true), Off)

        if(IconGUIs.has(i)) {
            IconGUIs[i].Destroy()
            IconGUIs.Delete(i)
        }
        if(TimerGUIs.has(i)) {
            TimerGUIs[i].Destroy()
            TimerGUIs.Delete(i)
        }
    }
}

CreateDefaultSettings() {
    for i in Range(1, CONFIG.MaxSkills) {
        Skills[i] := {
            enabled: false,
            icon: "",
            hotkey: "",
            duration: 10.0,
            posX: 100 + (i-1) * 80,
            posY: 100
        }
    }
}

SaveSettings(*) {
    settingsFile := A_WorkingDir "\settings.ini"
    
    ; Update skills from UI
    for i in Range(1, CONFIG.MaxSkills) {
        Skills[i] := {
            enabled: SkillControls["enabled" i].Value,
            icon: SkillControls["icon" i].Value,
            hotkey: SkillControls["hotkey" i].Value,
            duration: SkillControls["duration" i].Value,
            posX: SkillControls["posX" i].Value,
            posY: SkillControls["posY" i].Value
        }
    }
    
    ; Save to file
    for i in Range(1, CONFIG.MaxSkills) {
        section := "Skill" i
        skill := Skills[i]
        
        IniWrite(skill.enabled, settingsFile, section, "enabled")
        IniWrite(skill.icon, settingsFile, section, "icon")
        IniWrite(skill.hotkey, settingsFile, section, "hotkey")
        IniWrite(skill.duration, settingsFile, section, "duration")
        IniWrite(skill.posX, settingsFile, section, "posX")
        IniWrite(skill.posY, settingsFile, section, "posY")
    }
    
    ; Re-setup hotkeys
    SetupHotkeys()
    
    MsgBox("Settings saved!")
}

UpdateUIFromSettings() {
    for i in Range(1, CONFIG.MaxSkills) {
        skill := Skills[i]
        SkillControls["enabled" i].Value := skill.enabled
        SkillControls["icon" i].Value := skill.icon
        UpdateIconPreview(i)
        SkillControls["hotkey" i].Value := skill.hotkey
        SkillControls["duration" i].Value := skill.duration
        SkillControls["posX" i].Value := skill.posX
        SkillControls["posY" i].Value := skill.posY
    }
}

RefreshSettings(*) {
    Reload()
}

;================================================================
;                         Utility Functions
;================================================================

IsPOEActive() {
    return WinActive(CONFIG.POEWindowTitle)
}

;================================================================
;                         Initialization
;================================================================

Main()