
#------------------------------------------------
# keepTheDarnScreenOn.ps1
# 
# Script Written/Edited by Luka Altunashvili,
# with use of google gemini
#
# Written to keep your darn screen on
# Made for environments where even microsofts own awake program is not allowed
#
# Icons from Microsoft Awake program (PowerToys) have been used:
# Link: https://github.com/microsoft/PowerToys/tree/main/src/modules/awake/Awake/Assets/Awake
#------------------------------------------------

# Load necessary .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURATION: SET YOUR ICON PATHS HERE ---
$IdleIconPath   = "$PSScriptRoot\disabled.ico"   # Icon when OFF
$ActiveIconPath = "$PSScriptRoot\normal.ico" # Icon when ON
# -----------------------------------------------

# Global variables
$Global:KeepAwake = $false
$Global:StartTime = $null
$Global:LastPulseTime = $null
$WshShell = New-Object -ComObject WScript.Shell
$IntervalMs = 60000 

# --- Function to Load Icons Safely ---
function Get-MyIcon ([string]$Path) {
    if (Test-Path $Path) {
        return New-Object System.Drawing.Icon($Path)
    } else {
        # Fallback to PowerShell icon if file is missing
        return [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -id $PID).Path)
    }
}

$IdleIcon   = Get-MyIcon $IdleIconPath
$ActiveIcon = Get-MyIcon $ActiveIconPath

# --- Create the System Tray Icon ---
$NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
$NotifyIcon.Icon = $IdleIcon # Start with Idle icon
$NotifyIcon.Text = "Status: Idle"
$NotifyIcon.Visible = $true

# --- Create the Context Menu ---
$ContextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$StatusLabel = New-Object System.Windows.Forms.ToolStripMenuItem("Status: Idle")
$StatusLabel.Enabled = $false

$TotalTimerLabel = New-Object System.Windows.Forms.ToolStripMenuItem("Total Active: 00:00:00")
$TotalTimerLabel.Enabled = $false

$LastPulseLabel = New-Object System.Windows.Forms.ToolStripMenuItem("Last Pulse: Never")
$LastPulseLabel.Enabled = $false

$NextPulseLabel = New-Object System.Windows.Forms.ToolStripMenuItem("Next Pulse in: --s")
$NextPulseLabel.Enabled = $false

$ContextMenu.Items.AddRange(@($StatusLabel, $TotalTimerLabel, $LastPulseLabel, $NextPulseLabel))
$ContextMenu.Items.Add("-") | Out-Null 

$ToggleItem = $ContextMenu.Items.Add("Enable Ghost Key")
$ToggleItem.CheckOnClick = $true
$ExitItem = $ContextMenu.Items.Add("Exit")

# --- Timers ---
$PulseTimer = New-Object System.Windows.Forms.Timer
$PulseTimer.Interval = $IntervalMs 
$PulseTimer.add_Tick({
    if ($Global:KeepAwake) { 
        $WshShell.SendKeys('+{F15}') 
        $Global:LastPulseTime = Get-Date
        
        # Flash Green logic
        $StatusLabel.BackColor = [System.Drawing.Color]::LimeGreen
        $StatusLabel.ForeColor = [System.Drawing.Color]::Black
        $ResetTimer = New-Object System.Windows.Forms.Timer
        $ResetTimer.Interval = 1000
        $ResetTimer.add_Tick({
            $StatusLabel.BackColor = [System.Drawing.Color]::Transparent
            $StatusLabel.ForeColor = [System.Drawing.SystemColors]::ControlText
            $this.Stop(); $this.Dispose()
        })
        $ResetTimer.Start()
    }
})

$UITimer = New-Object System.Windows.Forms.Timer
$UITimer.Interval = 1000
$UITimer.add_Tick({
    if ($Global:KeepAwake) {
        $Now = Get-Date
        $Elapsed = $Now - $Global:StartTime
        $TotalTimerLabel.Text = "Total Active: {0:hh\:mm\:ss}" -f $Elapsed
        
        if ($Global:LastPulseTime) {
            $SecSince = [math]::Floor(($Now - $Global:LastPulseTime).TotalSeconds)
            $SecUntil = [math]::Max(0, ($IntervalMs / 1000) - $SecSince)
            $LastPulseLabel.Text = "Last Pulse: {0}s ago" -f $SecSince
            $NextPulseLabel.Text = "Next Pulse in: {0}s" -f $SecUntil
        }
    }
})

# --- Event Handlers ---
$ToggleItem.add_Click({
    $Global:KeepAwake = $ToggleItem.Checked
    
    if ($Global:KeepAwake) {
        $Global:StartTime = Get-Date
        $Global:LastPulseTime = Get-Date
        $PulseTimer.Start()
        $UITimer.Start()
        
        # Update UI and SWITCH ICON TO ACTIVE
        $NotifyIcon.Icon = $ActiveIcon
        $StatusLabel.Text = "Status: Active"
        $NotifyIcon.Text = "Ghost Key: Active"
    } else {
        $PulseTimer.Stop()
        $UITimer.Stop()
        $Global:StartTime = $null
        $Global:LastPulseTime = $null
        
        # Update UI and SWITCH ICON TO IDLE
        $NotifyIcon.Icon = $IdleIcon
        $StatusLabel.Text = "Status: Idle"
        $StatusLabel.BackColor = [System.Drawing.Color]::Transparent
        $TotalTimerLabel.Text = "Total Active: 00:00:00"
        $LastPulseLabel.Text = "Last Pulse: Never"
        $NextPulseLabel.Text = "Next Pulse in: --s"
        $NotifyIcon.Text = "Status: Idle"
    }
})

$ExitItem.add_Click({
    $PulseTimer.Stop()
    $UITimer.Stop()
    $NotifyIcon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
    Stop-Process -Id $PID
})

$NotifyIcon.ContextMenuStrip = $ContextMenu

# --- Run ---
$ApplicationContext = New-Object System.Windows.Forms.ApplicationContext
[System.Windows.Forms.Application]::Run($ApplicationContext)