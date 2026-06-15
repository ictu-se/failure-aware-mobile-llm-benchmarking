param(
  [int]$Port = 8765
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$WebRoot = Join-Path $ProjectRoot "ipad-web-benchmark"
$StatusDir = Join-Path $ProjectRoot "artifacts\ipad-web-benchmark-server"
New-Item -ItemType Directory -Force -Path $StatusDir | Out-Null

$ips = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
  $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*"
} | Select-Object -ExpandProperty IPAddress)

$status = [ordered]@{
  state = "starting"
  port = $Port
  web_root = $WebRoot
  urls = @($ips | ForEach-Object { "http://$($_):$Port/" })
  updated_at = (Get-Date).ToString("o")
}
$status | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $StatusDir "server-current.json")

@(
  "# iPad web benchmark server",
  "",
  "- State: starting",
  "- Port: $Port",
  "- Web root: ``$WebRoot``",
  "",
  "Open one of these URLs on the iPad:",
  ""
) + ($status.urls | ForEach-Object { "- $_" }) | Set-Content -Encoding UTF8 (Join-Path $StatusDir "live-progress.md")

Set-Location $WebRoot
python -m http.server $Port --bind 0.0.0.0
