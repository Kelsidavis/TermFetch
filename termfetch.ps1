# termfetch.ps1 – TermPix Logo + Aligned, Colored System Info

# --- Detect OS Info ---
$osInfo = Get-CimInstance Win32_OperatingSystem
$osCaption = $osInfo.Caption
$buildNumber = [System.Environment]::OSVersion.Version.Build

# --- Logo Selection ---
$logoFolder = "$PSScriptRoot\logos"
switch -Regex ($osCaption) {
    "Windows 11"            { $logo = "$logoFolder\11.png" }
    "Windows 10"            { $logo = "$logoFolder\10.png" }
    "Windows Server.*2022"  { $logo = "$logoFolder\s22.png" }
    "Windows Server"        { $logo = "$logoFolder\generic.png" }
    default                 { $logo = "$logoFolder\generic.png" }
}

# --- Fixed logo size ---
$width = 40
$height = 20

# --- Gather System Info ---
$hostname = $env:COMPUTERNAME
$username = $env:USERNAME
$cpu = (Get-CimInstance Win32_Processor)[0].Name
$gpu = (Get-CimInstance Win32_VideoController)[0].Name
$ramGB = "{0:N1}" -f ((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$res = (Get-CimInstance Win32_VideoController)[0].CurrentHorizontalResolution
$resY = (Get-CimInstance Win32_VideoController)[0].CurrentVerticalResolution
$uptime = (Get-Date) - $osInfo.LastBootUpTime
$uptimeStr = "{0}h {1}m" -f [math]::Floor($uptime.TotalHours), $uptime.Minutes
$shell = "PowerShell $($PSVersionTable.PSVersion.ToString())"
$parent = (Get-Process -Id $PID).Parent
$terminal = if ($parent.Name -like "*WindowsTerminal*") { "Windows Terminal" } else { $parent.Name }

# --- Format System Info as Label : Value pairs ---
$sysinfo = @(
    "OS         : $osCaption (Build $buildNumber)"
    "Hostname   : $hostname"
    "Username   : $username"
    "Uptime     : $uptimeStr"
    "CPU        : $cpu"
    "GPU        : $gpu"
    "RAM        : $ramGB GB"
    "Resolution : ${res}x${resY}"
    "Shell      : $shell"
    "Terminal   : $terminal"
)

# --- Render logo in color mode at fixed size ---
if (Test-Path $logo) {
    & "$PSScriptRoot\termpix.exe" --silent --width $width --height $height --mode color $logo
} else {
    Write-Warning "Logo not found for OS: $osCaption"
}

# --- Spacer ---
Write-Host "`n"

# --- Aligned + Colorized output ---
$infoWidth = 55
$totalWidth = $Host.UI.RawUI.WindowSize.Width
$leftPad = [Math]::Max(0, $totalWidth - $infoWidth - 4)

foreach ($line in $sysinfo) {
    $split = $line -split ":", 2
    if ($split.Count -eq 2) {
        $label = $split[0].Trim()
        $value = $split[1].Trim()
        $paddedLabel = (" " * $leftPad) + $label.PadRight(12)
        Write-Host ($paddedLabel + ":") -ForegroundColor Cyan -NoNewline
        Write-Host " $value" -ForegroundColor White
    } else {
        Write-Host ((" " * $leftPad) + $line) -ForegroundColor White
    }
}
