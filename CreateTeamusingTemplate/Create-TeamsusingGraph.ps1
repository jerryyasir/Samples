cls

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
	$SecondryOwners = $team.SecondryOwners
	$TeamMembers = $team.Members
	$TeamOwners = $team.'Primary Owner'
	$DeleteExistingTeam = $team.DeleteExistingTeam
	$Message = $team.Message
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
			Write-Host "There is issue with Members in CSV, Check and Fix:. $teamchannels"
		}

		$arraySecondryOwners = New-Object System.Collections.ArrayList
		try {
			$splitSecondryOwners = $SecondryOwners -split "#" 
			if ($splitSecondryOwners) {
				for ($i = 0; $i -le ($splitSecondryOwners.count - 1) ; $i++) {
					$UserUserPrincipalName = $splitSecondryOwners[$i]
					if ($UserUserPrincipalName -ne $CurrentUser) {
						$arraySecondryOwners.Add($UserUserPrincipalName)
					}
				}
			}
		}
		Catch {
			Write-Host "There is issue with Secondry Owners in CSV, Check and Fix:. $teamchannels"
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
		$arraySecondryOwnersInREST = New-Object System.Collections.ArrayList
		foreach ($Member in $arrayMembers) {
			$FindMemberUrl = $graphV1Endpoint + "/users/" + $Member + "?`$Select=Id"
			$Response = Invoke-RestMethod -Uri $FindMemberUrl -Headers @{Authorization = "Bearer $token" } -Method Get -ContentType "application/json"
			if ($Response) {
				$Response.id
				$MembersUrl = "$graphV1Endpoint/users/$($Response.id)"
				$arrayMembersInREST.Add($MembersUrl)
			}
		}
		foreach ($owner in $arrayOwners) {
			$FindOwnerUrl = "$graphV1Endpoint/users/" + $owner + "?`$Select=Id"
			$Response = Invoke-RestMethod -Uri $FindOwnerUrl -Headers @{Authorization = "Bearer $token" } -Method Get -ContentType "application/json" 
			if ($Response) {
				$Response.id
				$OwnerUrl = "$graphV1Endpoint/users/$($Response.id)"
				$arrayOwnersInREST.Add($OwnerUrl)
			}
		}
		foreach ($owner in $arraySecondryOwners) {
			$FindOwnerUrl = "$graphV1Endpoint/users/" + $owner + "?`$Select=Id"
			$Response = Invoke-RestMethod -Uri $FindOwnerUrl -Headers @{Authorization = "Bearer $token" } -Method Get -ContentType "application/json"
			if ($Response) {
				$Response.id
				$aSecondryOwnerUrl = "$graphV1Endpoint/users/$($Response.id)"
				$arraySecondryOwnersInREST.Add($aSecondryOwnerUrl)
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
			description           = $Description
			"owners@odata.bind"   = $arrayOwnersInREST
		}

		$bodyJSON = $body | ConvertTo-Json
		$TeamCreationResponse = $null
		Invoke-RestMethod -Uri $TeamCreationUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json" 
		Start-Sleep -Seconds 2

		$getTeamFromGraphUrl = "$GraphURL/groups?`$filter=displayName eq '" + $TeamName + "'"
		$TeamCreationResponse = Invoke-RestMethod -Uri $getTeamFromGraphUrl -Headers @{Authorization = "Bearer $token" } -Method Get -ContentType "application/json" 
		
		if ($TeamCreationResponse.value.Count -eq 0) {
			$Stoploop = $false
			do {
				Write-Host "Retrying Teams Creation..."
				$TeamCreationResponse = Invoke-RestMethod -Uri $getTeamFromGraphUrl -Headers @{Authorization = "Bearer $token" } -Method Get -ContentType "application/json" 
				if ($TeamCreationResponse) {
					foreach ($val in $TeamCreationResponse.value) {
						$TeamID = $val.Id
					}
					$Stoploop = $true
				}
				Start-Sleep -Seconds 2
			}
			While ($Stoploop -eq $false)
		}

		if ($TeamCreationResponse.value.Count -gt 0) {
			foreach ($t in $TeamCreationResponse.value) { 
				$newTeamDisplayName = $t.displayName
				$TeamId = $t.Id
				Write-Host "Team $newTeamDisplayName has been created successfully..." -ForegroundColor Green

				if ($TeamId.Length -eq 0) {
					return;
				}
			}
		}

		
		Write-Host "Adding Channels to $newTeamDisplayName Team..." -ForegroundColor Yellow
		$TeamsChannelsUrl = "$GraphURL/teams/$TeamId/channels"
				
		try {
			$arrteamchannels = $TeamChannels -split "#" 
			if ($arrteamchannels) {
				for ($i = 0; $i -le ($arrteamchannels.count - 1) ; $i++) {
					Start-Sleep -Seconds 1
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

		#Adding Tab in General
		#$TeamsUrl = "$GraphURL/teams/$TeamID"
		#$TeamsAppsUrl = "$TeamsUrl/installedApps"
			
		#$TabConfiguration = @{}
		#$TabConfiguration.Add("entityId", $null)
		# $TabConfiguration.Add("contentUrl", 'https://www.bing.com/maps/embed?h=768&w=800&cp=39.90073511625853~-75.16744692848968&lvl=18&typ=d&sty=h&src=SHELL&FORM=MBEDV8')
		# $TabConfiguration.Add("websiteUrl", "https://binged.it/2BqOkiG")
		# $TabConfiguration.Add("removeUrl", $null)
			
		# $TabPath = $GraphURL + "/appCatalogs/teamsApps/com.microsoft.teamspace.tab.web"
		# $body = [ordered]@{
		# 	displayName           = "Places to Go"
		# 	"teamsApp@odata.bind" = $TabPath
		# 	Configuration         = $TabConfiguration;
		# }
		
		# $bodyJSON = $body | ConvertTo-Json  
		# $GeneralChannelTabs = "$TeamsChannelsUrl/$ChannelID/tabs"
		# Invoke-RestMethod -Uri $GeneralChannelTabs -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json"

		# Write-Host "Places to go Tab has been Added." -ForegroundColor Green
		Start-Sleep -Seconds 1
		$TeamsMembersUrl = $graphV1Endpoint + "/groups/$TeamId"
		$body = @{
			"members@odata.bind" = $arrayMembersInREST
		}
		$bodyJSON = $body | ConvertTo-Json
		Invoke-RestMethod -Uri $TeamsMembersUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Patch -ContentType "application/json"
		
		Start-Sleep -Seconds 1
		$TeamsMembersUrl = $TeamsMembersUrl + "/owners/`$ref"
		foreach ($secOwner in $arraySecondryOwnersInREST) {
			$body = @{
				"@odata.id" = $secOwner 
			}
			$bodyJSON = $body | ConvertTo-Json
			Invoke-RestMethod -Uri $TeamsMembersUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json"
		}

		Start-Sleep -Seconds 5
		$TeamsChannelsUrl = "$GraphURL/teams/$TeamId/channels"
		Start-Sleep -Seconds 1	
		$GeneralChannelsUrl = "$($TeamsChannelsUrl)?$filter=displayName eq 'General' + '&$select=Id'"
		$GeneralChannelResponse = Invoke-RestMethod -Uri $GeneralChannelsUrl -Headers @{Authorization = "Bearer $token" } -Method Get
		$ChannelID = $GeneralChannelResponse.value[0].id
		$GeneralChannelMessageUrl = "$TeamsChannelsUrl/$ChannelID/messages"
			
		$MessageBody = @{}
		$MessageBody.Add("content", $Message)
		
			
		$body = [ordered]@{
			body = $MessageBody;
		}
		$bodyJSON = $body | ConvertTo-Json  

		Invoke-RestMethod -Uri $GeneralChannelMessageUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
		Write-Host "      Message has been posted on the Channel." -ForegroundColor Green

		
		
	}
	Write-Host "Team $($TeamName) Created Successfully. Moving to Next Team" -ForegroundColor Green
}
