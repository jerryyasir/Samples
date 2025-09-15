$AllreportData = @()

[string]$SiteUrl = "https://30jk56.sharepoint.com/sites/JustBasicTeamSite" 
$TargetAdminGroupName = "*admins" 
$TargetOwnerGroupName = "*owners" 
$CurrentAdminPermissionLevel = "OIG Site Admin" 
$CurrentOwnerPermissionLevel = "OIG Site Owner" 
$NewPermissionLevel = "OIG Edit" 
$ReportingOnly = $true


# Import required modules
#Import-Module -Name ImportExcel -ErrorAction Stop

$excludedLists = @(
    "Master Page Gallery",
    "Style Library",
    "Theme Gallery",
    "Solution Gallery",
    "Web Part Gallery",
    "List Template Gallery",
    "User Information List",
    "Site Assets",
    "Site Pages",
    "Form Templates",
    "Workflow History",
    "Workflow Tasks",
    "Composed Looks",
    "TaxonomyHiddenList",
    "App Catalog",
    "Maintenance Log Library"
)

# Connect to the SharePoint site
Connect-PnPOnline -Url $siteUrl -ClientId "c7bf16b8-a2cb-4a5b-8080-b00016bb59ae" -Tenant "77c0f0fc-3049-4c54-a5d5-ff32be8ffd59" -Thumbprint "961A05530B35BF73165BBCA0A90F83D82CF25C24" -Verbose

#$web = Get-PnPWeb
#$subWebs = Get-PnPSubWeb -Recurse

# $lists = Get-PnPList | ? {$_.Hidden -eq $false}

# foreach ($list in $lists) {
#     $SecurableObject = $list 
#     $ObjectName = $SecurableObject.Title
#     $hasUniquePermissions = Get-PnPProperty -ClientObject $SecurableObject -Property HasUniqueRoleAssignments
#     $ObjectType = "List"
#     if ($hasUniquePermissions) {
#         Write-Host "Checking $ObjectType : $ObjectName"
        
#         # Get role assignments
#         $roleAssignments = Get-PnPProperty -ClientObject $SecurableObject -Property RoleAssignments
        
#         foreach ($roleAssignment in $roleAssignments) {
#             $principal = Get-PnPProperty -ClientObject $roleAssignment -Property Member
#             $roleBindings = Get-PnPProperty -ClientObject $roleAssignment -Property RoleDefinitionBindings
#             $principal.Title.ToLower()
#             # Check if the principal is the target group
#             if ($principal.Title.ToLower() -like $TargetAdminGroupName -or $principal.Title.ToLower() -like $TargetOwnerGroupName) {
#                 foreach ($roleBinding in $roleBindings) {
#                     if ($roleBinding.Name -eq $CurrentAdminPermissionLevel -or $roleBinding.Name -eq $CurrentOwnerPermissionLevel) {
#                         if ($ReportingOnly) {
#                             # Add to report data
#                             $reportData += [PSCustomObject]@{
#                                 ObjectType = $ObjectType
#                                 ObjectName = $ObjectName
#                                 GroupName  = $principal.Title
#                                 PermissionLevel = $roleBinding.Name
#                                 SiteUrl    = $SiteUrl
#                             }
#                             Write-Host "Found $CurrentPermissionLevel for $principal.Title in $ObjectType : $ObjectName (Reporting Only)"
#                         } else {
#                             Write-Host "Found $CurrentPermissionLevel for $principal.Title in $ObjectType : $ObjectName. Replacing with $NewPermissionLevel."
                            
#                             # Remove the current permission
#                             $SecurableObject.RoleAssignments.GetByPrincipal($principal).RoleDefinitionBindings.Remove($roleBinding)
#                             $SecurableObject.Update()
#                             Invoke-PnPQuery
                            
#                             # Add the new permission
#                             Set-PnPListItemPermission -List $ObjectName -Identity $SecurableObject -User $principal.Title -AddRole $NewPermissionLevel -ErrorAction SilentlyContinue
#                             Write-Host "Permission updated to $NewPermissionLevel for $principal.Title in $ObjectType : $ObjectName."
#                         }
#                     }
#                 }
#             }
#         }
#     }
# }

#$reportData | Out-GridView

# Array to store report data


# Function to check and update or report permissions
function Process-Permissions {
    param (
        [Parameter(Mandatory=$true)] $SecurableObject,
        [Parameter(Mandatory=$true)] $ObjectName,
        [Parameter(Mandatory=$true)] $ObjectType,
        [Parameter(Mandatory=$false)] $ReportingOnly
    )
    $reportData = @()
    # Check if the object has unique permissions
    if($ObjectType -eq "Folder") {
        $hasUniquePermissions = $true
    } else {
        $hasUniquePermissions = Get-PnPProperty -ClientObject $SecurableObject -Property HasUniqueRoleAssignments
    }

    if ($hasUniquePermissions) {
        Write-Host "Checking $ObjectType : $ObjectName"
        
        if($ObjectType -eq "Folder") {
            Write-Host "Checking folder permissions"
            $roleAssignments = $SecurableObject.ListItemAllFields.RoleAssignments
        } else {
            $roleAssignments = Get-PnPProperty -ClientObject $SecurableObject -Property RoleAssignments
        }
        
        foreach ($roleAssignment in $roleAssignments) {
            $principal = Get-PnPProperty -ClientObject $roleAssignment -Property Member
            $roleBindings = Get-PnPProperty -ClientObject $roleAssignment -Property RoleDefinitionBindings
            $principal.Title
            $roleBindings
            # Check if the principal is the target group
            if ($principal.Title.ToLower() -like $TargetAdminGroupName -or $principal.Title.ToLower() -like $TargetOwnerGroupName) {
                foreach ($roleBinding in $roleBindings) {
                     if ($roleBinding.Name -eq $CurrentAdminPermissionLevel -or $roleBinding.Name -eq $CurrentOwnerPermissionLevel) {
                        if ($ReportingOnly) {
                            # Add to report data
                            $reportData += [PSCustomObject]@{
                                ObjectType = $ObjectType
                                ObjectName = $ObjectName
                                GroupName  = $principal.Title
                                PermissionLevel = $roleBinding.Name
                                SiteUrl    = $SiteUrl
                            }
                            Write-Host "Found $CurrentPermissionLevel for $principal.Title in $ObjectType : $ObjectName (Reporting Only)"
                        } else {
                            Write-Host "Found $CurrentPermissionLevel for $principal.Title in $ObjectType : $ObjectName. Replacing with $NewPermissionLevel."                            
                            # Remove the current permission
                            $SecurableObject.RoleAssignments.GetByPrincipal($principal).RoleDefinitionBindings.Remove($roleBinding)
                            $SecurableObject.Update()
                            Invoke-PnPQuery
                            
                            # Add the new permission
                            Set-PnPListItemPermission -List $ObjectName -Identity $SecurableObject -User $principal.Title -AddRole $NewPermissionLevel -ErrorAction SilentlyContinue
                            Write-Host "Permission updated to $NewPermissionLevel for $principal.Title in $ObjectType : $ObjectName."
                        }
                    }
                }
            }
        }
    }
    else {
        {
            Write-Host "$($ObjectType) : $($ObjectName) does not have unique permissions. Skipping." -ForegroundColor Yellow
        }
    }
    return $reportData
}

# Get all subsites
$web = Get-PnPWeb
$subWebs = Get-PnPSubWeb -Recurse

# Check permissions for the root web
$AllreportData += Process-Permissions -SecurableObject $web -ObjectName $web.Title -ObjectType "Web" -ReportingOnly $true

# Check permissions for subsites
foreach ($subWeb in $subWebs) {
    $AllreportData += Process-Permissions -SecurableObject $subWeb -ObjectName $subWeb.Title -ObjectType "Subsite" -ReportingOnly $true
}

# Get all lists and libraries
$lists = Get-PnPList | Where-Object { $_.Hidden -eq $false -and $excludedLists -notcontains $_.Title }

foreach ($list in $lists) {
    # Check permissions for the list/library
    $AllreportData += Process-Permissions -SecurableObject $list -ObjectName $list.Title -ObjectType "List/Library" -ReportingOnly $true
    
    # Get folders in the list/library
    $folders = Get-PnPFolder -List $list -Includes ListItemAllFields.HasUniqueRoleAssignments, ListItemAllFields.RoleAssignments
    
    foreach ($folder in $folders) {
        #$folder.ListItemAllFields.HasUniqueRoleAssignments
        #$hasUniquePermissions = Get-PnPProperty -ClientObject $folder -Property HasUniqueRoleAssignments
        $AllreportData += Process-Permissions -SecurableObject $folder -ObjectName $folder.Name -ObjectType "Folder" -ReportingOnly $true
    }
    
    # Get items/files in the list/library
    $items = Get-PnPListItem -List $list -Fields "FileLeafRef"
    foreach ($item in $items) {
        $itemName = $item["FileLeafRef"]
        $AllreportData += Process-Permissions -SecurableObject $item -ObjectName $itemName -ObjectType "Item/File" -ReportingOnly $true
    }
}

# Export to Excel if ReportingOnly is true
if ($ReportingOnly -and $AllreportData.Count -gt 0) {
    $excelPath = "C:\temp\PermissionReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"
    $AllreportData | Export-Excel -Path $excelPath -AutoSize -TableName "PermissionReport" -Title "SharePoint Permission Report"
    Write-Host "Report exported to $excelPath"
} elseif ($ReportingOnly -and $reportData.Count -eq 0) {
    Write-Host "No matching permissions found for reporting."
}

# Disconnect from SharePoint
Disconnect-PnPOnline
Write-Host "Script execution completed."