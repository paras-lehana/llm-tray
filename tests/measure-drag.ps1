# Explicit interactive regression check. Moves only the selected LLM Tray panel.
# Run on an unlocked desktop with the mouse idle; never part of unattended CI.
param(
    [Parameter(Mandatory=$true)][int]$TrayProcessId,
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [ValidateRange(3,30)][int]$Seconds=8,
    [switch]$UseVisiblePanel
)
$ErrorActionPreference='Stop'
$owner=Get-CimInstance Win32_Process -Filter "ProcessId=$TrayProcessId"
if(-not $owner -or $owner.Name -notlike 'AutoHotkey*.exe' -or $owner.CommandLine -notmatch 'LLMTray\.ahk') {
    throw 'Select an existing LLMTray.ahk process explicitly.'
}
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
public static class DragProbe {
    public delegate bool EnumProc(IntPtr h,IntPtr p);
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int L,T,R,B; }
    [StructLayout(LayoutKind.Sequential)] public struct Point { public int X,Y; }
    public class Sample { public double Ms; public int CursorX,CursorY,ActualCursorX,ActualCursorY,WindowX,WindowY; public double ErrorPx; public bool InputInterference; }
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p,IntPtr data);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
    [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
    [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int GetClassName(IntPtr h,StringBuilder s,int n);
    [DllImport("user32.dll")] static extern bool PostMessage(IntPtr h,uint msg,IntPtr w,IntPtr l);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h,out Rect r);
    [DllImport("user32.dll")] static extern bool SetCursorPos(int x,int y);
    [DllImport("user32.dll")] static extern bool GetCursorPos(out Point p);
    [DllImport("user32.dll")] static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr e);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h,IntPtr after,int x,int y,int w,int ht,uint f);
    [DllImport("user32.dll")] static extern bool SystemParametersInfo(uint a,uint b,out int c,uint d);
    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(Point p);
    [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr h,uint flags);
    public static bool FullWindowDrag() { int value; SystemParametersInfo(0x26,0,out value,0); return value!=0; }
    public static Sample[] Run(uint pid,int seconds,bool useVisible) {
        SetProcessDPIAware();
        IntPtr panel=IntPtr.Zero,script=IntPtr.Zero;
        EnumWindows((h,p)=>{
            uint id; GetWindowThreadProcessId(h,out id); if(id!=pid) return true;
            var title=new StringBuilder(256); var cls=new StringBuilder(256);
            GetWindowText(h,title,256); GetClassName(h,cls,256);
            if(title.ToString()=="LLM Tray - Model resources") panel=h;
            if(cls.ToString()=="AutoHotkey") script=h;
            return true;
        },IntPtr.Zero);
        if(panel==IntPtr.Zero || script==IntPtr.Zero) throw new Exception("Owned panel not found");
        // Same event as clicking this tray icon; no editor keystrokes or model action.
        if(useVisible) {
            if(!IsWindowVisible(panel)) throw new Exception("Expected a visible hover panel");
        } else {
            PostMessage(script,0x404,IntPtr.Zero,new IntPtr(0x202)); Thread.Sleep(700);
        }
        Rect original; GetWindowRect(panel,out original);
        Point cursor; GetCursorPos(out cursor);
        SetWindowPos(panel,IntPtr.Zero,600,400,0,0,0x15); Thread.Sleep(250);
        Rect start; GetWindowRect(panel,out start);
        double scale=(start.R-start.L)/490.0;
        int offsetX=(int)(150*scale),offsetY=(int)(20*scale);
        int x=start.L+offsetX,y=start.T+offsetY;
        var samples=new List<Sample>();
        try {
            SetCursorPos(x,y); Thread.Sleep(150);
            if(GetAncestor(WindowFromPoint(new Point { X=x,Y=y }),2)!=panel)
                throw new Exception("Another window covers the drag target; refusing input");
            mouse_event(2,0,0,0,UIntPtr.Zero); Thread.Sleep(50);
            var clock=Stopwatch.StartNew();
            while(clock.Elapsed.TotalSeconds<seconds) {
                double t=clock.Elapsed.TotalSeconds;
                int dx=(int)(210*Math.Sin(t*1.5)),dy=(int)(90*Math.Sin(t*2.1));
                SetCursorPos(x+dx,y+dy); Thread.Sleep(16);
                Rect r; GetWindowRect(panel,out r);
                Point actual; GetCursorPos(out actual);
                bool interference=Math.Abs(actual.X-x-dx)>2 || Math.Abs(actual.Y-y-dy)>2;
                samples.Add(new Sample { Ms=clock.Elapsed.TotalMilliseconds, CursorX=x+dx,CursorY=y+dy,
                    ActualCursorX=actual.X,ActualCursorY=actual.Y,InputInterference=interference,
                    WindowX=r.L,WindowY=r.T,ErrorPx=Math.Sqrt(Math.Pow(r.L-start.L-dx,2)+Math.Pow(r.T-start.T-dy,2)) });
                if(interference) break; // Stop promptly if the user moves the mouse.
            }
        } finally {
            mouse_event(4,0,0,0,UIntPtr.Zero); Thread.Sleep(350);
            SetWindowPos(panel,IntPtr.Zero,original.L,original.T,0,0,0x15);
            // Persist the restored location using the normal end-of-move handler.
            PostMessage(panel,0x232,IntPtr.Zero,IntPtr.Zero);
            SetCursorPos(cursor.X,cursor.Y);
        }
        return samples.ToArray();
    }
}
'@
$samples=[DragProbe]::Run($TrayProcessId,$Seconds,[bool]$UseVisiblePanel)
$errors=@($samples.ErrorPx|Sort-Object)
$longest=0.0;$lastChange=0.0;$previous=$null
foreach($sample in $samples){
    if($null -eq $previous -or $sample.WindowX -ne $previous.WindowX -or $sample.WindowY -ne $previous.WindowY){
        $longest=[Math]::Max($longest,$sample.Ms-$lastChange);$lastChange=$sample.Ms
    }
    $previous=$sample
}
$longest=[Math]::Max($longest,$samples[-1].Ms-$lastChange)
$summary=[ordered]@{
    timestamp=(Get-Date -Format o);process_id=$TrayProcessId;samples=$samples.Count
    full_window_drag=[DragProbe]::FullWindowDrag()
    duration_ms=[Math]::Round($samples[-1].Ms,1)
    input_interference=@($samples|Where-Object InputInterference).Count -gt 0
    p95_tracking_error_px=[Math]::Round($errors[[int][Math]::Floor(($errors.Count-1)*0.95)],1)
    maximum_tracking_error_px=[Math]::Round($errors[-1],1)
    longest_unchanged_position_ms=[Math]::Round($longest,1)
}
[pscustomobject]@{summary=$summary;samples=$samples}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 -LiteralPath $OutputPath
$summary|ConvertTo-Json
if($summary.input_interference){throw 'Mouse moved outside the test path. Input stopped; this run is inconclusive.'}
if($summary.p95_tracking_error_px -gt 12 -or $longest -gt 150){throw 'Drag responsiveness regression: inspect the saved samples.'}
