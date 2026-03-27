$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = 'powershell.exe'
$psi.Arguments = '-NoProfile -WindowStyle Hidden -File "C:\Users\lukautaa\Desktop\keepawake\keepTheDarnScreenOn.ps1"'
$psi.CreateNoWindow = $true
$psi.UseShellExecute = $false
[System.Diagnostics.Process]::Start($psi) | Out-Null