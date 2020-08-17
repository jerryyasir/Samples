cls

$ApplicationID = "5dbebc00-9595-433c-bc25-c4479e0e4a55"
$Password = ''
$appaaddomain = 'teannt.onmicrosoft.com'
$CurrentUser = "user@tenant.onmicrosoft.com"

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
	$TeamOwners = $team.Owners
	$DeleteExistingTeam = $team.DeleteExistingTeam
  
	#$url = "$GraphURL/groups?`$filter=displayName eq 'TeamABC'"
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
					$MemberUrl = "$graphV1Endpoint/users"
					$UserUserPrincipalName = $arrTeamMembers[$i]
					if ($UserUserPrincipalName -ne $CurrentUser) {
						#$arrayMembers.Add("$MemberUrl/$UserUserPrincipalName")
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
			$arrTeamOwners = $TeamOwners -split "#" 
			if ($arrTeamOwners) {
				for ($i = 0; $i -le ($arrTeamOwners.count - 1) ; $i++) {
					$OwnerUserPrincipalName = $arrTeamOwners[$i]
					$OwnerUrl = "$graphV1Endpoint/users"
					$arrayOwners.Add($OwnerUserPrincipalName)
				}
			}
		}
		Catch {
			Write-Host "There is issue with Channel settings in CSV, Check and Fix:. $teamchannels"
		}

		$arryGroupType = @("Unified")
		
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
		
		$FindOwnerUrl = "https://graph.microsoft.com/v1.0/users/" + $CurrentUser + "?`$Select=Id"
		$Response = Invoke-RestMethod -Uri $FindOwnerUrl -Headers @{Authorization = "Bearer $token" } -Method Get -ContentType "application/json" -Verbose
		if ($Response) {
			$Response.id
			$CurrentUserAsMemberUrl = "https://graph.microsoft.com/v1.0/directoryobjects/$($Response.id)"
					
			#$CurrentUserAsMember = "$graphV1Endpoint/groups/$TeamID/members/`$ref"
			#$body = [ordered]@{
			#	"@odata.id" = $CurrentUserAsMemberUrl
			#}
			#$bodyJSON = $body | ConvertTo-Json  
			#Invoke-RestMethod -Uri $CurrentUserAsMember -Headers @{Authorization = "Bearer $token"} -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
					
			#$PlannerUri = "$GraphURL/planner/plans"
			#$body = [ordered]@{
			#	owner = $TeamID;
			#   title = $TeamName;
			#}
			#$bodyJSON = $body | ConvertTo-Json  
			#Invoke-RestMethod -Uri $PlannerUri -Headers @{Authorization = "Bearer $token"} -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
			#Write-Host "      A planner plan $TeamName is now added to the Team." -ForegroundColor Green
		}
				
		$GroupUrl = "$graphV1Endpoint/groups"
		$body = [ordered]@{
			displayName          = $TeamName;
			description          = $Description;
			groupTypes           = $arryGroupType;
			mailEnabled          = $true;
			mailnickname         = $MailNickName;
			securityEnabled      = $false;
			"members@odata.bind" = $arrayMembersInREST;
			"owners@odata.bind"  = $arrayOwnersInREST;
		}
		
		$bodyJSON = $body | ConvertTo-Json  
		$Response = Invoke-RestMethod -Uri $GroupUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
		
		$GroupCreationResponse = $null
		$Stoploop = $false
		$GroupId = $null
		do {
			$GroupQueryUrl = $GroupUrl + "/?`$filter=displayName eq '" + $TeamName + "'"
			$GroupCreationResponse = Invoke-RestMethod -Uri $GroupQueryUrl -Headers @{Authorization = "Bearer $token" } -Method Get -Verbose  
			if ($GroupCreationResponse.value.Count -gt 0) {
				$Stoploop = $true
				foreach ($val in $GroupCreationResponse.value) {
					$GroupId = $val.Id
				}
				
			}
		}
		While ($Stoploop -eq $false)
		
		$memberSettings = @{}
		$memberSettings.Add("allowCreateUpdateChannels", $true)
		
		$messagingSettings = @{}
		$messagingSettings.Add("allowUserEditMessages", $true)
		$messagingSettings.Add("allowUserDeleteMessages", $false)

		$funSettings = @{}
		$funSettings.Add("allowGiphy", $true)
		$funSettings.Add("giphyContentRating", $true)
		
		#Create Team using Empty Template
		$TeamCreationUrl = "$GraphURL/groups/$GroupId/team"
		$body = [ordered]@{
		}
		$bodyJSON = $body | ConvertTo-Json
		
		$TeamCreationResponse = $null
		$TeamCreationResponse = Invoke-RestMethod -Uri $TeamCreationUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Put -ContentType "application/json" -Verbose
		if ($TeamCreationResponse -eq $null) {
			$Stoploop = $false
			do {
				$TeamCreationResponse = Invoke-RestMethod -Uri $getTeamFromGraphUrl -Headers @{Authorization = "Bearer $token" } -Method Get -Verbose  
				if ($TeamCreationResponse) {
					$Stoploop = $true
				}
			}
			While ($Stoploop -eq $false)
		}
		
      
		if ($TeamCreationResponse) {
			foreach ($t in $TeamCreationResponse) { 
				$newTeamDisplayName = $t.displayName
				$TeamId = $t.Id
				Write-Host "Team $newTeamDisplayName has been created successfully..." -ForegroundColor Green
				
			}
			
			
			Write-Host "Adding Channels to $newTeamDisplayName Team..." -ForegroundColor Yellow
			$TeamsChannelsUrl = "$GraphURL/teams/$TeamId/channels"
				
			try {
				$arrteamchannels = $TeamChannels -split "#" 
				if ($arrteamchannels) {
					for ($i = 0; $i -le ($arrteamchannels.count - 1) ; $i++) {
						$ChannelName = $arrteamchannels[$i]
						$ChannelDescription = "Channel 1 Description"
						$body = [ordered]@{
							displayName = $ChannelName;
							description = $ChannelDescription;
						}
						$bodyJSON = $body | ConvertTo-Json  
						Invoke-RestMethod -Uri $TeamsChannelsUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
						Write-Host "      Channel $ChannelName is now added to the Team." -ForegroundColor Green
					}
				}
			}
			Catch {
				Write-Host "There is issue with Channel settings in CSV, Check and Fix:. $teamchannels"
			}
			
			$GeneralChannelsUrl = "$TeamsChannelsUrl" + "?`$filter=displayName eq 'General'&`$select=Id"
			$GeneralChannelResponse = Invoke-RestMethod -Uri $GeneralChannelsUrl -Headers @{Authorization = "Bearer $token" } -Method Get -Verbose  
			$ChannelID = $GeneralChannelResponse.value[0].id
			$GeneralChannelMessageUrl = "$TeamsChannelsUrl/$ChannelID/messages"
			
			$Message = "Welcome to Microsoft Teams from Jerry Yasir"
			#$RootMessage = @{}
			$MessageBody = @{}
			#$MessageBody.Add("ContentType", 1)
			$MessageBody.Add("content", $Message)
			#$RootMessage.Add("body", $MessageBody)
			
			$body = [ordered]@{
				"body" = $MessageBody;
			}
			$bodyJSON = $body | ConvertTo-Json  

			Invoke-RestMethod -Uri $GeneralChannelMessageUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
			Write-Host "      Message has been posted on the Channel." -ForegroundColor Green

			[System.Guid]::NewGuid()
			$MessageBody = @{}
			$MessageBody.Add("contentType", "html")
			$MessageBody.Add("content", "<attachment id='c74512e29f9a49f29644a2b1faa4c3b1'></attachment>")
			$attachments = New-Object System.Collections.ArrayList
			$attachment = @{}
			$attachment.Add("id", "c74512e29f9a49f29644a2b1faa4c3b1")
			$attachment.Add("contentType", "application/vnd.microsoft.card.thumbnail")
			$attachment.Add("contentUrl", $null)
			$attachment.Add("content", "{\r\n  'title': 'This is an example of posting a card',\r\n  'subtitle': `
			'<h3>This is the subtitle</h3>',\r\n  'text': 'Here is some body text. <br>\r\nAnd a `
			<a href='http://microsoft.com/'>hyperlink</a>. <br>\r\nAnd below that is some buttons:',\r\n `
			'buttons': [\r\n    {\r\n      'type': 'messageBack',\r\n      'title': 'Login to FakeBot',\r\n      `
			'text': 'login',\r\n      'displayText': 'login',\r\n      'value': 'login'\r\n    }\r\n  ]\r\n}")
			$attachment.Add("name", $null)
			$attachment.Add("thumbnailUrl", $null)
			$attachments.Add($attachment)
			#$RootMessage.Add("body", $MessageBody)
			
			$body = [ordered]@{
				"subject"     = $null
				"body"        = $MessageBody;
				"attachments" = $attachments
			}
			$bodyJSON = $body | ConvertTo-Json  
			$bodyJSON | clip

			#Invoke-RestMethod -Uri $GeneralChannelMessageUrl -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
			#Write-Host "      Message has been posted on the Channel." -ForegroundColor Green
			
			#Adding Tab in General
			$TeamsUrl = "$GraphURL/teams/$TeamID"
			$TeamsAppsUrl = "$TeamsUrl/installedApps"
			
			$TabConfiguration = @{}
			$TabConfiguration.Add("entityId", $null)
			$TabConfiguration.Add("contentUrl", "https://www.bing.com/maps/embed?h=768&w=800&cp=39.90073511625853~-75.16744692848968&lvl=18&typ=d&sty=h&src=SHELL&FORM=MBEDV8")
			$TabConfiguration.Add("websiteUrl", "https://binged.it/2BqOkiG")
			$TabConfiguration.Add("removeUrl", $null)
			
			$TabPath = $GraphURL + "/appCatalogs/teamsApps/com.microsoft.teamspace.tab.web"
			$body = [ordered]@{
				"displayName"         = "Places to Go"
				"teamsApp@odata.bind" = $TabPath
				Configuration         = $TabConfiguration;
			}
			
			$bodyJSON = $body | ConvertTo-Json  
			$GeneralChannelTabs = "$TeamsChannelsUrl/$ChannelID/tabs"
			
			Invoke-RestMethod -Uri $GeneralChannelTabs -Headers @{Authorization = "Bearer $token" } -Body $bodyJSON -Method Post -ContentType "application/json" -Verbose
			Write-Host "      Tab has Added to the Channel." -ForegroundColor Green
		}
	  
	}

}
