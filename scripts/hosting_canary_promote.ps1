param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [string]$SiteId = "datafightcentral",

    [string]$ChannelId = "canary",

    [string]$Expires = "7d",

    [switch]$Promote
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying preview channel '$ChannelId' for site '$SiteId' in project '$ProjectId'..."
& firebase 'hosting:channel:deploy' $ChannelId --project $ProjectId --expires $Expires --non-interactive

if (-not $Promote) {
    Write-Host "Preview deploy complete. Promotion skipped (use -Promote to clone to live)."
    exit 0
}

$sourceChannel = ($SiteId, [char]58, $ChannelId) -join ''
$targetChannel = ($SiteId, [char]58, 'live') -join ''

Write-Host "Promoting '$sourceChannel' to '$targetChannel'..."
& firebase 'hosting:clone' $sourceChannel $targetChannel --project $ProjectId --non-interactive

Write-Host "Promotion complete. Live channel now reflects '$ChannelId'."
