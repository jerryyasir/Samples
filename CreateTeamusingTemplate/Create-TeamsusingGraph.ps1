Clear-Host

#$scopes = $null
$scopes = @("Group.Read.All", "Group.ReadWrite.All", "User.ReadWrite.All", "Directory.Read.All", "Reports.Read.All")

#Graph URLs - uncomment one to run
#Get all groups
#$url = "https://graph.microsoft.com/v1.0/groups?`$filter=groupTypes/any(c:c eq 'Unified')&`$select=displayname,resourceProvisioningOptions"
#$url = "$GraphURL/groups?`$filter=resourceProvisioningOptions/Any(x:x eq 'Team')"

$GraphURL = "https://graph.microsoft.com/beta"
$graphV1Endpoint = "https://graph.microsoft.com/v1.0"

#Establish connection
If ($scopes.Length -gt 0) {
	Connect-PnPOnline -Scopes $scopes
}
elseif ($ApplicationID.Length -gt 0) {
	#Connect-PnPOnline -AppId $ApplicationID -AppSecret $Password -AADDomain $appaaddomain
	Connect-PnPMicrosoftGraph -AppId $ApplicationID -AppSecret $Password -AADDomain $appaaddomain
}
else {
	write-host 'Connection issue' -ForegroundColor Red
	exit
}

$token = Get-PnPGraphAccessToken

$CSVPath = "C:\temp\CreateTeam-Basic-Graph.xlsx"
$Data = Import-Excel -Path $CSVPath

foreach ($team in $Data) {
	Write-Host "Team Creation Started..." $team.TeamsName -ForegroundColor Yellow
	$TeamName = $team.TeamName
	$displayname = $team.TeamName
	$MailNickName = $team.MailNickName
	$AccessType = $team.TeamType 
	$Description = $team.Description 
	$Classification = $team.Classification
	$TeamChannels = $team.Channels
	$TeamMembers = $team.Members
	$TeamOwners = $team.Owner
	$DeleteExistingTeam = $team.DeleteExistingTeam
  
	$getTeamFromGraphUrl = "$GraphURL/groups?`$filter=displayName eq '" + $TeamName + "'"
	$teamAlreadyExistResponse = Invoke-RestMethod -Uri $getTeamFromGraphUrl -Headers @{Authorization = "Bearer $token" }
	if ($teamAlreadyExistResponse.value.Count -gt 0) {
		foreach ($r in $teamAlreadyExistResponse.value) { 
			if ($r.resourceProvisioningOptions -eq 'Team') {
        
				$GroupCreatedDateTime = $r.createdDateTime
				
				$TeamID = $r.id
				$TeamsOwnerUrl = "$GraphURL/groups/$TeamID/owners"
				$teamsOwnersResponse = Invoke-RestMethod -Uri $TeamsOwnerUrl -Headers @{Authorization = "Bearer $token" }
				$OwnerName = ""
				if ($teamsOwnersResponse) {
					Write-Host "    Team Owners:" 
					foreach ($owner in $teamsOwnersResponse.value) {
						$OwnerName += $owner.displayName + ";"
					}
					$teamsOwnersResponse = $null
				}
				write-host "The Team $($r.displayname) Created On $GroupCreatedDateTime Owned by $OwnerName already exist on the tenant." -ForegroundColor Yellow
				
				if ($DeleteExistingTeam) {
					
				}
			
			}
			else {
				write-host $r.displayname "is an O365 Group." -ForegroundColor Green
			}
		}
	}
	else {
		$arrayMembers = New-Object System.Collections.ArrayList
		try {
			$arrTeamMembers = $TeamMembers -split "#" 
			if ($arrTeamMembers) {
				for ($i = 0; $i -le ($arrTeamMembers.count - 1) ; $i++) {
					$UserUserPrincipalName = $arrTeamMembers[$i]
					if ($UserUserPrincipalName -ne $CurrentUser) {
						$arrayMembers.Add($UserUserPrincipalName)
					}
				}
			}
		}
		Catch {
			Write-Host "There is issue with Channel settings in CSV, Check and Fix:. $teamchannels"
		}

		$arrayOwners = New-Object System.Collections.ArrayList
			
		try {
			$arrayOwners.Add($TeamOwners)
		}
		Catch {
			Write-Host "There is issue with Channel settings in CSV, Check and Fix:. $teamchannels"
		}

		$arrayOwnersInREST = New-Object System.Collections.ArrayList
		$arrayMembersInREST = New-Object System.Collections.ArrayList
		foreach ($Member in $arrayMembers) {
			$FindMemberUrl = "https://graph.microsoft.com/v1.0/users/" + $Member + "?`$Select=Id"
			$Response = Invoke-RestMethod -Uri $FindMemberUrl -Headers @{Authorization = "Bearer $token" } -Method Get -ContentType "application/json" -Verbose
			if ($Response) {
				$Response.id
				$MembersUrl = "https://graph.microsoft.com/v1.0/Users/$($Response.id)"
				$arrayMembersInREST.Add($MembersUrl)
			}
		}
		foreach ($owner in $arrayOwners) {
			$FindOwnerUrl = "https://graph.microsoft.com/v1.0/users/" + $owner + "?`$Select=Id"
			$Response = Invoke-RestMethod -Uri $FindOwnerUrl -Headers @{Authorization = "Bearer $token" } -Method Get -ContentType "application/json" -Verbose
			if ($Response) {
				$Response.id
				$OwnerUrl = "https://graph.microsoft.com/v1.0/Users/$($Response.id)"
				$arrayOwnersInREST.Add($OwnerUrl)
			}
		}

		$TeamCreationUrl = "$GraphURL/teams"
		$memberSettings = @{}
		$memberSettings.Add("allowCreateUpdateChannels", $true)
		
		$messagingSettings = @{}
		$messagingSettings.Add("allowUserEditMessages", $true)
		$messagingSettings.Add("allowUserDeleteMessages", $false)

		$funSettings = @{}
		$funSettings.Add("allowGiphy", $true)
		$funSettings.Add("giphyContentRating", $true)
		
		$body = [ordered]@{
			"template@odata.bind" = "https://graph.microsoft.com/beta/teamsTemplates('educationClass')"
			displayName           = $TeamName
			Classification        = $Classification
			description           = $Description
			"owners@odata.bind"   = $arrayOwnersInREST
		}

		$bodyJSON = $body | ConvertTo-Json
		$TeamCreationResponse = $null
		Invoke-RestMethod -Uri $TeamCreationUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
		Start-Sleep -Seconds 5

		$getTeamFromGraphUrl = "$GraphURL/groups?`$filter=displayName eq '" + $TeamName + "'"
		$TeamCreationResponse = Invoke-RestMethod -Uri $getTeamFromGraphUrl -Headers @{Authorization = "Bearer $token" } -Method Get -ContentType "application/json" -Verbose
		
		if ($TeamCreationResponse -eq $null) {
			$Stoploop = $false
			do {
				$TeamCreationResponse = Invoke-RestMethod -Uri $getTeamFromGraphUrl -Headers @{Authorization = "Bearer $token" } -Method Get -Verbose  
				if ($TeamCreationResponse) {
					foreach ($val in $TeamCreationResponse.value) {
						$TeamID = $val.Id
					}
					$Stoploop = $true
				}
			}
			While ($Stoploop -eq $false)
		}

		if ($TeamCreationResponse) {
			foreach ($t in $TeamCreationResponse.value) { 
				$newTeamDisplayName = $t.displayName
				$TeamId = $t.Id
				Write-Host "Team $newTeamDisplayName has been created successfully..." -ForegroundColor Green
				
			}
		}

		if ($TeamId.Length -eq 0) {
			return;
		}
		
		Write-Host "Adding Channels to $newTeamDisplayName Team..." -ForegroundColor Yellow
		$TeamsChannelsUrl = "$GraphURL/teams/$TeamId/channels"
				
		try {
			$arrteamchannels = $TeamChannels -split "#" 
			if ($arrteamchannels) {
				for ($i = 0; $i -le ($arrteamchannels.count - 1) ; $i++) {
					$ChannelName = $arrteamchannels[$i]
					$ChannelDescription = "$ChannelName Description"
					$body = [ordered]@{
						displayName    = $ChannelName;
						description    = $ChannelDescription;
						membershipType = "standard"
					}
					$bodyJSON = $body | ConvertTo-Json  

					$ChannelResponse = Invoke-RestMethod -Uri $TeamsChannelsUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
					if ($ChannelResponse -eq $null) {
						$Stoploop = $false
						do {
							Write-Host "Trying another time..." -ForegroundColor Yellow
							$ChannelResponse = Invoke-RestMethod -Uri $TeamsChannelsUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
							if ($ChannelResponse) {
								$Stoploop = $true
							}
						}
						While ($Stoploop -eq $false)
					}
					Write-Host "      Channel $ChannelName is now added to the Team." -ForegroundColor Green
				}
			}
		}
		Catch {
			Write-Host "There is issue with Channel settings in CSV, Check and Fix:. $teamchannels"
		}

		$TeamsChannelsUrl = "$GraphURL/teams/$TeamId/channels"
			
		$GeneralChannelsUrl = "$($TeamsChannelsUrl)?$filter=displayName eq 'General' + '&$select=Id'"
		$GeneralChannelResponse = Invoke-RestMethod -Uri $GeneralChannelsUrl -Headers @{Authorization = "Bearer $token" } -Method Get -Verbose
		$ChannelID = $GeneralChannelResponse.value[0].id
		$GeneralChannelMessageUrl = "$TeamsChannelsUrl/$ChannelID/messages"
			
		$Message = "Welcome to Microsoft Teams from Jerry Yasir"
		$MessageBody = @{}
		$MessageBody.Add("content", $Message)
		
			
		$body = [ordered]@{
			body = $MessageBody;
		}
		$bodyJSON = $body | ConvertTo-Json  

		Invoke-RestMethod -Uri $GeneralChannelMessageUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
		Write-Host "      Message has been posted on the Channel." -ForegroundColor Green

		#Adding Tab in General
		$TeamsUrl = "$GraphURL/teams/$TeamID"
		$TeamsAppsUrl = "$TeamsUrl/installedApps"
			
		$TabConfiguration = @{}
		$TabConfiguration.Add("entityId", $null)
		$TabConfiguration.Add("contentUrl", 'https://www.bing.com/maps/embed?h=768&w=800&cp=39.90073511625853~-75.16744692848968&lvl=18&typ=d&sty=h&src=SHELL&FORM=MBEDV8')
		$TabConfiguration.Add("websiteUrl", "https://binged.it/2BqOkiG")
		$TabConfiguration.Add("removeUrl", $null)
			
		$TabPath = $GraphURL + "/appCatalogs/teamsApps/com.microsoft.teamspace.tab.web"
		$body = [ordered]@{
			displayName           = "Places to Go"
			"teamsApp@odata.bind" = $TabPath
			Configuration         = $TabConfiguration;
		}
			
		$bodyJSON = $body | ConvertTo-Json  
		$GeneralChannelTabs = "$TeamsChannelsUrl/$ChannelID/tabs"
		Invoke-RestMethod -Uri $GeneralChannelTabs -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json"

		Write-Host "Adding Members to Team"
		#Code below is not working due an issue in the API switching to V1 below
		# $roles = New-Object System.Collections.ArrayList
		# $roles.Add("member")
		
		# $TeamsMembersUrl = $GraphURL + "/teams/" + $TeamId + "/members"
		# foreach ($member in $arrayMembers) {
		# 	$FindOwnerUrl = $graphV1Endpoint + "/users/" + $member
		# 	$Response = Invoke-RestMethod -Uri $FindOwnerUrl -Headers @{Authorization = "Bearer $token" } -Method Get -ContentType "application/json" -Verbose
		# 	$MemberUrl = $GraphURL + "/users/" + $Response.id
		
		# 	$odata = #microsoft.graph.aadUserConversationMember
		# 	$body = @{
		# 		"@odata.type"     = $odata
		# 		roles             = $roles
		# 		"user@odata.bind" = $MemberUrl
		# 	}
		
		# $bodyJSON = $body | ConvertTo-Json
		# Invoke-RestMethod -Uri $TeamsMembersUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json"
		# }

		$TeamsMembersUrl = $graphV1Endpoint + "/groups/$TeamId"
		$body = @{
			"members@odata.bind" = $arrayMembersInREST
		}
		$bodyJSON = $body | ConvertTo-Json
		Invoke-RestMethod -Uri $TeamsMembersUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Patch -ContentType "application/json"
		
	}
	Write-Host "Team Creation Process has been Completed." -ForegroundColor Green
}
