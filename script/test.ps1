# Enable Remote Desktop and disable Network Level Authentication (if needed)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
                    -Name "fDenyTSConnections" -Value 0 -Force
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
                    -Name "UserAuthentication" -Value 0 -Force
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
                    -Name "SecurityLayer" -Value 0 -Force

# Remove any existing rule with the same name to avoid duplication
netsh advfirewall firewall delete rule name="RDP-Tailscale"

# For testing, allow any incoming connection on port 3389
netsh advfirewall firewall add rule name="RDP-Tailscale" `
  dir=in action=allow protocol=TCP localport=3389

# (Optional) Restart the Remote Desktop service to ensure changes take effect
Restart-Service -Name TermService -Force


########################Set Password
$password = "Y276rJ68s45XgVfE"
$securePass = ConvertTo-SecureString $password -AsPlainText -Force
Set-LocalUser -Name "runneradmin" -Password $securePass

##################Cài đặt Tailscale
$tsUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-1.88.1-amd64.msi"
$installerPath = "$env:TEMP\tailscale.msi"

Invoke-WebRequest -Uri $tsUrl -OutFile $installerPath
Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart" -Wait
Remove-Item $installerPath -Force

# Bring up Tailscale with the provided auth key and set a unique hostname
& "$env:ProgramFiles\Tailscale\tailscale.exe" up --authkey=${{ secrets.TAILSCALE_AUTH_KEY }} --hostname=gh-runner-$env:GITHUB_RUN_ID

# Wait for Tailscale to assign an IP
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
echo "TAILSCALE_IP=$tsIP" >> $env:GITHUB_ENV

Write-Host "Tailscale IP: $env:TAILSCALE_IP"

# Test connectivity using Test-NetConnection against the Tailscale IP on port 3389
$testResult = Test-NetConnection -ComputerName $env:TAILSCALE_IP -Port 3389
if (-not $testResult.TcpTestSucceeded) {
    Write-Error "TCP connection to RDP port 3389 failed"
    exit 1
}
Write-Host "TCP connectivity successful!"
