<# 
.SYNOPSIS
This script targets migration batches and places users from these batches in a Azure AD group which allows Basic Auth.  

.DESCRIPTION
This was created to assist with the successful migration of remote clients from Exchange 2013 to Office 365. (See Notes) I must already have allowed the members of the group to use basic auth.  

## Enable-MigrationBatchBasicAuth.ps1 [-BasicAuthGroup <string[ObjectID]>] [-SearchString <string[Allows Wildcard]>] [-DifferentialScope <Int[Value]>]

.PARAMETER BasicAuthGroup
The BasicAuthGroup parameter details the ObjectId of the Azure Group which has been setup to allow Basic Authication.

.PARAMETER SearchString
The SearchString parameter allows administrators to be selective as to which migration batchs they would like be included. Default Value selects all migration batches.  

.PARAMETER DifferentialScope
The DifferentialScope parameter defines how many objects can be added or removed from the UserGroups in a single operation of the script. The goal of this setting is throttle bulk changes to limit the impact of misconfiguration by an administrator. What value you choose here will be dictated by your userbase and your script schedule. The default value is set to 10 Objects. 

.PARAMETER AutomationPSCredential
The DifferentialScope parameter defines how many objects can be added or removed from the UserGroups in a single operation of the script. The goal of this setting is throttle bulk changes to limit the impact of misconfiguration by an administrator. What value you choose here will be dictated by your userbase and your script schedule. The default value is set to 10 Objects. 

.EXAMPLE
Enable-MigrationBatchBasicAuth -BasicAuthGroup '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -SearchString "NYSite1*"

-- ENABLE BASIC AUTH FOR SELECT MIGRATION BATCHES --

In this example the script will collect any user which is included in migration batches "NYSite1*" and add the users to the Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2'

.EXAMPLE
Enable-MigrationBatchBasicAuth -BasicAuthGroup '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -DifferentialScope 20

-- ABLE BASIC AUTH FOR ALL MIGRATION BATCHES & INCREASE DIFFERENTIAL SCOPE TO 20 --

In this example the script will collect all migration batchs and adds 20 users to the group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2'

.LINK

Outlook prompts for password when Modern Authentication is enabled - https://support.microsoft.com/en-us/help/3126599/outlook-prompts-for-password-when-modern-authentication-is-enabled


.NOTES
This function requires that you have already created your Azure AD Group and have allowed members of this group to use Basic Authentication via conditional access policies.

Please note, when using Azure Automation with more than one user group the array should be set to JSON for example ['ObjectID','ObjectID']

[AUTHOR]
Joshua Bines, Consultant

Find me on:
* Web:     https://theinformationstore.com.au
* LinkedIn:  https://www.linkedin.com/in/joshua-bines-4451534
* Github:    https://github.com/jbines
  
[VERSION HISTORY / UPDATES]
0.0.1 20200706 - JBINES - Created the bare bones
1.0.0 20200706 - JBines - [MAJOR RELEASE] Other than that it works like a dream... 

[TO DO LIST / PRIORITY]

#>

Param 
(
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [String]$BasicAuthGroup,
    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [String]$SearchString = "*",
    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [Int]$DifferentialScope = 10,
    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [String]$AutomationPSCredential
)

    #Set VAR
    $counter = 0

# Success Strings
    $sString0 = "OUT-CMDlet:Remove-AzureADGroupMember"
    $sString1 = "IN-CMDlet:Add-AzureADGroupMember"

    # Info Strings
    $iString0 = "Updating Migration Batch Users to Azure AD Group"

# Warn Strings
    $wString0 = "CMDlet:Measure-Object;No Members found in Migration Batch"
    $wString1 = "CMDlet:Measure-Object;No Members found in Basic Auth Azure AD Group"

# Error Strings

    $eString2 = "Hey! You made it to the default switch. That shouldn't happen might be a null or returned value."
    $eString3 = "Hey! You hit the -DifferentialScope limit of $DifferentialScope. Let's break out of this loop and save some CPU time"
    $eString4 = "Hey! Help us out and put some users in the group."

    #Load Functions

    function Write-Log([string[]]$Message, [string]$LogFile = $Script:LogFile, [switch]$ConsoleOutput, [ValidateSet("SUCCESS", "INFO", "WARN", "ERROR", "DEBUG")][string]$LogLevel)
    {
           $Message = $Message + $Input
           If (!$LogLevel) { $LogLevel = "INFO" }
           switch ($LogLevel)
           {
                  SUCCESS { $Color = "Green" }
                  INFO { $Color = "White" }
                  WARN { $Color = "Yellow" }
                  ERROR { $Color = "Red" }
                  DEBUG { $Color = "Gray" }
           }
           if ($Message -ne $null -and $Message.Length -gt 0)
           {
                  $TimeStamp = [System.DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
                  if ($LogFile -ne $null -and $LogFile -ne [System.String]::Empty)
                  {
                         Out-File -Append -FilePath $LogFile -InputObject "[$TimeStamp] [$LogLevel] $Message"
                  }
                  if ($ConsoleOutput -eq $true)
                  {
                         Write-Host "[$TimeStamp] [$LogLevel] :: $Message" -ForegroundColor $Color

                    if($AutomationPSCredential)
                    {
                         Write-Output "[$TimeStamp] [$LogLevel] :: $Message"
                    } 
                  }
           }
    }

    #Validate Input Values From Parameter 

    Try{

        if ($AutomationPSCredential) {
            
            $Credential = Get-AutomationPSCredential -Name $AutomationPSCredential

            Connect-AzureAD -Credential $Credential
            
            #$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection
            #Import-PSSession $Session -DisableNameChecking -Name ExSession -AllowClobber:$true | Out-Null

            $ExchangeOnlineSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection -Name $ConnectionName 
            Import-Module (Import-PSSession -Session $ExchangeOnlineSession -AllowClobber -DisableNameChecking) -Global

            }
                            
        #New Array of migrated users
        $MigrationBatchesUsers = Get-MigrationUser | Where-Object {$_.BatchId -like $SearchString} | ForEach-Object{Get-AzureADUser -ObjectId $_.Identity }

        #Check if No migrated users can be found.
        $MigrationBatchesUsersNull = $False
        if($MigrationBatchesUsers.count -eq 0){
            $MigrationBatchesUsersNull = $True
            If($?){Write-Log -Message $wString0 -LogLevel WARN -ConsoleOutput}
        }

        #Get Basic Auth Group Details
        $BasicAuthGroupobj = Get-AzureADGroup -ObjectId $BasicAuthGroup
        
        #Get Basic Auth group members
        $BasicAuthGroupMembers = Get-AzureADGroupMember -ObjectId $BasicAuthGroup -All:$true
        
        #Check if Basic Auth Group Members eq $Null
        $BasicAuthGroupMembersNull = $False
        if($BasicAuthGroupMembers.count -eq 0){
            $BasicAuthGroupMembersNull = $True
            If($?){Write-Log -Message $wString1 -LogLevel WARN -ConsoleOutput}
        }

    }
    
    Catch{
    
        $ErrorMessage = $_.Exception.Message
        Write-Error $ErrorMessage

            If($?){Write-Log -Message $ErrorMessage -LogLevel Error -ConsoleOutput}

        Break

    }

        
        Write-Log -Message "$iString0 - $($BasicAuthGroupobj.DisplayName)" -LogLevel INFO -ConsoleOutput

        switch ($BasicAuthGroupMembersNull) {
            {(-not($BasicAuthGroupMembersNull))-and(-not($MigrationBatchesUsersNull))}{ 
                                                                                    
                                                                                    #Compare Lists and find missing users those who should be removed. 
                                                                                    $assessUsers = Compare-Object -ReferenceObject $MigrationBatchesUsers.ObjectID -DifferenceObject $BasicAuthGroupMembers.ObjectId | Where-Object {$_.SideIndicator -ne "=="}
                                                                                    
                                                                                    if($null -ne $assessUsers){

                                                                                        Foreach($objUser in $assessUsers){  

                                                                                            if ($counter -lt $DifferentialScope) {

                                                                                                # <= -eq Add Object
                                                                                                # = -eq Skip
                                                                                                # => -eq Remove Object

                                                                                                Switch ($objUser.SideIndicator) {
                                                                                
                                                                                                    "=>" { 
                                                                                                    
                                                                                                        $objID = $objUser.InputObject
                                                                                                        $objUPN = (Get-AzureADUser -ObjectId $objID).UserPrincipalName 

                                                                                                        try {

                                                                                                            Remove-AzureADGroupMember -ObjectId $BasicAuthGroup -MemberId  $objID

                                                                                                            if($?){Write-Log -Message "$sString0;UPN:$objUPN;ObjectId:$objID" -LogLevel SUCCESS -ConsoleOutput}
                        
                                                                                                        }
                                                                                                        catch {
                                                                                                            Write-log -Message $_.Exception.Message -ConsoleOutput -LogLevel ERROR
                                                                                                            Break                                                                                   
                                                                                                        }
                                                                                                        
                                                                                                        #Increase the count post change
                                                                                                        $counter++
                                                                                
                                                                                                        $objID = $null
                                                                                                        $objGroupID = $null
                                                                                                        $objUPN = $null
                                                                                                        
                                                                                                            }
                                                                                
                                                                                                    "<=" { 

                                                                                                        $objID = $objUser.InputObject
                                                                                                        $objUPN = (Get-AzureADUser -ObjectId $objID).UserPrincipalName 

                                                                                                        Add-AzureADGroupMember -ObjectId $BasicAuthGroup -RefObjectId $objID

                                                                                                        if($?){Write-Log -Message "$sString1;UPN:$objUPN;ObjectId:$objID" -LogLevel SUCCESS -ConsoleOutput}

                                                                                                        #Increase the count post change
                                                                                                        $counter++
                                                                                
                                                                                                        $objID = $null
                                                                                                        $objGroupID = $null
                                                                                                        $objUPN = $null
                                                                                
                                                                                                            }
                                                                                
                                                                                                    Default {Write-log -Message $eString2 -ConsoleOutput -LogLevel ERROR }
                                                                                                }
                                                                                            }
                                                                                
                                                                                            else {
                                                                                                       
                                                                                                #Exceeded couter limit
                                                                                                Write-log -Message $eString3 -ConsoleOutput -LogLevel ERROR
                                                                                                Break
                                                                                
                                                                                            }  
                                                                                
                                                                                        }
                                                                                    }

                                                                                }
            {($BasicAuthGroupMembersNull-and(-not($MigrationBatchesUsersNull)))}{ 
                                                                                
                                                                                foreach($objGroupMember in $MigrationBatchesUsers){
                                                                                    if ($counter -lt $DifferentialScope) {

                                                                                        $objID = $objGroupMember.ObjectID
                                                                                        $objUPN = (Get-AzureADUser -ObjectId $objID).UserPrincipalName 

                                                                                        Add-AzureADGroupMember -ObjectId $BasicAuthGroup -RefObjectId $objID
                                                                                        if($?){Write-Log -Message "$sString1;UPN:$objUPN;ObjectId:$objID" -LogLevel SUCCESS -ConsoleOutput}

                                                                                        #Increase the count post change
                                                                                        $counter++
                                                                
                                                                                        $objID = $null
                                                                                        $objGroupID = $null
                                                                                        $objUPN = $null
                                                                                    }
                                                                                    else {
                                                                                    
                                                                                        #Exceeded couter limit
                                                                                        Write-log -Message $eString3 -ConsoleOutput -LogLevel ERROR
                                                                                        Break
                                                                        
                                                                                    }  
                                                                                }
                                                                            }
            {(-not($BasicAuthGroupMembersNull))-and($MigrationBatchesUsersNull)}{ 
                                                                                    
                                                                            foreach($objBasicAuthGroupMembers in $BasicAuthGroupMembers){
                                                                                if ($counter -lt $DifferentialScope) {
                                                                                
                                                                                    $objID = $objBasicAuthGroupMembers.ObjectID
                                                                                    $objUPN = $objBasicAuthGroupMembers.UserPrincipalName 

                                                                                    try {

                                                                                        Remove-AzureADGroupMember -ObjectId $BasicAuthGroup -MemberId $objID
                                                                                        if($?){Write-Log -Message "$sString0;UPN:$objUPN;ObjectId:$objID" -LogLevel SUCCESS -ConsoleOutput}
    
                                                                                    }
                                                                                    catch {
                                                                                        Write-log -Message $_.Exception.Message -ConsoleOutput -LogLevel ERROR
                                                                                        Break                                                                                   
                                                                                    }
                                                                
                                                                                    #Increase the count post change
                                                                                    $counter++
                                                                                    
                                                                                    $objID = $null
                                                                                    $objGroupID = $null
                                                                                    $objUPN = $null

                                                                                }

                                                                                else {
                                                                                
                                                                                    #Exceeded couter limit
                                                                                    Write-log -Message $eString3 -ConsoleOutput -LogLevel ERROR
                                                                                    Break
                                                                    
                                                                                }      
                                                                            }
                                                                        }
            Default {Write-Log -Message $eString4 -LogLevel ERROR -ConsoleOutput}
        }

if ($AutomationPSCredential) {
    
    #Invoke-Command -Session $ExchangeOnlineSession -ScriptBlock {Remove-PSSession -Session $ExchangeOnlineSession}

    Disconnect-AzureAD
}
