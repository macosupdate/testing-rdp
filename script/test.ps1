$authKey = $env:TAILSCALE_AUTH_KEY
#$hostname = "gh-runner-" + ($env:GITHUB_RUN_ID ?? (Get-Random))
$hostname = "gh-runner-win"

# Enable Remote Desktop and disable NLA
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 -Force
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0 -Force
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "SecurityLayer" -Value 0 -Force

# Firewall rule for RDP
netsh advfirewall firewall delete rule name="RDP-Tailscale"
netsh advfirewall firewall add rule name="RDP-Tailscale" dir=in action=allow protocol=TCP localport=3389

Restart-Service -Name TermService -Force

# Set password for runneradmin (from secret)
$password = "Y276rJ68s45XgVfE"
$securePass = ConvertTo-SecureString $password -AsPlainText -Force
Set-LocalUser -Name "runneradmin" -Password $securePass

# Install Tailscale
$tsUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-1.88.1-amd64.msi"
$installerPath = "$env:TEMP\tailscale.msi"
Invoke-WebRequest -Uri $tsUrl -OutFile $installerPath
Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart" -Wait
Remove-Item $installerPath -Force

# Bring up Tailscale
& "$env:ProgramFiles\Tailscale\tailscale.exe" up --authkey=$authKey --hostname=$hostname

# Wait for IP
$tsIP = $null
$retries = 0
while (-not $tsIP -and $retries -lt 10) {
    $tsIP = & "$env:ProgramFiles\Tailscale\tailscale.exe" ip -4
    Start-Sleep -Seconds 5
    $retries++
}

if (-not $tsIP) {
    Write-Error "Tailscale IP not assigned. Exiting."
    exit 1
}

# Export IP
$env:TAILSCALE_IP = $tsIP
echo "TAILSCALE_IP=$tsIP" >> $env:GITHUB_ENV

Write-Host "Tailscale IP: $tsIP"

# Test RDP connectivity
$testResult = Test-NetConnection -ComputerName $tsIP -Port 3389
if (-not $testResult.TcpTestSucceeded) {
    Write-Error "TCP connection to RDP port 3389 failed"
    exit 1
}
Write-Host "TCP connectivity successful!"

#hide console github
Add-Type '[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr hWnd,int nCmdShow);' -Name Win32 -Namespace Native; $p=Get-Process hosted-compute-agent; [Native.Win32]::ShowWindow($p.MainWindowHandle,6)
