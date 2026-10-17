#Requires AutoHotkey v2.0
#SingleInstance Force
; Native UI: no Python, browser, or per-refresh child processes.
DataDir := A_Args.Length ? A_Args[1] : A_ScriptDir '\..\local-data'
DirCreate DataDir
Config := DataDir '\config.ini'
if !FileExist(Config) {
    MsgBox 'Run install.ps1 first, then edit the model profile.', 'LLM Tray setup'
    ExitApp
}
ProfileName := IniRead(Config,'ui','profile','llama')
if !RegExMatch(ProfileName,'^[A-Za-z0-9_-]+$')
    throw Error('Invalid profile filename.')
Profile := DataDir '\profiles\' ProfileName '.ini'
ModelName := IniRead(Profile,'model','name','Local model')
Endpoint := RTrim(IniRead(Profile,'model','endpoint','http://127.0.0.1:8080'),'/')
if !RegExMatch(Endpoint,'^http://(127\.0\.0\.1|localhost|\[::1\]):\d+$')
    throw Error('Use an explicit loopback HTTP port in the profile.')
Protocol := IniRead(Profile,'model','status','llama')
ExpectedModel := IniRead(Profile,'model','model_id','')
Shortcut := IniRead(Config,'ui','hotkey','^!l')
WarningLevel := Max(1,Min(99,Number(IniRead(Config,'ui','warning_percent',70))))
CriticalLevel := Max(WarningLevel+1,Min(100,Number(IniRead(Config,'ui','critical_percent',90))))
Pinned := !!Integer(IniRead(Config,'ui','pinned',0))
HoverEnabled := !!Integer(IniRead(Config,'ui','hover',1))
Notifications := !!Integer(IniRead(Config,'ui','notifications',1))
MetricKeys := [], MetricValues := Map(), MetricLabels := Map('vram','VRAM','ram','RAM','gpu','GPU'), Percent := Map('vram',-1,'ram',-1,'gpu',-1)
for key in StrSplit(IniRead(Config,'ui','metrics','vram,ram,gpu'),',') {
    key := Trim(key)
    if MetricLabels.Has(key) && !Has(MetricKeys,key)
        MetricKeys.Push(key)
}
ActionPid := 0, LastState := '', State := 'Checking', LastHover := 0, Visible := false, SettingsOpen := false
Dragging := false, StatusRequest := 0, StatusStarted := 0, ServerState := 'Checking'
MetricText := Map('ram','Unavailable','vram','Unavailable','gpu','Unavailable')
Nvml := 0, Device := 0
Palette := Map('green','86E3A7','amber','FFD07D','red','FF9A9E','muted','AABACB')
try {
    Nvml := DllCall('LoadLibrary','Str',A_WinDir '\System32\nvml.dll','Ptr')
    if !Nvml || DllCall(Nv('nvmlInit_v2'),'Cdecl UInt')
        throw Error('NVML unavailable')
    if DllCall(Nv('nvmlDeviceGetHandleByIndex_v2'),'UInt',Integer(IniRead(Config,'ui','gpu_index',0)),'Ptr*',&Device,'Cdecl UInt')
        throw Error('GPU unavailable')
} catch {
    Nvml := 0
}

PanelWidth := 490
Panel := Gui('+AlwaysOnTop -Caption +ToolWindow','LLM Tray - Model resources')
Panel.BackColor := '16202D'
Panel.SetFont('s9 cAABACB','Segoe UI')
Title := Panel.AddText('x16 y10 w330 h24 +0x100','LLM TRAY   /   ' PrettyHotkey(Shortcut))
Panel.SetFont('s12 cE8EFF7','Segoe Fluent Icons')
PinButton := Panel.AddText('x356 y7 w32 h28 Center',Chr(0xE718))
PinButton.OnEvent('Click',(*) => TogglePin())
Gear := Panel.AddText('x400 y7 w32 h28 Center',Chr(0xE713))
Gear.OnEvent('Click',(*) => OpenSettings())
CloseButton := Panel.AddText('x446 y7 w28 h28 Center',Chr(0xE711))
CloseButton.OnEvent('Click',(*) => HidePanel(true))
Panel.SetFont('s13 Bold c86E3A7','Segoe UI')
Power := Panel.AddText('x16 y41 w155 h29','● Checking')
Power.OnEvent('Click',(*) => Act('Toggle'))
Panel.SetFont('s9 Norm cAABACB')
Hint := Panel.AddText('x16 y78 w155 h32','Click to start / stop')
Hint.OnEvent('Click',(*) => Act('Toggle'))
for index,key in MetricKeys {
    x := 188 + (index-1)*96
    Panel.SetFont('s9 Norm cAABACB')
    Panel.AddText('x' x ' y42 w94 h18',MetricLabels[key])
    Panel.SetFont('s11 Bold c86E3A7')
    MetricValues[key] := Panel.AddText('x' x ' y64 w94 h26','—')
    Panel.SetFont('s8 Norm cAABACB')
    Panel.AddText('x' x ' y91 w94 h18', key='gpu' ? 'utilization' : 'used / total GiB')
}
Panel.SetFont('s9 Norm cAABACB')
Panel.AddText('x16 y120 w458 h20',ModelName)
Panel.OnEvent('Escape',(*) => HidePanel(true))
Panel.OnEvent('Close',(*) => HidePanel(true))
Panel.OnEvent('ContextMenu',(*) => A_TrayMenu.Show())
A_TrayMenu.Delete()
A_TrayMenu.Add('Open / pin panel',(*) => OpenPinned())
A_TrayMenu.Add('Unpin / hide panel',(*) => HidePanel(true))
A_TrayMenu.Add('Toggle model  ·  ' PrettyHotkey(Shortcut),(*) => Act('Toggle'))
A_TrayMenu.Add('Start / wake model',(*) => Act('Start'))
A_TrayMenu.Add('Stop / unload model',(*) => Act('Stop'))
A_TrayMenu.Add()
A_TrayMenu.Add('Settings…',(*) => OpenSettings())
A_TrayMenu.Add('Edit model profile',(*) => Run('notepad.exe ' Q(Profile)))
A_TrayMenu.Add('Open guide',(*) => Run('https://github.com/paras-lehana/llm-tray#readme'))
A_TrayMenu.Add('Reload configuration',(*) => SafeReload())
if IniRead(Config,'ui','connection_script','')!=''
    A_TrayMenu.Add('Reconnect remote access',(*) => StartConnections())
A_TrayMenu.Add()
A_TrayMenu.Add('Exit tray (leave model running)',(*) => ExitApp())
A_TrayMenu.Default := 'Open / pin panel'
A_TrayMenu.ClickCount := 2
try {
    if !CanRegisterHotkey(Shortcut)
        throw Error('Shortcut is unavailable')
    Hotkey Shortcut, (*) => Act('Toggle')
}
catch {
    A_TrayMenu.Rename('Toggle model  ·  ' PrettyHotkey(Shortcut),'Toggle model (shortcut unavailable)')
    Shortcut := ''
    Title.Text := 'LLM TRAY   /   Set a shortcut in Settings'
    Notify('Shortcut unavailable or already used. Choose another in Settings.',true)
}
Log('hotkey=' Shortcut)
OnMessage(0x404,TrayEvent)
OnMessage(0x201,PanelPointerDown)
OnMessage(0x231,PanelMoveStarted)
OnMessage(0x232,PanelMoveEnded)
OnExit Cleanup
PinButton.SetFont('c' (Pinned ? '86E3A7' : 'AABACB'))
if Pinned
    ShowPanel(true)
Refresh()
SetTimer Refresh, Max(1,Min(60,Number(IniRead(Config,'ui','refresh_seconds',3))))*1000
SetTimer HoverWatch, 100
SetTimer FinishAction, 500
SetTimer FinishStatusPoll, 50
if IniRead(Config,'ui','connection_script','')!=''
    SetTimer StartConnections,-1000

Has(values,value) {
    for v in values
        if v=value
            return true
    return false
}
Q(value) => '"' value '"'
PrettyHotkey(value) {
    labels := Map('^','Ctrl + ','!','Alt + ','+','Shift + ','#','Win + '), result := ''
    loop Parse,value
        result .= labels.Has(A_LoopField) ? labels[A_LoopField] : StrUpper(A_LoopField)
    return result
}
CanRegisterHotkey(value) {
    if !RegExMatch(value,'^([!^+#]+)(.+)$',&match)
        return false
    modifiers := 0, flags := Map('!',1,'^',2,'+',4,'#',8)
    loop Parse,match[1]
        modifiers |= flags[A_LoopField]
    virtualKey := GetKeyVK(match[2])
    if !virtualKey
        return false
    available := DllCall('RegisterHotKey','Ptr',A_ScriptHwnd,'Int',0x7FFD,'UInt',modifiers,'UInt',virtualKey)
    if available
        DllCall('UnregisterHotKey','Ptr',A_ScriptHwnd,'Int',0x7FFD)
    return available
}

Nv(name) {
    global Nvml
    proc := DllCall('GetProcAddress','Ptr',Nvml,'AStr',name,'Ptr')
    if !proc
        throw Error('NVML entry point missing')
    return proc
}
Color(percent) {
    global Palette,WarningLevel,CriticalLevel
    return percent<0 ? Palette['muted'] : Palette[percent>=CriticalLevel ? 'red' : percent>=WarningLevel ? 'amber' : 'green']
}
Notify(message,error:=false) {
    global Notifications
    if Notifications
        TrayTip(message,'LLM Tray',error ? 'Iconx Mute' : 'Iconi Mute')
}
Log(message) {
    global DataDir
    FileAppend FormatTime(,'yyyy-MM-dd HH:mm:ss') ' ' message '`n',DataDir '\tray.log','UTF-8'
}
TrayRect() {
    identity := Buffer(A_PtrSize=8 ? 40 : 28,0), rect := Buffer(16,0)
    NumPut('UInt',identity.Size,identity)
    NumPut('Ptr',A_ScriptHwnd,identity,A_PtrSize=8 ? 8 : 4)
    NumPut('UInt',0x404,identity,A_PtrSize=8 ? 16 : 8)
    if DllCall('shell32\Shell_NotifyIconGetRect','Ptr',identity,'Ptr',rect,'Int') != 0
        return false
    return [NumGet(rect,0,'Int'),NumGet(rect,4,'Int'),NumGet(rect,8,'Int'),NumGet(rect,12,'Int')]
}
WorkArea(x,y) {
    loop MonitorGetCount() {
        MonitorGet(A_Index,&l,&t,&r,&b)
        if x>=l && x<r && y>=t && y<b {
            MonitorGetWorkArea(A_Index,&l,&t,&r,&b)
            return [l,t,r,b]
        }
    }
    MonitorGetWorkArea(,&l,&t,&r,&b)
    return [l,t,r,b]
}
ShowPanel(saved:=false) {
    global Panel,Visible,Config,PanelWidth,LastHover
    CoordMode 'Mouse','Screen'
    MouseGetPos &mx,&my
    r := TrayRect(), scale := A_ScreenDPI/96
    if saved {
        x := Number(IniRead(Config,'position','x',-1)), y := Number(IniRead(Config,'position','y',-1))
    } else {
        x := -1, y := -1
    }
    if x=-1 && y=-1 {
        x := r ? r[3]-PanelWidth*scale : mx-PanelWidth*scale
        y := r ? r[2]-152*scale : my-152*scale
    }
    area := WorkArea(x,y)
    x := Max(area[1],Min(area[3]-PanelWidth*scale,x))
    y := Max(area[2],Min(area[4]-148*scale,y))
    Panel.Show('NA x' Round(x) ' y' Round(y) ' w' PanelWidth ' h148')
    Panel.GetPos(,,&w,&h)
    WinSetRegion('0-0 w' w ' h' h ' R16-16','ahk_id ' Panel.Hwnd)
    Visible := true, LastHover := A_TickCount
    Log('panel_show x=' x ' y=' y)
}
HidePanel(unpin:=false) {
    global Panel,Visible,Pinned,Config,PinButton
    if unpin {
        Pinned := false
        IniWrite 0,Config,'ui','pinned'
        PinButton.SetFont('cAABACB')
    }
    Panel.Hide(), Visible := false
    Log('panel_hide')
}
TogglePin() {
    global Pinned,Config,PinButton,Panel
    Pinned := !Pinned
    IniWrite Integer(Pinned),Config,'ui','pinned'
    PinButton.SetFont('c' (Pinned ? '86E3A7' : 'AABACB'))
    SavePosition()
    Log('pinned=' Pinned)
}
OpenPinned() {
    global Pinned,Visible
    if !Visible
        ShowPanel(true)
    if !Pinned
        TogglePin()
}
PanelPointerDown(wParam,lParam,msg,hwnd) {
    global Panel,Title,Dragging,Pinned,PinButton
    ; A Text Click fires on release. Start Windows' move loop on the initial
    ; button-down instead; exclude pin/settings/close and all model controls.
    if hwnd!=Title.Hwnd && !(hwnd=Panel.Hwnd && (lParam & 0xFFFF)<350*A_ScreenDPI/96 && ((lParam>>16)&0xFFFF)<34*A_ScreenDPI/96)
        return
    Dragging := true, Pinned := true
    PinButton.SetFont('c86E3A7')
    CoordMode 'Mouse','Screen'
    MouseGetPos &x,&y
    DllCall('ReleaseCapture')
    PostMessage 0xA1,2,((y & 0xFFFF)<<16)|(x & 0xFFFF),,'ahk_id ' Panel.Hwnd
    return 0
}
PanelMoveStarted(w,l,m,h) {
    global Panel,Dragging
    if h=Panel.Hwnd
        Dragging := true
}
PanelMoveEnded(w,l,m,h) {
    global Panel,Dragging
    if h=Panel.Hwnd {
        Dragging := false
        ; Never perform configuration writes in the native move loop.
        SetTimer PersistPanelMove,-1
    }
}
PersistPanelMove() {
    global Pinned,Config,Dragging
    if Dragging
        return
    IniWrite Integer(Pinned),Config,'ui','pinned'
    SavePosition()
    Refresh()
}
SavePosition() {
    global Panel,Config,Pinned
    if Pinned {
        Panel.GetPos(&x,&y)
        IniWrite x,Config,'position','x'
        IniWrite y,Config,'position','y'
    }
}
HoverWatch() {
    global Visible,Pinned,LastHover,Panel,SettingsOpen,HoverEnabled,Dragging
    if Dragging || (Visible && (Pinned || SettingsOpen))
        return
    CoordMode 'Mouse','Screen'
    MouseGetPos &x,&y
    r := TrayRect()
    if !Visible {
        if HoverEnabled && !SettingsOpen && r && x>=r[1] && x<=r[3] && y>=r[2] && y<=r[4] && IsOurTrayButton(r)
            ShowPanel()
        return
    }
    if Pinned || SettingsOpen
        return
    Panel.GetPos(&px,&py,&pw,&ph)
    if (x>=px-6 && x<=px+pw+6 && y>=py-6 && y<=py+ph+6) || (r && x>=r[1]-6 && x<=r[3]+6 && y>=r[2]-6 && y<=r[4]+6)
        LastHover := A_TickCount
    else if A_TickCount-LastHover>650
        HidePanel()
}
IsOurTrayButton(rect) {
    ; Hidden icons can report the overflow-chevron bounds. UI Automation checks
    ; the actual button name before showing; no panel on someone else's icon.
    static automation := ComObject('{FF48DBA4-60EF-4201-AA87-54103EEF594E}','{30CBE57D-D9D0-452A-AB13-7AC5AC4825EE}')
    element := 0, name := 0
    try {
        point := ((rect[2]+2)<<32) | ((rect[1]+2)&0xFFFFFFFF)
        ComCall(7,automation,'Int64',point,'Ptr*',&element)
        ComCall(23,element,'Ptr*',&name)
        return name && InStr(StrGet(name,'UTF-16'),'LLM Tray:')
    } catch {
        return false
    } finally {
        if name
            DllCall('oleaut32\SysFreeString','Ptr',name)
        if element
            ObjRelease(element)
    }
}
TrayEvent(wParam,lParam,msg,hwnd) {
    global HoverEnabled,Visible,LastHover,Pinned
    if hwnd!=A_ScriptHwnd
        return
    event := lParam & 0xFFFF
    if event=0x200 && HoverEnabled {
        LastHover := A_TickCount
        if !Visible
            SetTimer (*) => ShowPanel(),-1
    } else if event=0x202 {
        SetTimer OpenPinned,-1
        return 0
    } else if event=0x203 {
        return 0
    } else if event=1026 || event=1027 {
        Log('notification_event=' event)
    }
}

Refresh() {
    global Percent,MetricValues,Nvml,Device,Dragging,MetricText
    if Dragging
        return
    values := Map('ram','Unavailable','vram','Unavailable','gpu','Unavailable')
    for key in Percent
        Percent[key] := -1
    mem := Buffer(64,0)
    NumPut('UInt',64,mem)
    if DllCall('GlobalMemoryStatusEx','Ptr',mem) {
        total := NumGet(mem,8,'UInt64')/1073741824, used := total-NumGet(mem,16,'UInt64')/1073741824
        values['ram'] := Format('{:.1f} / {:.0f}',used,total), Percent['ram'] := 100*used/total
    }
    if Nvml {
        try {
            memory := Buffer(24,0), util := Buffer(8,0)
            if !DllCall(Nv('nvmlDeviceGetMemoryInfo'),'Ptr',Device,'Ptr',memory,'Cdecl UInt') {
                total := NumGet(memory,0,'UInt64')/1073741824, used := NumGet(memory,16,'UInt64')/1073741824
                values['vram'] := Format('{:.1f} / {:.0f}',used,total), Percent['vram'] := 100*used/total
            }
            if !DllCall(Nv('nvmlDeviceGetUtilizationRates'),'Ptr',Device,'Ptr',util,'Cdecl UInt') {
                Percent['gpu'] := NumGet(util,0,'UInt'), values['gpu'] := Percent['gpu'] '%'
            }
        }
    }
    for key,control in MetricValues {
        control.Text := values[key]
        control.SetFont('c' Color(Percent[key]))
    }
    MetricText := values
    StartStatusPoll()
    PaintStatus()
}
StartStatusPoll() {
    global StatusRequest,StatusStarted,ServerState,ActionPid,Endpoint,Protocol
    if ActionPid || StatusRequest
        return
    try {
        http := ComObject('WinHttp.WinHttpRequest.5.1')
        http.SetProxy(1) ; Loopback endpoints do not need proxy discovery.
        http.SetTimeouts(500,500,500,500)
        path := Protocol='llama' ? '/props' : Protocol='ollama' ? '/api/ps' : '/health'
        http.Open('GET',Endpoint path,true)
        StatusStarted := A_TickCount, StatusRequest := http
        http.Send()
    } catch {
        StatusRequest := 0, ServerState := 'Offline'
    }
}
FinishStatusPoll() {
    global StatusRequest,StatusStarted,ServerState,Protocol,ExpectedModel,Dragging
    if !StatusRequest || Dragging
        return
    next := 'Offline'
    try {
        http := StatusRequest
        ; Zero seconds is a nonblocking completion check, not a network wait.
        if !http.WaitForResponse(0) {
            if A_TickCount-StatusStarted<2000
                return
            http.Abort()
        } else if http.Status=200 {
            next := 'Ready'
            if Protocol='llama' {
                if ExpectedModel && (!RegExMatch(http.ResponseText,'"model_alias"\s*:\s*"([^"]+)"',&model) || model[1]!=ExpectedModel)
                    next := 'Other model'
                else if RegExMatch(http.ResponseText,'"is_sleeping"\s*:\s*true')
                    next := 'Sleeping'
            } else if Protocol='ollama' {
                escaped := RegExReplace(ExpectedModel,'[\\.*?+\[\]{}()|^$]','\$0')
                next := RegExMatch(http.ResponseText,'"(name|model)"\s*:\s*"' escaped '"') ? 'Ready' : 'Unloaded'
            }
        } else {
            next := http.Status=503 ? 'Loading' : 'Endpoint error'
        }
    }
    StatusRequest := 0, ServerState := next
    PaintStatus()
}
PaintStatus() {
    global MetricText,ActionPid,State,ServerState,LastState,Palette,Power,Hint,DataDir,Visible,Pinned,Dragging
    if Dragging
        return
    values := MetricText
    State := ActionPid ? 'Working' : ServerState
    shade := State='Ready' ? 'green' : State='Offline' || State='Unloaded' ? 'red' : 'amber'
    Power.Text := '● ' State
    Power.SetFont('c' Palette[shade])
    Hint.Text := State='Sleeping' ? 'Next message wakes me' : State='Working' ? 'Please wait…' : 'Click to start / stop'
    DrawTrayIcon(Palette[shade])
    A_IconTip := 'LLM Tray: ' State '`nVRAM ' values['vram'] ' GiB | RAM ' values['ram'] ' GiB | GPU ' values['gpu']
    if State!=LastState {
        Log('state=' State), LastState := State
    }
    telemetry := 'state=' State '`nvisible=' Integer(Visible) '`npinned=' Integer(Pinned)
    for key,value in values
        telemetry .= '`n' key '=' value
    IniWrite telemetry,DataDir '\telemetry.ini','live'
}

DrawTrayIcon(stateColor) {
    global MetricKeys,Percent
    ; Generate a 32px opaque icon in memory. AHK owns/destroys the final HICON.
    info := Buffer(40,0)
    NumPut('UInt',40,'Int',32,'Int',-32,'UShort',1,'UShort',32,info)
    pixels := 0
    bitmap := DllCall('gdi32\CreateDIBSection','Ptr',0,'Ptr',info,'UInt',0,'Ptr*',&pixels,'Ptr',0,'UInt',0,'Ptr')
    if !bitmap
        return
    loop 1024
        NumPut('UInt',0xFF16202D,pixels+(A_Index-1)*4)
    Rect(x,y,w,h,color) {
        loop h {
            row := A_Index-1
            loop w
                NumPut('UInt',0xFF000000|Integer('0x' color),pixels+((y+row)*32+x+A_Index-1)*4)
        }
    }
    Rect(2,1,12,3,'AABACB')
    Rect(2,4,5,2,'AABACB')
    loop 7 {
        y := A_Index-1
        loop 7 {
            x := A_Index-1
            if (x-3)**2+(y-3)**2<=10
                Rect(24+x,y,1,1,stateColor)
        }
    }
    letters := Map('vram',['101','101','101','101','010'],'ram',['110','101','110','101','101'],'gpu',['111','100','101','101','111'])
    for index,key in MetricKeys {
        y := 9+(index-1)*8
        for row,bits in letters[key] {
            loop 3
                if SubStr(bits,A_Index,1)='1'
                    Rect(2+A_Index-1,y+row-1,1,1,'AABACB')
        }
        Rect(8,y,22,5,'344254')
        if Percent[key]>=0
            Rect(8,y,Max(1,Round(22*Min(100,Percent[key])/100)),5,Color(Percent[key]))
        else
            Rect(8,y+2,6,1,'AABACB')
    }
    mask := DllCall('gdi32\CreateBitmap','Int',32,'Int',32,'UInt',1,'UInt',1,'Ptr',Buffer(128,0),'Ptr')
    iconInfo := Buffer(A_PtrSize=8 ? 32 : 20,0)
    NumPut('Int',1,iconInfo)
    NumPut('Ptr',mask,iconInfo,A_PtrSize=8 ? 16 : 12)
    NumPut('Ptr',bitmap,iconInfo,A_PtrSize=8 ? 24 : 16)
    icon := DllCall('CreateIconIndirect','Ptr',iconInfo,'Ptr')
    DllCall('gdi32\DeleteObject','Ptr',bitmap)
    DllCall('gdi32\DeleteObject','Ptr',mask)
    if icon
        TraySetIcon 'HICON:' icon,,true
}

Act(action) {
    global ActionPid,DataDir,ProfileName
    if ActionPid {
        Notify('A model action is already running.')
        return
    }
    result := DataDir '\action.ini'
    if FileExist(result)
        FileDelete result
    Run 'powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ' Q(A_ScriptDir '\control.ps1') ' -DataDir ' Q(DataDir) ' -Profile ' ProfileName ' -Action ' action,, 'Hide', &ActionPid
    Notify('Switching model state. The tray will update when ready.')
    Log('action=' action ' pid=' ActionPid)
    Refresh()
}
FinishAction() {
    global ActionPid,DataDir,Dragging
    if Dragging || !ActionPid || ProcessExist(ActionPid)
        return
    ActionPid := 0
    result := DataDir '\action.ini'
    status := IniRead(result,'result','status','error')
    message := IniRead(result,'result','message','No action result. Check the logs.')
    Notify(message,status='error')
    Log('result=' status ' ' message)
    Refresh()
}
SafeReload() {
    global ActionPid,DataDir
    if ActionPid {
        Notify('Wait for the current model action before reloading.',true)
        return
    }
    SavePosition()
    ; Native Reload discards script arguments. Preserve a custom data directory.
    Run Q(A_AhkPath) ' /restart ' Q(A_ScriptFullPath) ' ' Q(DataDir),,'Hide'
    ExitApp
}
StartConnections() {
    global Config
    script := IniRead(Config,'ui','connection_script','')
    if script && FileExist(script) && RegExMatch(script,'i)\.ps1$')
        Run 'powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ' Q(script),,'Hide'
}
OpenSettings() {
    global SettingsOpen,ActionPid,DataDir,Config,Shortcut,MetricKeys,ProfileName,HoverEnabled,Notifications,WarningLevel,CriticalLevel
    if SettingsOpen || ActionPid
        return
    SettingsOpen := true
    options := Gui('+AlwaysOnTop +ToolWindow','LLM Tray settings')
    options.SetFont('s10','Segoe UI')
    options.AddText('xm ym','Model profile')
    names := []
    Loop Files,DataDir '\profiles\*.ini'
        names.Push(SubStr(A_LoopFileName,1,-4))
    choice := options.AddDropDownList('xm w330',names)
    choice.Choose(ProfileName)
    options.AddText('xm y+14','Global shortcut (press your preferred keys)')
    shortcutInput := options.AddHotkey('xm w330',Shortcut)
    options.AddText('xm y+14','Show in tray + panel (order: edit config.ini)')
    checks := Map()
    for key in ['vram','ram','gpu']
        checks[key] := options.AddCheckBox('xm Checked' Integer(Has(MetricKeys,key)),StrUpper(key))
    hover := options.AddCheckBox('xm y+12 Checked' Integer(HoverEnabled),'Open panel when hovering over tray icon')
    notices := options.AddCheckBox('xm Checked' Integer(Notifications),'Show action notifications')
    options.AddText('xm y+12','Warning / critical usage (%)')
    warn := options.AddEdit('xm w80 Number',WarningLevel)
    critical := options.AddEdit('x+12 w80 Number',CriticalLevel)
    options.AddText('xm y+12 w350','Profiles contain your launcher and endpoint. Saving selects a profile; it never starts or stops a model.')
    edit := options.AddButton('xm y+12 w165','Edit selected profile')
    edit.OnEvent('Click',(*) => Run('notepad.exe ' Q(DataDir '\profiles\' choice.Text '.ini')))
    save := options.AddButton('x+12 w165 Default','Save settings')
    save.OnEvent('Click',SaveSettings)
    options.OnEvent('Close',CloseSettings)
    options.OnEvent('Escape',CloseSettings)
    options.Show()
    CloseSettings(*) {
        global SettingsOpen
        options.Destroy(), SettingsOpen := false
    }
    SaveSettings(*) {
        global Config,Shortcut,MetricKeys
        newKey := shortcutInput.Value
        if !newKey || !RegExMatch(newKey,'[!^+#]') {
            MsgBox 'Use at least one modifier (Ctrl, Alt or Shift) with a key.','Shortcut'
            return
        }
        if !IsNumber(warn.Value) || !IsNumber(critical.Value) || Number(warn.Value)<1 || Number(critical.Value)>100 || Number(warn.Value)>=Number(critical.Value) {
            MsgBox 'Use thresholds from 1–100; warning must be below critical.','Thresholds'
            return
        }
        try {
            if newKey!=Shortcut && !CanRegisterHotkey(newKey)
                throw Error('Shortcut is already in use')
            Hotkey newKey,(*) => Act('Toggle')
            if Shortcut && newKey!=Shortcut
                Hotkey Shortcut,'Off'
        } catch {
            MsgBox 'Windows could not register that shortcut. Choose another.','Shortcut'
            return
        }
        selected := ''
        ordered := MetricKeys.Clone()
        for key in ['vram','ram','gpu']
            if !Has(ordered,key)
                ordered.Push(key)
        for key in ordered
            if checks[key].Value
                selected .= (selected ? ',' : '') key
        IniWrite selected,Config,'ui','metrics'
        IniWrite newKey,Config,'ui','hotkey'
        IniWrite choice.Text,Config,'ui','profile'
        IniWrite hover.Value,Config,'ui','hover'
        IniWrite notices.Value,Config,'ui','notifications'
        IniWrite warn.Value,Config,'ui','warning_percent'
        IniWrite critical.Value,Config,'ui','critical_percent'
        CloseSettings()
        SafeReload()
    }
}
Cleanup(*) {
    global Nvml,StatusRequest
    try {
        if StatusRequest
            StatusRequest.Abort()
    }
    try SavePosition()
    try {
        if Nvml
            DllCall(Nv('nvmlShutdown'),'Cdecl UInt')
    }
}
