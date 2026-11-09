[CmdletBinding()]
param(
	[int]$Port = 8765
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$webRoot = Join-Path $projectRoot "builds\web"
$indexPath = Join-Path $webRoot "index.html"

if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
	throw "Web build is missing. Run tools/package_web.ps1 first."
}

Write-Output "Serving $webRoot"
Write-Output "Open http://127.0.0.1:$Port/"
python -m http.server $Port --bind 127.0.0.1 --directory $webRoot

