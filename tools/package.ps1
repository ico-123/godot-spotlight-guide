[CmdletBinding()]
param(
	[string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$buildRoot = Join-Path $projectRoot "builds"
$stagingRoot = Join-Path $buildRoot (".staging-" + [guid]::NewGuid().ToString("N"))
$packageName = "godot-spotlight-guide-$Version"
$packageRoot = Join-Path $stagingRoot $packageName
$zipPath = Join-Path $buildRoot ($packageName + ".zip")
$checksumPath = $zipPath + ".sha256.txt"

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

$requiredFiles = @(
	"project.godot",
	"export_presets.cfg",
	"icon.svg",
	"START_HERE.md",
	"README.md",
	"CHANGELOG.md",
	"LICENSE.txt"
)

$requiredDirectories = @(
	"addons/spotlight_guide",
	"example",
	"docs"
)

foreach ($relativePath in $requiredFiles) {
	$fullPath = Join-Path $projectRoot $relativePath
	if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
		throw "Required package file is missing: $relativePath"
	}
}

foreach ($relativePath in $requiredDirectories) {
	$fullPath = Join-Path $projectRoot $relativePath
	if (-not (Test-Path -LiteralPath $fullPath -PathType Container)) {
		throw "Required package directory is missing: $relativePath"
	}
}

New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null

foreach ($relativePath in $requiredFiles) {
	Copy-Item `
		-LiteralPath (Join-Path $projectRoot $relativePath) `
		-Destination (Join-Path $packageRoot $relativePath) `
		-Force
}

foreach ($relativePath in $requiredDirectories) {
	$destinationPath = Join-Path $packageRoot $relativePath
	$destinationParent = Split-Path -Parent $destinationPath
	New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
	Copy-Item `
		-LiteralPath (Join-Path $projectRoot $relativePath) `
		-Destination $destinationPath `
		-Recurse `
		-Force
}

$excludedPackageFiles = @(
	"docs/QA_REPORT_0.9.0.md"
)

foreach ($relativePath in $excludedPackageFiles) {
	$fullPath = Join-Path $packageRoot $relativePath
	if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
		Remove-Item -LiteralPath $fullPath -Force
	}
}

Get-ChildItem -LiteralPath $packageRoot -Recurse -File |
	Where-Object {
		$_.Name -eq ".gitkeep" -or
		$_.Extension -eq ".uid"
	} |
	Remove-Item -Force

if (Test-Path -LiteralPath $zipPath) {
	Remove-Item -LiteralPath $zipPath -Force
}
if (Test-Path -LiteralPath $checksumPath) {
	Remove-Item -LiteralPath $checksumPath -Force
}

Compress-Archive -LiteralPath $packageRoot -DestinationPath $zipPath -CompressionLevel Optimal

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
	$entryNames = @($archive.Entries | ForEach-Object { $_.FullName })
	foreach ($relativePath in $requiredFiles) {
		$entryPath = "$packageName/$relativePath"
		if ($entryNames -notcontains $entryPath) {
			throw "Built archive is missing $entryPath"
		}
	}
	if ($entryNames -notcontains "$packageName/docs/.gdignore") {
		throw "Built archive is missing docs/.gdignore."
	}
	$addonEntries = @(
		$entryNames |
			Where-Object { $_ -like "$packageName/addons/spotlight_guide/*" }
	)
	if ($addonEntries.Count -eq 0) {
		throw "Built archive is missing the Spotlight Guide addon directory."
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

Write-Output "PACKAGE_OK=$zipPath"
Write-Output "SHA256=$hash"

