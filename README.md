# Enable-MigrationBatchBasicAuth
This script targets migration batches and places users from these batches in a Azure AD group which allows Basic Auth.

````powershell
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
