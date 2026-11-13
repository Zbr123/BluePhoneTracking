# Place / tear down an inbound call to the Blue phone (same VoIP API as Robot).
# Usage (from repo root or anywhere):
#   powershell -ExecutionPolicy Bypass -File ".\1.5-APK-AUTOMATION\scripts\place_inbound_call.ps1"
#   powershell -ExecutionPolicy Bypass -File ".\1.5-APK-AUTOMATION\scripts\place_inbound_call.ps1" -Action down

param(
    [ValidateSet("up", "down")]
    [string]$Action = "up",

    # Softphone (NAU) that dials the AU
    [string]$Did = "6264241175",
    [string]$DidPassword = "jeb9kg_xxv@9e4",

    # AU phone number (home "My Number")
    [string]$CalleeNumber = "6503196269",

    [string]$BlueDeviceId = "B34049ec9405b",
    [string]$UserName = "jh-auto-s-10@cc-qa.com",
    [string]$Duration = "5000"
)

$ErrorActionPreference = "Stop"

$baseUrl = "https://e7mknbtv0d.execute-api.us-west-2.amazonaws.com/ccqa"
$headers = @{
    "Authorization" = "Bearer vTJGrJVBOckFbUyEfS1cZL0RmMFppCMLkywFI7huePyAtZ58Rlt8q2s4H1cHeLu4"
    "x-auth-token"  = "UXB9bLaZu99cKsDdAoX0OgKSXCKWXeXVcDowF9Q14zk7A8pGVCtqd4xtfslVztHB"
    "Content-Type"  = "application/json"
}

$cmd  = if ($Action -eq "up") { "UP" } else { "DOWN" }
$url  = if ($Action -eq "up") { "$baseUrl/make_calls" } else { "$baseUrl/remove_container" }

$body = @{
    user_name      = $UserName
    account        = "097041003708"
    region         = "us-west-2"
    version        = "2_9_3"
    blue_device_id = $BlueDeviceId
    did            = $Did
    password       = $DidPassword
    cmd            = $cmd
    type           = "OB"
    media          = "SCRIPT2"
    duration       = $Duration
    callee_number  = $CalleeNumber
} | ConvertTo-Json

Write-Host "Action : $Action ($cmd)"
Write-Host "NAU DID: $Did  ->  AU: $CalleeNumber"
Write-Host "Device : $BlueDeviceId"
Write-Host "URL    : $url"
Write-Host ""

$resp = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body
Write-Host "Response:"
$resp | ConvertTo-Json -Depth 6

if ($Action -eq "up") {
    Write-Host ""
    Write-Host "If it worked, the Blue phone should ring shortly."
    Write-Host "When done, tear down with:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action down"
}
