#-----Script Info---------------------------------------------------------------------------------------------
# Name:XwikiPS.psm1
# Author: Einar Stenberg 
# mail:einar@stenberg.im
# Date: 15.09.2015
# Version: 3
# Job/Tasks: Powershell module for interfacing with Xwiki
#--------------------------------------------------------------------------------------------------------------


#-----Changelog------------------------------------------------------------------------------------------------
#v1.  Script created ES
#v2.  Added support for searching specific spaces
#v3.  Added switch forcessl for get-xwikipage
#--------------------------------------------------------------------------------------------------------------





#-----Functions---------------------------------------------------------------------------------------------

Function Connect-Xwiki {
<#
.SYNOPSIS
Creates authentication abject for xwiki
.DESCRIPTION
For authenticating xwiki invoke-restmethod wrapper
Part of PVEPS by ES
.EXAMPLE
Connect-Xwiki -username johndoe -password secret
#>

Param(
[Parameter(Mandatory=$true,Position=0)]
[string]$Username,
[Parameter(Mandatory=$true,Position=1)]
[string]$Password,
[switch]$SaveToProfile,
[Parameter(Position=2)]
[string]$XwikiUrl,
[Parameter(Position=3)]
[string]$Xdefaultwiki
)

If ($Password -and $Username){
    $xwikicred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username,$Password)))

    $Global:xwikicred=$xwikicred
    
}
Else { Write-Host "Missing password, username!"}



If ($SaveToProfile -and $Password -and $Username) {
    #Creates profile file if it does not exist already
    if (!(Test-Path $Profile)){New-Item -Type File -Force $Profile; Add-Content $Profile ""}
    #Removes old entry in profile
    $tempprofile=Get-Content $Profile | ForEach-Object {if ($_ -notlike "`$xwikicred*"){$_}}
    $tempprofile | Set-Content $Profile
    #Adds new entry in profile
    Add-Content $Profile "`$xwikicred = `"$xwikicred`""
    Write-Verbose "New Xwiki credentials set to $xwikicred"
}

If ($XwikiUrl){$Global:XwikiUrl=$xwikiurl}

If ($SaveToProfile -and $xwikiurl) {
    #Creates profile file if it does not exist already
    if (!(Test-Path $Profile)){New-Item -Type File -Force $Profile; Add-Content $Profile ""}
    #Removes old entry in profile
    $tempprofile=Get-Content $Profile | ForEach-Object {if ($_ -notlike "`$xwikiurl*"){$_}}
    $tempprofile | Set-Content $Profile
    #Adds new entry in profile
    Add-Content $Profile "`$xwikiurl = `"$xwikiurl`""
    Write-Verbose "New Xwiki URL set to $xwikiurl"
}

If ($Xdefaultwiki){$Global:Xdefaultwiki=$Xdefaultwiki}

If ($SaveToProfile -and $Xdefaultwiki) {
    #Creates profile file if it does not exist already
    if (!(Test-Path $Profile)){New-Item -Type File -Force $Profile; Add-Content $Profile ""}
    #Removes old entry in profile
    $tempprofile=Get-Content $Profile | ForEach-Object {if ($_ -notlike "`$Xdefaultwiki*"){$_}}
    $tempprofile | Set-Content $Profile
    #Adds new entry in profile
    Add-Content $Profile "`$Xdefaultwiki = `"$Xdefaultwiki`""
    Write-Verbose "New default wiki set to $Xdefaultwiki"
}

}

Function Get-XwikiSpace {
<#
.SYNOPSIS
Gets a list of xwiki spaces
.DESCRIPTION
Gets a list of xwiki spaces
Part of PVEPS by ES
.EXAMPLE
Get-XwikiSpace -name derpiderp
#>

Param(
[Parameter(Mandatory=$false,Position=0)]
[string]$Name = "*",
[string]$WikiName = $Global:Xdefaultwiki
)


$out=Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $xwikicred)} -Uri "$xwikiurl/rest/wikis/$WikiName/spaces"

Write-Output $out.spaces.space | where {$_.name -like $name} | select name,xwikiabsoluteUrl,id,home | Sort-Object name
}

Function Search-Xwiki {
<#
.SYNOPSIS
Searches in xwiki
.DESCRIPTION
Search for xwiki pages/objects
Part of PVEPS by ES
.EXAMPLE
Search-Xwiki -SearchString derpiderp -scope content -wikiname xwiki
#>

Param(
[Parameter(Mandatory=$false,Position=0)]
[string]$SearchString,
[ValidateSet("Name","Content","Title","Objects")] 
[string]$scope ="name",
[string]$WikiName = $Global:Xdefaultwiki,
$space
)

If($space){$out=Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $xwikicred)} -Uri "$xwikiurl/rest/wikis/$WikiName/spaces/$space/search?q=$SearchString&scope=$scope"}
else {
    $out=Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $xwikicred)} -Uri "$xwikiurl/rest/wikis/$WikiName/search?q=$SearchString&scope=$scope"
}

Write-Output $out.ChildNodes.searchresult
}

Function Get-XwikiPage {
<#
.SYNOPSIS
Gets xwiki page
.DESCRIPTION
Gets a list of xwiki spaces
Part of PVEPS by ES
.EXAMPLE
Get-XwikiSpace -name derpiderp
#>

Param(
[parameter(ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
$link,
[ValidateSet("Page","Object")]
[string]$Type = "page",
[switch]$ForceSSL
)
BEGIN{

}
PROCESS{
    #for pipeline proccessing
    If ($link.link){
        If ($type -eq "page") {$link=$link.link | Where-Object {$_.rel -eq "http://www.xwiki.org/rel/page"} }
        If ($type -eq "Object") {$link=$link.link | Where-Object {$_.rel -eq "http://www.xwiki.org/rel/object"} }
        $link=$link.href
    }
    Write-verbose "Proccessing $($link)"
    
    If ($ForceSSL){$link=$link -replace("http://","https://")}
    If($link){$result=Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $xwikicred)} -Uri $link}

   $result.childnodes
}

}
