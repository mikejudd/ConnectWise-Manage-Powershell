function Connect-ConnectWiseManage {
    <#
    .SYNOPSIS
    This will create the connection to the manage server.
    
    .DESCRIPTION
    This will create a global variable that contains all needed connection and autherisiztion information.
    All other commands from the module will call this vatiable to get connection information.
    
    .PARAMETER Server
    The URL of your ConnectWise Mange server.
    Example: manage.mydomain.com
    
    .PARAMETER Company
    The login company that you are prompted with at logon.
    
    .PARAMETER MemberID
    The member that you are impersonating
    
    .PARAMETER IntegratorUser
    The integrator username
    docs: Member Impersonation
    
    .PARAMETER IntegratorPass
    The integrator password
    docs: Member Impersonation
    
    .PARAMETER pubkey
    Public API key created by a user
    docs: My Account
    
    .PARAMETER privatekey
    Private API key created by a user
    docs: My Account
    
    .EXAMPLE
    $Connection = @{
        Server = $Server
        IntegratorUser = $IntegratorUser
        IntegratorPass = $IntegratorPass
        Company = $Company 
        MemberID = $MemberID
    }
    Connect-ConnectWiseManage @Connection
    
    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/Manage/Developer_Guide#Authentication
    #>

    param(
        [Parameter(Mandatory=$true)]
        $Server,
        [Parameter(Mandatory=$true)]
        $Company,
        $MemberID,
        $IntegratorUser,
        $IntegratorPass,        
        $pubkey,
        $privatekey
    )
    
    # Check to make sure one of the full auth pairs is passed.
    ##TODO
    #if((!$MemberID -or !$IntegratorUser -or !$IntegratorPass) -and (!$pubkey -or !$privatekey)){}
    
    # If connecting with a public/private API key
    if($pubkey -and $privatekey){
        $Authstring  = $Company + '+' + $pubkey + ':' + $privatekey
        $encodedAuth  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)));
        $Headers=@{
            Authorization = "Basic $encodedAuth"
            'Cache-Control'= 'no-cache'
            Accept = 'application/vnd.connectwise.com+json; version=3.0.0'
        }             
    }

    # If connecting with an integrator account and memberid
    if($IntegratorUser -and $IntegratorPass){
        $URL = "https://$($Server)/v4_6_release/apis/3.0/system/members/$($MemberID)/tokens"
        # Create auth header to get auth header ;P
        $Authstring  = $Company + '+' + $IntegratorUser + ':' + $IntegratorPass
        $encodedAuth  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)));
        $Headers = @{
            Authorization = "Basic $encodedAuth"
            'x-cw-usertype' = "integrator"
            'Cache-Control'= 'no-cache'
            Accept = 'application/vnd.connectwise.com+json; version=3.0.0'
        }
        $Body = @{
            memberIdentifier = $MemberID
        }
    
        # Get an auth token
        $Result = Invoke-RestMethod -Method Post -Uri $URL -Headers $Headers -Body $Body -ContentType application/json

        # Create auth header
        $Authstring  = $Company + '+' + $Result.publicKey + ':' + $Result.privateKey
        $encodedAuth  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)));
        $Headers=@{
            Authorization = "Basic $encodedAuth"
           'Cache-Control'= 'no-cache'
           Accept = 'application/vnd.connectwise.com+json; version=3.0.0'
        }    
    }

    # Creat the Server Connection object    
    $global:CWServerConnection = @{
        Server = $Server
        Headers = $Headers
    }
    
}
function Get-CWConfig {
    <#
    .SYNOPSIS
    This function will allow you to search for Manage configurations.

    .PARAMETER Condition
    This is you search conditon to return the results you desire.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"

    .PARAMETER orderBy
    Parameter description

    .PARAMETER childconditions
    Parameter description

    .PARAMETER customfieldconditions
    Parameter description

    .PARAMETER page
    Parameter description

    .PARAMETER pageSize
    Parameter description

    .PARAMETER managedIdentifier
    Parameter description

    .EXAMPLE
    Get-CWConfig -Condition "name=`"$ConfigName`""
    This will return all the configs with a name that matches $ConfigName

    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Company&e=Configurations&o=GET
    #>

    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize,
        $managedIdentifier        
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/company/configurations"
    if($Condition){$URI += "?conditions=$Condition"}
    
    $Config = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Config
}
function Get-CWAddition {
    <#
    .SYNOPSIS
    This function will list additions to a Manage agreement.
        
    .PARAMETER AgreementID
    The agreement ID of the agreement the addition belongs to.
    
    .EXAMPLE
    Get-CWAddition -AgreementID $Agreement.id | where {$_.product.identifier -eq $AdditionName}
    
    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Finance&e=AgreementAdditions&o=GET
    #>
    param(
        $AgreementID,
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/finance/agreements/$AgreementID/additions"
    if($Condition){$URI += "?conditions=$Condition"}

    
    $Addition = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Addition
}
function Get-ChargeCode{
    <#
    .SYNOPSIS
    Gets a list of charge codes
    
    .EXAMPLE
    Get-ChargeCode
    
    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017

    .LINK
    http://labtechconsulting.com
    #>
    param(
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/system/reports/ChargeCode"
    
    $ChargeCode = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    
    # Clean the returned object up
    $Item = @{}
    For ($a=0; $a -lt $ChargeCode.row_values.count; $a++){
        For ($b=0; $b -lt $ChargeCode.column_definitions.count; $b++){
            $Property += @{$(($ChargeCode.column_definitions[$b] | Get-Member -MemberType NoteProperty).Name) = $($ChargeCode.row_values[$a][$b])}
        }
        $Item.add($Property.Description,$Property)
        Remove-Variable Property -ErrorAction SilentlyContinue
    }
    return $Item

}
function Update-CWAddition {
    <#
    .SYNOPSIS
    This will update an addition to an agreement.
        
    .PARAMETER AgreementID
    The ID of the agreement that you are updating. Get-CWAgreement

    .PARAMETER AdditionID
    The ID of the adition that you are updating. Get-CWAddition

    .PARAMETER Operation
    What you are doing with the value. 
    replace

    .PARAMETER Path
    The value that you want to perform the operation on.

    .PARAMETER Value
    The value of that operation.

    .EXAMPLE
    $UpdateParam = @{
        AgreementID = $Agreement.id
        AdditionID = $Addition.id
        Operation = 'replace'
        Path = 'quantity'
        Value = $UmbrellaCount
    }
    Update-CWAddition @UpdateParam

    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017
    
    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Finance&e=AgreementAdditions&o=UPDATE
    #>
    param(
        [Parameter(Mandatory=$true)]
        $AgreementID,
        [Parameter(Mandatory=$true)]
        $AdditionID,
        [Parameter(Mandatory=$true)]
        $Operation,
        [Parameter(Mandatory=$true)]
        $Path,
        [Parameter(Mandatory=$true)]
        $Value
    )

    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $Body =@(
        @{            
            op = $Operation
            path = $Path
            value = $Value      
        }
    )

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/finance/agreements/$AgreementID/additions/$AdditionID"
    $Addition = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method Patch -Body $(ConvertTo-Json $Body) -ContentType application/json
    
    return $Addition
}
function Get-CWAgreement {
    <#
    .SYNOPSIS
    This function will list agreements based on conditions.
        
    .PARAMETER Condition
    The search cryteria for your agreement.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"
   
    .EXAMPLE
    $Condition = "company/identifier=`"$($Config.company.identifier)`" AND parentagreementid = null AND cancelledFlag = False AND endDate > [$(Get-Date -format yyyy-MM-ddTHH:mm:sZ)]"
    Get-CWAgreement -Condition $Condition

    .NOTES
    Author: Chris Taylor
    Date: 7/28/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Finance&e=Agreements&o=GET    
    #>
    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/finance/agreements"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}

    
    $Agreement = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Agreement
}
function Get-CWCompany {
    <#
    .SYNOPSIS
    This function will list companies based on conditions.
        
    .PARAMETER Condition
    The search cryteria for your company.
    Example:
    (contact/name like "Fred%" and closedFlag = false) and dateEntered > [2015-12-23T05:53:27Z] or summary contains "test" AND  summary != "Some Summary"
   
    .EXAMPLE
    $Condition = "identifier=`"$($Config.company.identifier)`" and type/id IN (1,42,43,57)"
    Get-CWAgreement -Condition $Condition

    .NOTES
    Author: Chris Taylor
    Date: 8/14/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Company&e=Companies&o=GET  
    #>
    param(
        $Condition,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/company/companies"
    if($Condition){$URI += "?conditions=$Condition"}
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($page){$URI += "&page=$page"}
    
    $Agreement = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
    return $Agreement
}
function Get-CWTicket {
    param(
        $TicketID
    )
        if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }
    $Condition = "id = $TicketID"
    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/service/tickets?conditions=$Condition"

    try{
        $Ticket = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
        return $Ticket
    }
    catch{
        Write-Output "There was an error: $($Error[0])"
    }    
}
function Remove-CWAddition {
    <#
    .SYNOPSIS
    This function will remove additions from a Manage agreement.
        
    .PARAMETER AgreementID
    The AgreementID of the agreement the addition belongs to.

    .PARAMETER AdditionID
    The addition ID that you want to delete.

    
    .EXAMPLE
    Remove-CWAddition -AdditionID $Addition.id -AgreementID $AgreementID.id
    
    .NOTES
    Author: Chris Taylor
    Date: 8/16/2017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Finance&e=AgreementAdditions&o=DELETE
    #>
    param(
        $AgreementID,
        $AdditionID
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/finance/agreements/$AgreementID/additions/$AdditionID"

    
    $Addition = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method Delete
    return $Addition
}
function Get-CWTicketNote {
    param(
        $TicketID,
        $Conditions,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions,
        $page,
        $pageSize
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }
    
    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/service/tickets/$TicketID/notes"
    if($Conditions){
        $URI = "&conditions= $Conditions"
    }
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($URI -notlike "*\?*" -and $URI -like "*&*") {
        $URI = $URI -replace '(.*?)&(.*)', '$1?$2'
    }    

    try{
        $Ticket = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method GET
        return $Ticket
    }
    catch{
        Write-Output "There was an error: $($Error[0])"
    }    
}
function Remove-CWCompany {
    <#
    .SYNOPSIS
    This function will remove a company from Manage.
        
    .PARAMETER CompanyID
    The ID of the company that you want to delete.
   
    .EXAMPLE
    Remove-CWAgreement -CompanyID 123

    .NOTES
    Author: Chris Taylor
    Date: 8/162017

    .LINK
    http://labtechconsulting.com
    https://developer.connectwise.com/manage/rest?a=Company&e=Companies&o=DELETE  
    #>
    param(
        $CompanyID
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/company/companies/$CompanyID"
    try{
        $Agreement = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method Delete
        return $Agreement
    }
    catch{
        Write-Output "There was an error: $Error[0]"
    }    
}
function Find-CWTicket {
    param(
        $page,
        $pageSize,
        $conditions,
        [ValidateSet('asc','desc')] 
        $orderBy,
        $childconditions,
        $customfieldconditions
    )
    if(!$global:CWServerConnection){
        Write-Error "Not connected to a Manage server. Run Connect-ConnectWiseManage first."
        break
    }

    $Body = @{}
    switch ($PSBoundParameters.Keys) {
        'conditions'               { $Body.conditions               = $conditions               }
        'orderBy'                  { $Body.orderBy                  = $orderBy                  }
        'childconditions'          { $Body.childconditions          = $childconditions          }
        'customfieldconditions'    { $Body.customfieldconditions    = $customfieldconditions    }                       
    }
    $Body = $($Body | ConvertTo-Json)

    $URI = "https://$($global:CWServerConnection.Server)/v4_6_release/apis/3.0/service/tickets/search"
    if($childconditions){$URI += "&childconditions=$childconditions"}
    if($customfieldconditions){$URI += "&customfieldconditions=$customfieldconditions"}
    if($orderBy){$URI += "&orderBy=$orderBy"}
    if($pageSize){$URI += "&pageSize=$pageSize"}
    if($URI -notlike "*\?*" -and $URI -like "*&*") {
        $URI = $URI -replace '(.*?)&(.*)', '$1?$2'
    }

    try{
        $Ticket = Invoke-RestMethod -Headers $global:CWServerConnection.Headers -Uri $URI -Method Post -ContentType 'application/json' -Body $Body
        return $Ticket
    }
    catch{
        Write-Output "There was an error: $($Error[0])"
    }    
}
