[CmdletBinding()]
param(
	[string]$Version = "1.0.0",
	[string]$GodotExecutable = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
if ([string]::IsNullOrWhiteSpace($GodotExecutable)) {
	[string[]]$candidates = @()
	if (-not [string]::IsNullOrWhiteSpace($env:GODOT_EXECUTABLE)) {
		$candidates += $env:GODOT_EXECUTABLE
	}

	foreach ($commandName in @("godot", "godot4")) {
		$command = Get-Command $commandName -ErrorAction SilentlyContinue |
			Select-Object -First 1
		if ($command -and -not [string]::IsNullOrWhiteSpace($command.Source)) {
			$candidates += $command.Source
		}
	}

	$candidates += Join-Path (Split-Path -Parent $projectRoot) "Godot_v4.7.2-stable_win64_console.exe"
	$candidates += Join-Path $projectRoot "tools\Godot_v4.7.2-stable_win64_console.exe"

	$GodotExecutable = $candidates |
		Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
		Select-Object -First 1
	if ([string]::IsNullOrWhiteSpace($GodotExecutable)) {
		throw "Godot console executable not found. Pass -GodotExecutable or set GODOT_EXECUTABLE."
	}
}
$GodotExecutable = (Resolve-Path -LiteralPath $GodotExecutable).Path

$buildRoot = Join-Path $projectRoot "builds"
$webRoot = Join-Path $buildRoot "web"
$stagingRoot = Join-Path $buildRoot (".web-staging-" + [guid]::NewGuid().ToString("N"))
$packageName = "godot-spotlight-guide-web-demo-$Version"
$zipPath = Join-Path $buildRoot ($packageName + ".zip")
$checksumPath = $zipPath + ".sha256.txt"

$requiredWebFiles = @(
	"index.html",
	"index.js",
	"index.wasm",
	"index.pck",
	"index.png",
	"index.icon.png",
	"index.apple-touch-icon.png",
	"index.audio.worklet.js",
	"index.audio.position.worklet.js"
)

trap {
	if (Test-Path -LiteralPath $stagingRoot -PathType Container) {
		$resolvedStaging = (Resolve-Path -LiteralPath $stagingRoot).Path
		$resolvedBuildRoot = (Resolve-Path -LiteralPath $buildRoot).Path
		if ($resolvedStaging.StartsWith($resolvedBuildRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
			Remove-Item -LiteralPath $resolvedStaging -Recurse -Force
		}
	}
	throw
}

New-Item -ItemType Directory -Path $webRoot -Force | Out-Null
New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null

& $GodotExecutable `
	--headless `
	--path $projectRoot `
	--export-release "Web" `
	(Join-Path $webRoot "index.html")
if ($LASTEXITCODE -ne 0) {
	throw "Godot Web export failed with exit code $LASTEXITCODE."
}

foreach ($fileName in $requiredWebFiles) {
	$sourcePath = Join-Path $webRoot $fileName
	if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
		throw "Web export is missing $fileName"
	}
	Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $stagingRoot $fileName) -Force
}

if (Test-Path -LiteralPath $zipPath) {
	Remove-Item -LiteralPath $zipPath -Force
}
if (Test-Path -LiteralPath $checksumPath) {
	Remove-Item -LiteralPath $checksumPath -Force
}

Compress-Archive -Path (Join-Path $stagingRoot "*") -DestinationPath $zipPath -CompressionLevel Optimal

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
	$entryNames = @($archive.Entries | ForEach-Object { $_.FullName })
	foreach ($fileName in $requiredWebFiles) {
		if ($entryNames -notcontains $fileName) {
			throw "Web ZIP is missing $fileName"
		}
	}
} finally {
	$archive.Dispose()
}

$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  $($packageName).zip" | Set-Content -LiteralPath $checksumPath -Encoding ascii

$resolvedStaging = (Resolve-Path -LiteralPath $stagingRoot).Path
$resolvedBuildRoot = (Resolve-Path -LiteralPath $buildRoot).Path
if (-not $resolvedStaging.StartsWith($resolvedBuildRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
	throw "Refusing to remove staging directory outside builds."
}
Remove-Item -LiteralPath $resolvedStaging -Recurse -Force

Write-Output "WEB_PACKAGE_OK=$zipPath"
Write-Output "SHA256=$hash"

