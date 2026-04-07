# Requires: Windows PowerShell 5.1+ or PowerShell 7+
# One-click Windows proxy

$ErrorActionPreference = "Stop"

$assetName   = "anon-live-windows-signed-amd64.zip"
$downloadUrl = "https://github.com/anyone-protocol/ator-protocol/releases/latest/download/$assetName"
$workDir     = Join-Path $env:TEMP "anyone-proxy"
$zipPath     = Join-Path $workDir $assetName
$extractDir  = Join-Path $workDir "extracted"
$stdoutLog   = Join-Path $workDir "anon-stdout.log"
$stderrLog   = Join-Path $workDir "anon-stderr.log"
$socksHost   = "127.0.0.1"
$socksPort   = 9055
$proxyServer = "socks=127.0.0.1:9055"
$script:AnonProcess = $null
$watcherPath = Join-Path $workDir "cleanup_watcher.ps1"

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class WinInetNative {
    [DllImport("wininet.dll", SetLastError=true)]
    public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
}
"@

function Refresh-WinInet {
    [void][WinInetNative]::InternetSetOption([IntPtr]::Zero, 95, [IntPtr]::Zero, 0)
    [void][WinInetNative]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0)
}

function Start-CleanupWatcher {
@"
param(
    [int]`$ParentPid
)

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WinInetNative {
    [DllImport("wininet.dll", SetLastError=true)]
    public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
}
'@

function Refresh-WinInet {
    [void][WinInetNative]::InternetSetOption([IntPtr]::Zero, 95, [IntPtr]::Zero, 0)
    [void][WinInetNative]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0)
}

while (Get-Process -Id `$ParentPid -ErrorAction SilentlyContinue) {
    Start-Sleep -Seconds 1
}

`$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-ItemProperty -Path `$reg -Name "ProxyEnable" -Value 0 -ErrorAction SilentlyContinue
Remove-ItemProperty -Path `$reg -Name "ProxyServer" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path `$reg -Name "ProxyOverride" -ErrorAction SilentlyContinue
Refresh-WinInet

Get-Process -Name "anon" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
"@ | Set-Content -Path $watcherPath -Encoding UTF8

    Start-Process powershell `
        -WindowStyle Hidden `
        -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$watcherPath`" -ParentPid $PID" | Out-Null
}

function Show-Banner {
    param(
        [string]$Message,
        [string]$Color = "Cyan"
    )

    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ("{0,-54}" -f $Message) -ForegroundColor $Color
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Set-ProxyOn {
    $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $reg -Name "ProxyEnable" -Value 1
    Set-ItemProperty -Path $reg -Name "ProxyServer" -Value $proxyServer
    Set-ItemProperty -Path $reg -Name "ProxyOverride" -Value "<local>"
    Refresh-WinInet
}

function Set-ProxyOff {
    $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $reg -Name "ProxyEnable" -Value 0 -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $reg -Name "ProxyServer" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $reg -Name "ProxyOverride" -ErrorAction SilentlyContinue
    Refresh-WinInet
}

function Wait-ForPort {
    param(
        [string]$ListenHost,
        [int]$Port,
        [int]$TimeoutSeconds = 120
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $lastBootstrapped = $null

    while ((Get-Date) -lt $deadline) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $iar = $client.BeginConnect($ListenHost, $Port, $null, $null)
            $connected = $iar.AsyncWaitHandle.WaitOne(1000, $false)

            if ($connected -and $client.Connected) {
                $client.EndConnect($iar) | Out-Null
                $client.Close()
                return
            }

            $client.Close()
        } catch {
        }

        if ($script:AnonProcess -and $script:AnonProcess.HasExited) {
            throw "anon.exe exited unexpectedly"
        }

        if (Test-Path $stdoutLog) {
            $line = Get-Content $stdoutLog -Tail 50 -ErrorAction SilentlyContinue |
                Where-Object { $_ -match "Bootstrapped \d+%" } |
                Select-Object -Last 1

            if ($line -and $line -ne $lastBootstrapped) {
                Write-Host $line
                $lastBootstrapped = $line
            }
        }

        Start-Sleep -Seconds 1
    }

    throw "Timed out waiting for local SOCKS proxy on $ListenHost`:$Port"
}

function Cleanup {
    Set-ProxyOff

    if ($script:AnonProcess -and -not $script:AnonProcess.HasExited) {
        Stop-Process -Id $script:AnonProcess.Id -Force -ErrorAction SilentlyContinue
    } else {
        Get-Process -Name "anon" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    Remove-Item $stdoutLog -Force -ErrorAction SilentlyContinue
    Remove-Item $stderrLog -Force -ErrorAction SilentlyContinue
    Remove-Item $watcherPath -Force -ErrorAction SilentlyContinue
	
    if (Test-Path $extractDir) {
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Show-Banner -Message "ANON Proxy terminated" -Color "Red"
}

if ($env:OS -ne "Windows_NT") {
    Write-Host "This script is for Windows"
    exit 1
}

try {
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    Start-CleanupWatcher

    if (-not (Test-Path $zipPath)) {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    }
    Show-Banner -Message "Starting ANON Proxy, bootstrapping..." -Color "Green"
    Get-Process -Name "anon" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    if (Test-Path $extractDir) {
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

    $anonExe = Get-ChildItem -Path $extractDir -Recurse -File -Filter "anon.exe" |
        Select-Object -First 1

    if (-not $anonExe) {
        throw "anon.exe not found after extraction"
    }

    $anonDir = Split-Path $anonExe.FullName -Parent
    $anonRc  = Join-Path $anonDir "anonrc"

@"
SocksPort 127.0.0.1:9055
SocksPolicy accept 127.0.0.1
SocksPolicy reject *
HTTPTunnelPort auto
"@ | Set-Content -Path $anonRc -Encoding ASCII

    $script:AnonProcess = Start-Process `
        -FilePath $anonExe.FullName `
        -ArgumentList @("-f", $anonRc, "--agree-to-terms") `
        -WorkingDirectory $anonDir `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -PassThru

    Wait-ForPort -ListenHost $socksHost -Port $socksPort -TimeoutSeconds 120

    Set-ProxyOn
    Start-Sleep -Seconds 1

    $exitIp = ""
    $isAnon = ""
    $exitCountry = ""

    $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($curl) {
        $checkAnon = & $curl.Source --socks5 "$socksHost`:$socksPort" -s "https://check.en.anyone.tech/api/ip" 2>$null

        if ($checkAnon) {
            try {
                $obj = $checkAnon | ConvertFrom-Json
                $exitIp = $obj.ip
                $isAnon = $obj.isAnon
            } catch {
            }
        }

        $countryJson = & $curl.Source --socks4 "$socksHost`:$socksPort" -s "https://ipinfo.io" 2>$null
        if ($countryJson) {
            try {
                $countryObj = $countryJson | ConvertFrom-Json
                $exitCountry = $countryObj.country
            } catch {
            }
        }
    }

    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ""
    if ($exitIp) {
        Write-Host "Exit IP: $exitIp"
    }
    if ($exitCountry) {
        Write-Host "Exit Country: $exitCountry"
    }
    if ($isAnon -ne "") {
        Write-Host "Is Anon: $isAnon"
    }
    if (-not $curl) {
        Write-Host "Proxy Check: https://check.en.anyone.tech"
    }
    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "ANON Proxy activated" -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ""

    while ($true) {
        Write-Host "Press Ctrl+C to terminate proxy" -ForegroundColor Red
        Start-Sleep -Seconds 1800
    }
}
finally {
    Cleanup
}