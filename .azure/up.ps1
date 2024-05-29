Import-Module Az.Resources
Install-Module -Name PSMenu -Scope CurrentUser
Import-Module -Name PSMenu

$ErrorActionPreference = "Stop"

Connect-AzAccount

if (-not $?) {
    throw "Failed to connect to Azure account."
}

$subscriptions = Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' }

Write-Host "Select a subscription:"
$subscription = Show-Menu -MenuItems $subscriptions -MenuItemFormatter { $Args | Select -Exp Name }

Set-AzContext -Subscription $subscription
$user = az ad signed-in-user show | ConvertFrom-Json

$resourceGroupName = $newResourceGroupName = '(new)'
$resourceGroupNames = @($resourceGroupName) + @(Get-AzResourceGroup | ForEach-Object { $_.ResourceGroupName })
if ($resourceGroupNames.Count -gt 1) {

    Write-Host "Select a resource group:"
    $resourceGroupName = Show-Menu -MenuItems $resourceGroupNames
}

if ($resourceGroupName -eq $newResourceGroupName) {

    Write-host "getting locations...`r" -NoNewline
    $locations = Get-AzLocation

    Write-host "`rSelect a location for the new resource group"
    $location = Show-Menu -MenuItems ($locations | ForEach-Object { $_.DisplayName })

    $resourceGroupName = $null
    while ([string]::IsNullOrEmpty($resourceGroupName)) {
        $resourceGroupName = Read-Host -Prompt "New resource group name"
        
        if (-not [string]::IsNullOrEmpty($resourceGroupName)) {

            try {
    
                New-AzResourceGroup -Name $resourceGroupName -Location $location

            }
            catch {
                Write-Host "The resource group name '$resourceGroupName' is invalid or not available. Please try again."
                $resourceGroupName = $null
            }
        }
    }
}

# Define the group name
$groupName = "$resourceGroupName-group"
$group = Get-AzADGroup -SearchString $groupName 

if ($null -eq $group) {
    $group = New-AzADGroup -DisplayName $groupName -MailNickName $groupName
}

try {
    $deployment = New-AzResourceGroupDeployment -TemplateFile "./main.bicep" -Mode Complete -Force -Verbose `
        -ResourceGroupName $resourceGroupName `
        -groupId $group.Id `
        -prefix $resourceGroupName

    Write-Host "Deployed app $($deployment.Outputs | Format-Table -AutoSize -Wrap | Out-String)"

    ipconfig /flushdns

    $appPrincipalId = $deployment.Outputs.appPrincipalId.Value
    $appName = $deployment.Outputs.appName.Value
    $appHostname = $deployment.Outputs.appHostname.Value

    $groupMembers = Get-AzADGroupMember -GroupObjectId $group.Id
    if ($null -eq ($groupMembers | Where-Object { $_.Id -eq $appPrincipalId })) {
        Add-AzADGroupMember -TargetGroupObjectId $group.Id -MemberObjectId $appPrincipalId
    }
    if ($null -eq ($groupMembers | Where-Object { $_.Id -eq $user.Id })) {
        Add-AzADGroupMember -TargetGroupObjectId $group.Id -MemberObjectId $user.Id
    }

    Write-Host "Waiting for DNS to propagate for $appHostname...`r"
    while ($true) {
        try {
            Resolve-DnsName -Name $appHostname -ErrorAction Stop
            Write-Host "DNS has propagated for $appHostname."
            break
        }
        catch {
            Write-Host "DNS has not yet propagated for $appHostname. Waiting for 30 seconds before checking again...`r"
            Start-Sleep -Seconds 30
        }
    }

    Write-Host "Publishing app '$($appName)' to Azure...`r"

    Push-Location
    Set-Location ../Sandbox.Secretless.Functions

    $localPublishFolder = "./bin/Release/net8.0/publish"
    $zipPath = "./bin/Release/net8.0/publish.zip"

    dotnet publish --configuration Release --output $localPublishFolder

    Compress-Archive -Path $localPublishFolder/* -DestinationPath $zipPath -Force
    Publish-AzWebapp -ResourceGroupName $resourceGroupName -Name $appName -ArchivePath $zipPath -Force

}
catch {
    Write-Host "failed, error:"
    Write-Host $_.Exception.Message

    if ($_.Exception.InnerException) {
        Write-Host "Inner Exception:"
        Write-Host $_.Exception.InnerException.Message
    }
}
finally {
    
    Pop-Location
}