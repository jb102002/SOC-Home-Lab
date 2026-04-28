<powershell>

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$ProgressPreference = 'SilentlyContinue'

New-Item -ItemType Directory -Force -Path "C:\SOCLab"

Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" `
  -OutFile "C:\SOCLab\Sysmon.zip" `
  -UseBasicParsing

Expand-Archive -Path "C:\SOCLab\Sysmon.zip" `
  -DestinationPath "C:\SOCLab\Sysmon"

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" `
  -OutFile "C:\SOCLab\sysmonconfig.xml" `
  -UseBasicParsing

Start-Process -FilePath "C:\SOCLab\Sysmon\Sysmon64.exe" `
  -ArgumentList "-accepteula -i C:\SOCLab\sysmonconfig.xml" `
  -Wait

Invoke-WebRequest -Uri "https://download.splunk.com/products/universalforwarder/releases/10.2.2/windows/splunkforwarder-10.2.2-80b90d638de6-windows-x64.msi" `
  -OutFile "C:\SOCLab\splunkforwarder.msi" `
  -UseBasicParsing

Start-Process -FilePath "msiexec.exe" -ArgumentList `
  "/i C:\SOCLab\splunkforwarder.msi /quiet AGREETOLICENSE=Yes " + `
  "SPLUNKUSERNAME=YOUR_USERNAME_HERE SPLUNKPASSWORD=YOUR_PASSWORD_HERE " + `
  "RECEIVING_INDEXER=${splunk_private_ip}:9997" `
  -Wait

$inputsConf = @"
[WinEventLog://Application]
index = windows
disabled = false

[WinEventLog://Security]
index = windows
disabled = false

[WinEventLog://System]
index = windows
disabled = false

[WinEventLog://Microsoft-Windows-Sysmon/Operational]
index = sysmon
disabled = false
renderXml = true
"@

$inputsPath = "C:\Program Files\SplunkUniversalForwarder\etc\system\local\inputs.conf"
New-Item -ItemType Directory -Force -Path (Split-Path $inputsPath)
Set-Content -Path $inputsPath -Value $inputsConf

sc.exe config SplunkForwarder obj= "LocalSystem"

Restart-Service -Name "SplunkForwarder"

</powershell>