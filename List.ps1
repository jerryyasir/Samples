Connect-PnPOnline -Url "https://yourtenant.sharepoint.com/sites/yoursite" -Interactive

# Create Rooms List
New-PnPList -Title "Rooms" -Template GenericList -OnQuickLaunch

# Add columns to Rooms
Add-PnPField -List "Rooms" -DisplayName "Active" -InternalName "Active" -Id (New-Guid) -Group "Custom" -AddToDefaultView -Type Boolean

# Create Bookings List
New-PnPList -Title "Bookings" -Template GenericList -OnQuickLaunch

# Add columns to Bookings
Add-PnPField -List "Bookings" -DisplayName "Room" -InternalName "Room" -Id (New-Guid) -Group "Custom" -AddToDefaultView -Type Lookup -LookupList "Rooms" -LookupField "Title"
Add-PnPField -List "Bookings" -DisplayName "StartDateTime" -InternalName "StartDateTime" -Id (New-Guid) -Group "Custom" -AddToDefaultView -Type DateTime -DateTimeFormat DateAndTime
Add-PnPField -List "Bookings" -DisplayName "EndDateTime" -InternalName "EndDateTime" -Id (New-Guid) -Group "Custom" -AddToDefaultView -Type DateTime -DateTimeFormat DateAndTime
Add-PnPField -List "Bookings" -DisplayName "BookedBy" -InternalName "BookedBy" -Id (New-Guid) -Group "Custom" -AddToDefaultView -Type User
Add-PnPField -List "Bookings" -DisplayName "Status" -InternalName "Status" -Id (New-Guid) -Group "Custom" -AddToDefaultView -Type Choice -Choices "Active","Cancelled" -DefaultValue "Active"

# Optional: Add sample data to Rooms
Add-PnPListItem -List "Rooms" -Values @{"Title"="Conference Room A"; "Active"=$true}
Add-PnPListItem -List "Rooms" -Values @{"Title"="Conference Room B"; "Active"=$true}
Add-PnPListItem -List "Rooms" -Values @{"Title"="Inactive Room"; "Active"=$false}

# Optional: Add sample data to Bookings (assuming Room IDs from above; adjust as needed)
$roomA = Get-PnPListItem -List "Rooms" -Query "<View><Query><Where><Eq><FieldRef Name='Title' /><Value Type='Text'>Conference Room A</Value></Eq></Where></Query></View>"
Add-PnPListItem -List "Bookings" -Values @{"Room"=$roomA.Id; "StartDateTime"=(Get-Date "2025-10-13 09:00"); "EndDateTime"=(Get-Date "2025-10-13 10:00"); "BookedBy"="user@yourdomain.com"; "Status"="Active"}
