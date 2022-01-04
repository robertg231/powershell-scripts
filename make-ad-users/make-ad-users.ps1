$dbzDataset = Import-Csv -path ".\DBZ-dataset.csv"

<#
$dbzDataset | ForEach-Object { 
    Write-Host "Name: $($_.Name)"
    Write-Host "Description: $($_.description)"
    Write-Host "Image URL: $($_.imageUrl)"
    }
#>


$dbzDataset | ForEach-Object { 
    #Write-Host "Name: $($_.Name)"

    #dataset has full name as name so we gotta split it up.
    $names = $_.Name.split(' ')

    $firstName = ""
    $lastName = ""
    $logonName = ""

    if( $names.length -eq 1)
    {
        $firstName = $names[0]
        $lastName = ""
        $logonName = "$($firstName)"
    }
    elseif( $names.length -eq 2)
    {
        $firstName = $names[0]
        $lastName = $names[1]
        $logonName = "$($firstName).$($lastName)"
    }
    elseif( $names.length -ge 3)
    {
        $firstName = $names[0]

        #creating last names with spaces
        for($i=1; $i -lt $names.length; $i++)
        {
            $lastName += "$($names[$i]) "
        }
        #remove extra space left at end
        $lastName = $lastName.Substring(0,$lastName.Length-1)
        
        #creating logon name with dots
        for($i = 0; $i -lt $names.length; $i++)
        {
            $logonName += "$($names[$i])."             
        }
        #remove extra period left at end
        $logonName =$logonName.Substring(0,$logonName.Length-1)
    }
    else
    {
        #somethign went wrong?
        write-host "something went wrong. names length less than 0??"
    }

    
    
    <#
    Write-Host "First Name: $($firstName)"
    Write-Host "Last Name: $($lastName)"
    Write-Host "Logon Name: $($logonName)"
    ""
    #>

    #TODO: figure out how to download and set user photo
    #$userPhoto = New-Object System.Net.WebClient
    #$userPhoto.DownloadFile($_.imageUrl) 

    #splatting https://www.pdq.com/blog/add-users-to-ad-with-powershell/
    $userAttributes = @{
        Enabled = $true
        ChangePasswordAtLogon = $false
        PasswordNeverExpires = $true

        Path = "OU=DBZ-Users,OU=goro-users,DC=goro,DC=local"

        #name can't be more than 20 characters or you get an error.
        Name = $_.Name
        DisplayName = $_.Name 
        
        
        UserPrincipalName = "$($logonName)@goro.local"
        SamAccountName = "$($logonName)"
        EmailAddress = "$($logonName)@goro.local"

        GivenName = $firstName
        Surname = $lastName

        
        Country = "JP" #country code for japan
        City = "Dragon Ball Town"
        Company = "Capsule Corp"
        Department = "Heroes"
        EmployeeID = [string](get-random -Minimum 100000 -Maximum 999999)
        MobilePhone = "($(get-random -minimum 800 -Maximum 850)) $(get-random -minimum 100 -Maximum 999)-$(get-random -minimum 1000 -Maximum 9999)"
        OfficePhone = "(760) 331-$(get-random -minimum 1000 -Maximum 9999)"
        Description = $_.description
        
        AccountPassword = "dragonB@lls" | ConvertTo-SecureString -AsPlainText -Force
    }


    #try to make the user, catch any errors that occur and write them to csv files
    $user = $_ 
    try
    {
        New-ADUser @userAttributes
    }
    catch
    {
        write-host -ForegroundColor Red "Error for $($user.name)"
        $user | export-csv -path .\nameErrors.csv -append -notypeinformation
        $_ | Export-Csv -path .\errors.csv -Append -NoTypeInformation
        
    }

    
}


#notes for other stuff
#when identifying the ous you gotta specify them backwards/reverse order. ex: goro.local/goro-users/DBZ-Users is identified as "OU=DBZ-Users,ou=goro-users,DC=goro,DC=local"

#moving dbz-users ou into the goro-users ou
#Move-ADObject -Identity "OU=DBZ-Users,DC=goro,DC=local" -TargetPath "OU=goro-users,DC=goro,DC=local"

#moving dbz-users ou to root ou
#Move-ADObject -Identity "OU=DBZ-Users,ou=goro-users,DC=goro,DC=local" -TargetPath "DC=goro,DC=local"