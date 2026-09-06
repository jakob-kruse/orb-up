[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Repository = if ($env:ORB_UP_REPOSITORY) { $env:ORB_UP_REPOSITORY } else { 'J4K4-Dev/orb-up' }
$Ref = if ($env:ORB_UP_REF) { $env:ORB_UP_REF } else { 'main' }
$BaseUrl = "https://raw.githubusercontent.com/$Repository/$Ref"
$SourceUrl = if ($env:ORB_UP_SOURCE_URL) { $env:ORB_UP_SOURCE_URL } else { "$BaseUrl/orb-up.ps1" }
$PluginSourceUrl = if ($env:ORB_UP_PLUGIN_SOURCE_URL) { $env:ORB_UP_PLUGIN_SOURCE_URL } else { "$BaseUrl/orb-up-idle.ts" }

function Find-Amp {
	$command = Get-Command amp -ErrorAction SilentlyContinue
	if ($command) { return $command.Source }
	$installedAmp = Join-Path $(if ($env:AMP_HOME) { $env:AMP_HOME } else { Join-Path $HOME '.amp' }) 'bin\amp.exe'
	if (Test-Path -LiteralPath $installedAmp -PathType Leaf) { return $installedAmp }
	return $null
}

try {
	$ampBin = Find-Amp
	if (-not $ampBin) {
		Write-Output 'Installing Amp CLI...'
		$ampInstaller = Join-Path ([IO.Path]::GetTempPath()) "install-amp-$PID.ps1"
		try {
			Invoke-WebRequest -UseBasicParsing https://ampcode.com/install.ps1 -OutFile $ampInstaller
			Unblock-File -LiteralPath $ampInstaller
			& $ampInstaller
		} finally {
			Remove-Item -LiteralPath $ampInstaller -Force -ErrorAction SilentlyContinue
		}
		$ampBin = Find-Amp
		if (-not $ampBin) { throw 'Amp installation finished, but the executable was not found' }
	}

	$installDirectory = if ($env:ORB_UP_INSTALL_DIR) {
		$env:ORB_UP_INSTALL_DIR
	} else {
		Join-Path $env:LOCALAPPDATA 'Programs\orb-up'
	}
	$pluginDirectory = if ($env:ORB_UP_PLUGIN_DIR) {
		$env:ORB_UP_PLUGIN_DIR
	} else {
		Join-Path $HOME '.config\amp\plugins'
	}
	New-Item -ItemType Directory -Path $installDirectory, $pluginDirectory -Force | Out-Null

	Write-Output 'Installing orb-up...'
	$orbUpPath = Join-Path $installDirectory 'orb-up.ps1'
	$pluginPath = Join-Path $pluginDirectory 'orb-up-idle.ts'
	Invoke-WebRequest -UseBasicParsing $SourceUrl -OutFile $orbUpPath
	Invoke-WebRequest -UseBasicParsing $PluginSourceUrl -OutFile $pluginPath
	Unblock-File -LiteralPath $orbUpPath, $pluginPath

	$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
	$pathEntries = @($userPath -split ';' | Where-Object { $_ })
	if ($installDirectory -notin $pathEntries) {
		[Environment]::SetEnvironmentVariable('Path', (($pathEntries + $installDirectory) -join ';'), 'User')
	}
	if ($installDirectory -notin ($env:Path -split ';')) {
		$env:Path = "$env:Path;$installDirectory"
	}

	$env:AMP_BIN = $ampBin
	& $orbUpPath enable-updates

	Write-Output "`norb-up is installed at $installDirectory\orb-up.ps1."
	Write-Output 'Open a new PowerShell window, then start a runner with:'
	Write-Output '  orb-up.ps1 start C:\path\to\project'
} catch {
	Write-Error "orb-up installer: $($_.Exception.Message)"
	exit 1
}
