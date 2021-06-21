<#
.SYNOPSIS
Name: Ploto
Version: 0.8
Author: Tydeno


.DESCRIPTION
"Installs" Ploto from your downloaded clone of Ploto. 
A basic Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself. Basically spawns and moves Plots around.
https://github.com/tydeno/Ploto
#>


#Helper functions
function Get-JsonDifference
{
    <#
    .SYNOPSIS
        Compares two JSON strings and generated stringified JSON object representing differences.

        LIMITATIONS:
            1. Arrays sub-objects are compared literally as strings after every object within array is sorted by keys and
                whole array is minified afterwards.

            2. Due to limitation of ConvertTo-Json in PowerShell 5.1 <https://github.com/PowerShell/PowerShell/issues/3705>
                object with case sensitive keys are not supported. E.g. Can't have object wil `KeyName` and `keyname`.

    .PARAMETER FromJsonString
        Old variant of stringified JSON object.

    .PARAMETER ToJsonString
        New variant of stringified JSON object that FromJsonString will be compared to.

    .PARAMETER Depth
        Depth used on resulting object conversion to JSON string ('ConvertTo-Json -Depth' parameter).
        Is it also used when converting Array values into JSON string after it has been sorted for comparison logic.

    .PARAMETER Compress
        Set to minify resulting object

    .OUTPUTS
        JSON string with the following JSON object keys:
        - Added - items that were not present in FromJsonString and are now in ToJsonString JSON object.
        - Changed - items that were present in FromJsonString and in ToJsonString containing new values are from ToJsonString JSON object.
        - ChangedOriginals - - items that were present in FromJsonString and in ToJsonString containing old values are from FromJsonString JSON object.
        - Removed - items that were present in FromJsonString and are missing in ToJsonString JSON object.
        - NotChanged - items that are present in FromJsonString and in ToJsonString JSON objects with the same values.
        - New - Merged Added and Changed resulting objects representing all items that have changed and were added.

    .EXAMPLE
        Get-JsonDifference -FromJsonString '{"foo_gone":"bar","bar":{"foo":"bar","bar":"foo"},"arr":[{"bar":"baz","foo":"bar"},1]}' `
                           -ToJsonString   '{"foo_added":"bar","bar":{"foo":"bar","bar":"baz"},"arr":[{"foo":"bar","bar":"baz"},1]}'
        {
            "Added": {
                "foo_added": "bar"
            },
            "Changed": {
                "bar": {
                    "bar": "baz"
                }
            },
            "ChangedOriginals": {
                "bar": {
                    "bar": "foo"
                }
            },
            "Removed": {
                "foo_gone": "bar"
            },
            "NotChanged": {
                "bar": {
                        "foo": "bar"
                },
                "arr": [
                    {
                        "foo": "bar",
                        "bar": "baz"
                    },
                    1
                ]
            },
            "New": {
                "foo_added": "bar",
                "bar": {
                    "bar": "baz"
                }
            }
        }

    .LINK
        https://github.com/choovick/ps-jsonutils

    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $true)]
        [String]$FromJsonString,
        [Parameter(Mandatory = $true)]
        [String]$ToJsonString,
        [Parameter(Mandatory = $false)]
        [String]$Depth = 25,
        [Switch]$Compress
    )
    try
    {
        # Convert to PSCustomObjects
        $FromObject = ConvertFrom-Json -InputObject $FromJsonString
        $ToObject = ConvertFrom-Json -InputObject $ToJsonString
        # Ensuring both inputs are objects
        try
        {
            if (([PSCustomObject]@{ }).GetType() -ne $FromObject.GetType())
            {
                throw
            }
        }
        catch
        {
            throw "FromJsonString must be an object at the root"
        }
        try
        {
            if (([PSCustomObject]@{ }).GetType() -ne $ToObject.GetType())
            {
                throw
            }
        }
        catch
        {
            throw "ToJsonString must be an object at the root"
        }

        return Get-JsonDifferenceRecursion -FromObject $FromObject -ToObject $ToObject | ConvertTo-Json -Depth $Depth -Compress:$Compress

    }
    catch
    {
        throw
    }

}


function Get-JsonDifferenceRecursion
{
    <#
    .SYNOPSIS
        INTERNAL - Compares two PSCustomObjects produced via ConvertFrom-Json cmdlet.

    .PARAMETER FromObject
        Old variant of JSON object.

    .PARAMETER ToObject
        New variant of JSON object.

    .PARAMETER Depth
        Depth used when converting Array values into JSON string after it has been sorted for comparison logic.

    .OUTPUTS
        PSCustomObject with the following object keys:
        - Added - items that were not present in FromJsonString and are now in ToJsonString JSON object.
        - Changed - items that were present in FromJsonString and in ToJsonString containing new values are from ToJsonString JSON object.
        - ChangedOriginals - - items that were present in FromJsonString and in ToJsonString containing old values are from FromJsonString JSON object.
        - Removed - items that were present in FromJsonString and are missing in ToJsonString JSON object.
        - NotChanged - items that are present in FromJsonString and in ToJsonString JSON objects with the same values.
        - New - Merged Added and Changed resulting objects representing all items that have changed and were added.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        $FromObject,
        $ToObject,
        $Depth = 25
    )
    try
    {
        $Removed = [PSCustomObject]@{ }
        $Changed = [PSCustomObject]@{ }
        $ChangedOriginals = [PSCustomObject]@{ }
        $Added = [PSCustomObject]@{ }
        $New = [PSCustomObject]@{ }
        $NotChanged = [PSCustomObject]@{ }

        # Now for sort can capture each value of input object
        foreach ($Property in $ToObject.PsObject.Properties)
        {
            # Access the name of the property
            $ToName = $Property.Name
            # Access the value of the property
            $ToValue = $Property.Value

            # getting types handling null
            if ($null -eq $ToValue)
            {
                $ToValueType = $Script:NullType
            }
            else
            {
                $ToValueType = $ToValue.GetType()
            }

            # check if property exists in FromObject (in PS 5.1 we cant support case sensitive keys https://github.com/PowerShell/PowerShell/issues/3705)
            if ([bool]($FromObject.PSObject.Properties.Name -match [System.Text.RegularExpressions.Regex]::Escape($ToName)))
            {
                # old value
                $FromValue = $FromObject.$ToName

                # getting from object type
                # getting types handling null
                if ($null -eq $FromObject.$ToName)
                {
                    $FromValueType = $Script:NullType
                }
                else
                {
                    $FromValueType = $FromObject.$ToName.GetType()
                }

                # if both of them are object, continue recursion
                if ($FromValueType -eq ([PSCustomObject]@{ }).GetType() -and $ToValueType -eq ([PSCustomObject]@{ }).GetType())
                {
                    $Result = Get-JsonDifferenceRecursion -FromObject $FromValue -ToObject $ToValue
                    # capture differences
                    if (-not [string]::IsNullOrWhiteSpace($Result.Added))
                    {
                        Add-Member -InputObject $Added -MemberType NoteProperty -Name $ToName -Value $Result.Added
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Result.Removed))
                    {
                        Add-Member -InputObject $Removed -MemberType NoteProperty -Name $ToName -Value $Result.Removed
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Result.Changed))
                    {
                        Add-Member -InputObject $Changed -MemberType NoteProperty -Name $ToName -Value $Result.Changed
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Result.ChangedOriginals))
                    {
                        Add-Member -InputObject $ChangedOriginals -MemberType NoteProperty -Name $ToName -Value $Result.ChangedOriginals
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Result.NotChanged))
                    {
                        Add-Member -InputObject $NotChanged -MemberType NoteProperty -Name $ToName -Value $Result.NotChanged
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Result.New))
                    {
                        Add-Member -InputObject $New -MemberType NoteProperty -Name $ToName -Value $Result.New
                    }
                }
                # if type is different
                elseif ($FromValueType -ne $ToValueType)
                {
                    # capturing new value in changed object
                    Add-Member -InputObject $Changed -MemberType NoteProperty -Name $ToName -Value $ToValue
                    Add-Member -InputObject $New -MemberType NoteProperty -Name $ToName -Value $ToValue
                    Add-Member -InputObject $ChangedOriginals -MemberType NoteProperty -Name $ToName -Value $FromValue
                }
                # If both are arrays, items should be sorted by now, so we will stringify them and compare as string case sensitively
                elseif ($FromValueType -eq @().GetType() -and $ToValueType -eq @().GetType())
                {
                    # stringify array
                    $FromJSON = Get-SortedPSCustomObjectRecursion $FromObject.$ToName | ConvertTo-Json -Depth $Depth
                    $ToJSON = Get-SortedPSCustomObjectRecursion $ToObject.$ToName | ConvertTo-Json -Depth $Depth

                    # add to changed object if values are different for stringified array
                    if ($FromJSON -cne $ToJSON)
                    {
                        Add-Member -InputObject $Changed -MemberType NoteProperty -Name $ToName -Value $ToValue
                        Add-Member -InputObject $New -MemberType NoteProperty -Name $ToName -Value $ToValue
                        Add-Member -InputObject $ChangedOriginals -MemberType NoteProperty -Name $ToName -Value $FromValue
                    }
                    else
                    {
                        Add-Member -InputObject $NotChanged -MemberType NoteProperty -Name $ToName -Value $ToValue
                    }
                }
                # other primitive types changes
                else
                {
                    if ($FromValue -cne $ToValue)
                    {
                        Add-Member -InputObject $Changed -MemberType NoteProperty -Name $ToName -Value $ToValue
                        Add-Member -InputObject $New -MemberType NoteProperty -Name $ToName -Value $ToValue
                        Add-Member -InputObject $ChangedOriginals -MemberType NoteProperty -Name $ToName -Value $FromValue
                    }
                    else
                    {
                        Add-Member -InputObject $NotChanged -MemberType NoteProperty -Name $ToName -Value $ToValue
                    }
                }
            }
            # if value does not exist in the from object, then its was added
            elseif (-not [bool]($FromObject.PSObject.Properties.Name -match [System.Text.RegularExpressions.Regex]::Escape($ToName)))
            {
                Add-Member -InputObject $Added -MemberType NoteProperty -Name $ToName -Value $ToValue
                Add-Member -InputObject $New -MemberType NoteProperty -Name $ToName -Value $ToValue
            }
        }

        # Looping from object to find removed items
        foreach ($Property in $FromObject.PsObject.Properties)
        {
            # Access the name of the property
            $FromName = $Property.Name
            # Access the value of the property
            $FromValue = $Property.Value

            # if property not on to object, its removed
            if (-not [bool]($ToObject.PSObject.Properties.Name -match [System.Text.RegularExpressions.Regex]::Escape($FromName)))
            {
                Add-Member -InputObject $Removed -MemberType NoteProperty -Name $FromName -Value $FromValue
            }
        }

        return [PSCustomObject]@{
            Added            = $Added
            Changed          = $Changed
            ChangedOriginals = $ChangedOriginals
            Removed          = $Removed
            NotChanged       = $NotChanged
            New              = $New
        }
    }
    catch
    {
        throw
    }
}

function ConvertTo-KeysSortedJSONString
{
    <#
    .SYNOPSIS
        Sorts JSON strings by object keys.

    .PARAMETER JsonString
        Input JSON string

    .PARAMETER Depth
        Used for ConvertTo-Json on resulting object

    .PARAMETER Compress
        Returned minified JSON

    .OUTPUTS
        String of sorted and stringified JSON object

    .EXAMPLE
        ConvertTo-KeysSortedJSONString -JsonString '{"b":1,"1":{"b":null,"a":1}}'
        {
            "1": {
                "a": 1,
                "b": null
            },
            "b": 1
        }

    .LINK
        https://github.com/choovick/ps-jsonutils

    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $true)]
        [String]$JsonString,
        [Parameter(Mandatory = $false)]
        [String]$Depth = 25,
        [Switch]$Compress
    )
    try
    {
        $ResultObject = Get-SortedPSCustomObjectRecursion -InputObject (ConvertFrom-Json $JsonString)
        return $ResultObject | ConvertTo-Json -Compress:$Compress -Depth $Depth
    }
    catch
    {
        throw
    }
}

function Get-SortedPSCustomObjectRecursion
{
    <#
    .SYNOPSIS
        INTERNAL - Recursion to sort PSCustomObject produced via ConvertFrom-Json by keys.
        Can take $null, that will be simply returned.

    .PARAMETER InputObject
        PSCustomObject produced via ConvertFrom-Json

    .OUTPUTS
        PSCustomObject sorted by keys

    #>
    [CmdletBinding()]
    [OutputType([Object])]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$InputObject
    )

    try
    {
        # null handle
        if ($null -eq $InputObject)
        {
            return $InputObject
        }
        # object
        if ($InputObject.GetType() -eq ([PSCustomObject]@{ }).GetType())
        {
            # soft object by keys
            # thanks to https://stackoverflow.com/a/44056862/2174835
            $SortedInputObject = New-Object PSCustomObject
            $InputObject |
            Get-Member -Type NoteProperty | Sort-Object Name | ForEach-Object {
                Add-Member -InputObject $SortedInputObject -Type NoteProperty `
                    -Name $_.Name -Value $InputObject.$($_.Name)
            }

            # Now for sort can capture each value of input object
            foreach ($Property in $SortedInputObject.PsObject.Properties)
            {
                # Access the name of the property
                $PropertyName = $Property.Name
                # Access the value of the property
                $PropertyValue = $Property.Value

                $SortedInputObject.$PropertyName = Get-SortedPSCustomObjectRecursion -InputObject $PropertyValue
            }

            return $SortedInputObject
        }
        # array, sort each item within array
        elseif ($InputObject.GetType() -eq @().GetType())
        {
            $SortedArrayObjects = @()

            foreach ($Item in $InputObject)
            {
                $SortedArrayObjects += @(Get-SortedPSCustomObjectRecursion -InputObject $Item)
            }

            return $SortedArrayObjects
        }
        # primitive are not sorted as returned as is
        return $InputObject
    }
    catch
    {
        throw
    }
}

# Mainlogic

Write-Host "InstallPloto @"(Get-Date)": Hello there! My Name is Ploto. This script guides you trough the setup of myself." -ForegroundColor Magenta

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

Write-Host ("InstallPloto @"+(Get-Date)+": Path I got launched from: "+$scriptPath)

$PathToPloto = $scriptPath+"\Ploto.psm1"

#Get Version of ploto in source for folder name (posh structure)
$Pattern = "Version:"
$PlotoVersionInSource = (Get-Content $PathToPloto | Select-String $pattern).Line.Trimstart("Version: ")

Write-Host "InstallPloto @"(Get-Date)": Installing Version: $PlotoVersionInSource of Ploto on this machine." 

$IsInstalledFromRelease = $scriptPath.Split("\")
$CountInThere = ($IsInstalledFromRelease.Count)-1
if ($IsInstalledFromRelease[$CountInThere] -ne "Ploto")
    {
        Write-Host "InstallPloto @"(Get-Date)": Ploto Install script is launched from Release. Need to rewrite its name to 'Ploto'" -ForegroundColor Yellow
        $RenameFinalCopy = $true
    }
else
    {
        $RenameFinalCopy = $false
    }

$DestinationForModule = $Env:ProgramFiles+"\WindowsPowerShell\Modules\"
$DestinationContainer = $Env:ProgramFiles+"\WindowsPowerShell\Modules\Ploto"
$DestinationFullPathForModule = $Env:ProgramFiles+"\WindowsPowerShell\Modules\Ploto.psm1"

Write-Host "InstallPloto @"(Get-Date)": Lets check if a version of Ploto is installed in:"$Env:ProgramFiles"\WindowsPowerShell\Modules" -ForegroundColor Cyan

If (Test-Path $DestinationContainer)
    {
        Write-Host "InstallPloto @"(Get-Date)": There is a version of Ploto installed in:"$Env:ProgramFiles"\WindowsPowerShell\Modules" -ForegroundColor Cyan

        #Lets get version of Script
        $PlotoVersionInstalled = (Get-Content $DestinationContainer"\Ploto.psm1" | Select-String $pattern).Line.Trimstart("Version: ")
        
        Write-Host "InstallPloto @"(Get-Date)": Current version installed:"$PlotoVersionInstalled -ForegroundColor Cyan

        If ($PlotoVersionInstalled -le $PlotoVersionInSource)
            {
                Write-Host "InstallPloto @"(Get-Date)": Version in downloaded Source is newer or the same as installed Version." -ForegroundColor Yellow
                $Update = Read-Host -Prompt "InstallPloto: Do you want to update your existing version?"

                if ($Update -eq "Yes" -or $Update -eq "y")
                    {
                        Write-Host "InstallPloto @"(Get-Date)": Starting update of Module..." -ForegroundColor Cyan
                        try 
                            {
                                Write-Host "InstallPloto @"(Get-Date)": Deleting old version in:"$DestinationContainer -ForegroundColor Cyan
                                Get-Item -Path $DestinationContainer | Remove-Item -Recurse -Force -ErrorAction Stop
                                Write-Host "InstallPloto @"(Get-Date)": Successfully removed previous version of Ploto in:"$DestinationContainer  -ForegroundColor Green
                            }
                        catch 
                            {
                                Write-Host $_.Exception.Message -ForegroundColor Red
                                Write-Host "InstallPloto @"(Get-Date)": Could not remove older version." -ForegroundColor Red
                                break
                            }
                        try 
                            {
                                Copy-Item -Path $scriptPath -Destination $DestinationForModule -Force -Recurse
                                Write-Host "InstallPloto @"(Get-Date)": Copied Module successfully to:"$DestinationForModule -ForegroundColor Green
                            }

                        catch 
                            {
                                Write-Host "InstallPloto @"(Get-Date)": Could not install Module in:"$Env:ProgramFiles"\WindowsPowerShell\Modules" -ForegroundColor Red
                                Write-Host $_.Exception.Message -ForegroundColor Red
                                break 
                            }
                    }
                else
                    {
                        Write-Host "InstallPloto @"(Get-Date)": We skipped updating. Using currently installed version of Ploto:"$PlotoVersionInSource -ForegroundColor Yellow
                    }
            }
    }
else
    {
        Write-Host "InstallPloto @"(Get-Date)": There is no version of Ploto installed in:"$Env:ProgramFiles"\WindowsPowerShell\Modules" -ForegroundColor Cyan
        Write-Host "InstallPloto @"(Get-Date)": Starting copy of Module..."
        try 
            {
        
                Copy-Item -Path $scriptPath -Destination $DestinationForModule -Force -Recurse
                Write-Host "InstallPloto @"(Get-Date)": Copied Module successfully to:"$DestinationForModule -ForegroundColor Green
            }

        catch 
            {
                Write-Host "InstallPloto @"(Get-Date)": Could not install Module in:"$Env:ProgramFiles"\WindowsPowerShell\Modules" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                break 
            }
    }

if ($RenameFinalCopy -eq $true)
    {
        Write-Host "InstallPloto @"(Get-Date)": Renaming Ploto folder in: "$DestinationForModule -ForegroundColor yellow
        $buildedpath = $DestinationForModule+"\"+$IsInstalledFromRelease[$CountInThere]
        Write-Host "InstallPloto @"(Get-Date)": Builde Path to rename:"$buildedpath -ForegroundColor yellow

        try 
            {
                Rename-Item -path $buildedpath -NewName "Ploto" -Force -ErrorAction Stop
                Write-Host "InstallPloto @"(Get-Date)": Renamed Module successfully!" -ForegroundColor Green
            }
        catch 
            {
                Write-Host "InstallPloto @"(Get-Date)": Could not rename final Module to 'Ploto'. You may need to rename manually in:"$DestinationForModule -ForegroundColor red
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        

    }


Write-Host "InstallPloto @"(Get-Date)": Lets check the current set Execution Policy..." -ForegroundColor Cyan
$ExecPolicy = Get-ExecutionPolicy
Write-Host "InstallPloto @"(Get-Date)": Execution Policy is set to: "$ExecPolicy


#get ExecPolicy
if (!($ExecPolicy -ne "RemoteSigned" -or "Bypass"))
    {
        Write-Host "InstallPloto @"(Get-Date)": Alright, ExecutionPolicy is NOT RemoteSigned or Bypass. Need to adjust..." -ForegroundColor Yellow
        try
            {
                Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
                Write-Host "InstallPloto @"(Get-Date)": I set Execution Policy to RemoteSigned."
            }
        catch
            {
                
                Write-Host $_.Exception.Message -ForegroundColor red
                Write-Host "InstallPloto @"(Get-Date)": I ran into trouble setting RemoteSigned. Trying to set Bypass." -ForegroundColor Yellow

                try 
                    {
                        Set-ExecutionPolicy -ExecutionPolicy Bypass
                        Write-Host "InstallPloto @"(Get-Date)": I set Execution Policy to Bypass."
                    }
                catch 
                    {
                        Write-Host "InstallPloto @"(Get-Date)": I ran into trouble setting RemoteSigned and Bypass. Aorting. Maybe launch Script as Admin." -ForegroundColor Red
                        Write-Host $_.Exception.Message -ForegroundColor Red
                        break
                    }
            }        
    }

try 
    {
       Import-Module $PathToPloto
       Write-Host "InstallPloto @"(Get-Date)": Wooho! I've managed to imort the Ploto Module!" -ForegroundColor Green
    }
catch
    {
       Write-Host "InstallPloto @"(Get-Date)": Aww... I ran into trouble importing the Module. See below for details." -ForegroundColor Red
       Write-Host $_.Exception.Message -ForegroundColor Red
       break
     
    }



Write-Host "InstallPloto @"(Get-Date)": Okay, next step is getting the config and setting it together with you..."

Write-Host "InstallPloto @"(Get-Date)": Checking if we have new properties in config from new version..." -ForegroundColor Cyan

$pathtolchech = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"
$sourcecfg = Get-Content -raw -Path $scriptPath"\PlotoSpawnerConfig.json" | ConvertFrom-Json 
if (Test-Path $pathtolchech)
    {
        $installedcfg = Get-Content -raw -Path $env:HOMEDRIVE$env:HOMEPath"\.chia\mainnet\config\PlotoSpawnerConfig.json" | ConvertFrom-Json 
        $old = Get-Content -raw -Path $env:HOMEDRIVE$env:HOMEPath"\.chia\mainnet\config\PlotoSpawnerConfig.json"
        $new = Get-Content -raw -Path $scriptPath"\PlotoSpawnerConfig.json" 
        $compare = Get-JsonDifference -FromJsonString $old -ToJsonString $new -Depth 32 | ConvertFrom-Json
        $checkAdded = $compare.added

        if ($checkAdded -match "@")
            {
                Write-Host "InstallPloto @"(Get-Date)": New properties were introduced in new version, need to update config!" -ForegroundColor Yellow
                Write-Host "InstallPloto @"(Get-Date)": New properties:" -ForegroundColor Yellow
                Write-Host "InstallPloto @"(Get-Date)": Added: "$compare.added -ForegroundColor Yellow
                
            }
        else
            {
                Write-Host "InstallPloto @"(Get-Date)": No new properties were introduced in config" -ForegroundColor Green
            }

    }
else
    {
         Write-Host "InstallPloto @"(Get-Date)": No productive config found among this usercontext."
    }
   

$SkipCFG = Read-Host "InstallPloto: Do you want to set the config? If not, we skip that, because you alreay have one in place (eg. Yes or y)"

If ($SkipCFG -eq "Yes" -or $SkipCFG -eq "y")
    {
 try 
        {

            $PathToConfig = $scriptPath+"\PlotoSpawnerConfig.json"

            $config = Get-Content -raw -Path $PathToConfig | ConvertFrom-Json -ErrorAction Stop

            Write-Host "InstallPloto @"(Get-Date)": Wuepa! We could grab the config! Next up is setting its values with you." -ForegroundColor Green
        }
 catch
        {
             
            Write-Host "PlotoManager @"(Get-Date)": Could not read Config. Check your config with the hints below and on https://jsonformatter.org/ for validation. If you cant get it to run, join Ploto Discord for help.  " -ForegroundColor Red

            if ($_.Exception.Message -like "*1384*")
                {
                    Write-Host "PlotoManager @"(Get-Date)": Looks like your PathToPlotoModule is not specified correctly. You have to use \ instead of /!" -ForegroundColor Yellow
                }

           if ($_.Exception.Message -like "*1093*")
                {
                    Write-Host "PlotoManager @"(Get-Date)": Looks like there is a ','  missing somewhere at the end of a line " -ForegroundColor Yellow
                }

           if ($_.Exception.Message -like "*1094*")
                {
                    Write-Host "PlotoManager @"(Get-Date)": Looks like there is a '$a' missing somewhere at the  beginning or end of a  property " -ForegroundColor Yellow
                }



            if ($_.Exception.Message -notlike "*1384*" -and $_.Exception.Message -notlike "*1093*" -and $_.Exception.Message -notlike "*1094*") 
                {
                    Write-Host "PlotoManager @"(Get-Date)": Could not determine possible rootcause. Check your config on https://jsonformatter.org/ for validation. If you cant get it to run, join Ploto Discord for help." -ForegroundColor Red
                    Write-Host $_.Exception.Message -ForegroundColor red
                }

                Start-Sleep 30 

            Write-Host "Exiting cause there is no readable config." -ForegroundColor Red
            break
        } 

if ($config.PathToPloto -eq "C:/Users/Tydeno/Desktop/Ploto/Ploto.psm1" -or $config.PathToPloto -eq "")
    {
        
        $config.PathToPloto = $PathToPloto
           
    }


Write-Host "-------------------------------------"
Write-Host "ConfigurePloto: Lets go over to the basic config..." -ForegroundColor Cyan

$PlotterName = Read-Host -Prompt "ConfigurePloto: Enter the name of your plotter (eg: SirNotPlotAlot)"
$config.PlotterName = $PlotterName

$EnableAlerts = Read-Host -Prompt "ConfigurePloto: Do you want to enable Discord Notifications? (eg: Yes or No)"
If ($EnableAlerts -eq "Yes" -or $EnableAlerts -eq "yes" -or $EnableAlerts -eq "y")
    {
        $config | % {$_.EnableAlerts = "true"}
        $config | % {$_.EnablePlotoFyOnStart = "true"}

        $WebhookURL = Read-Host -Prompt "Enter the WebhookURL of Discord where you want to receive alerts:"
        $config.SpawnerAlerts | % {$_.DiscordWebhookUrl = $WebhookURL}

        $PeriodToReport = Read-Host -Prompt "In what intervall in hours would you like to receive a summary? (eg: 0.5)"
        $config.SpawnerAlerts | % {$_.WhenJobSpawned = "true"}
        $config.SpawnerAlerts | % {$_.WhenNoOutDrivesAvailable = "true"}
        $config.SpawnerAlerts | % {$_.WhenJobCouldNotBeSpawned  = "true"}
        $config.SpawnerAlerts | % {$_.PeriodOfReportInHours  = $PeriodToReport}
    }
else
    {
        $config | % {$_.EnableAlerts = "false"}
        $config | % {$_.EnablePlotoFyOnStart = "false"}
    }

$WindowStyle = Read-Host -Prompt "ConfigurePloto: Do you want to the plot jobs in background? (eg: Yes or No)"

Write-Host "-------------------------------------"

Write-Host "ConfigurePloto: Lets go over to the disk config..."
Write-Host "ConfigurePloto: To define your drives, use the following notation:"  
Write-Host "ConfigurePloto: To define one drive, use the following notation: F:"
Write-Host "ConfigurePloto: To define several drives, use the following notation: F:,E:,K:"
Write-Host "ConfigurePloto: To define a folder within a  drive, use following notation: F:\afolder,E:\anotherone,K:\somefolder"
$TempDrives = Read-Host -Prompt "ConfigurePloto: Define your TempDrives."
$config.DiskConfig | % {$_.TempDrives = $TempDrives}

$OutDrives = Read-Host -Prompt "ConfigurePloto: Define your OutDrives"
$config.DiskConfig | % {$_.OutDrives = $OutDrives}

$EnableT2 = Read-Host -Prompt "ConfigurePloto: Do you want to enable T2 drives? (eg: Yes or No)"

if ($EnableT2 -eq "Yes" -or $EnableT2 -eq "yes" -or $EnableT2 -eq "y")
    {
        $config.DiskConfig | % {$_.EnableT2 = "true"}
        $t2denom = Read-Host -Prompt "ConfigurePloto: Define your t2drives"

    }
else
    {
        $config.DiskConfig | % {$_.EnableT2 = "false"}
        $t2denom = ""        
    }

$config.DiskConfig | % {$_.Temp2drives = $t2denom}


$replot = Read-Host -Prompt "ConfigurePloto: Do you want to replot existing plots? (eg: Yes or No)"
if ($replot -eq "Yes" -or $replot -eq "yes" -or $replot -eq "y")
     {
        Write-Host "ConfigurePloto: Will be replotting." -ForegroundColor Magenta
        $config.SpawnerConfig | % {$_.ReplotForPool = "true"}
        $replotDenom = Read-Host "Define your ReplotDrives"
        $config.DiskConfig | % {$_.ReplotDrives = $replotDenom}
    }
else
    {
        Write-Host "ConfigurePloto: Will not be replotting." -ForegroundColor Magenta
        $config.DiskConfig | % {$_.ReplotDrives = ""}   
        $config.SpawnerConfig | % {$_.ReplotForPool = "false"}
    }
    
$PlotForPools = Read-Host "ConfigurePloto: Do you want to create poolable, portable plots? (eg: Yes or No)"


if ($PlotForPools -eq "Yes" -or $PlotForPools -eq "y")
    {
        $P2 = Read-Host "ConfigurePloto: Enter your P2SingletonAdress to be used by the plots (eg: 76x8s9s89sjhsdsshdsi)"
        $fk = Read-host -Prompt "ConfigurePloto: Define your farmer key (eg: dskofsjfias09eidaoufoj...)"
        $config.JobConfig | % {$_.P2SingletonAdress = $P2} 
        $config.JobConfig | % {$_.FarmerKey = $fk}
    }
else
    {
    $pfkeys = Read-Host -Prompt "ConfigurePloto: Do you want to specify -p and -f keys for plotting? DO NOT DO THIS IF YOU WANT PORTABLE POOL PLOTS! (eg: Yes or No)"

    if ($pfkeys -eq "Yes" -or $pfkeys -eq "y")
        {
            $pk = Read-host -Prompt "ConfigurePloto: Define your pool key (eg: 982192183012830173jdi832...)"
            $fk = Read-host -Prompt "ConfigurePloto: Define your farmer key (eg: dskofsjfias09eidaoufoj...)"
            $config.JobConfig | % {$_.PoolKey = $pk}
            $config.JobConfig | % {$_.FarmerKey = $fk}
        }    
    }

if ($WindowStyle -eq "Yes" -or $WindowStyle -eq "yes" -or $WindowStyle -eq "y")
    {
        $config.ChiaWindowStyle = "hidden"
    } 
else
    {
        $config.ChiaWindowStyle = "normal"
    }


Write-Host "-------------------------------------"
Write-Host "ConfigurePloto: Lets go over to the job config..." -ForegroundColor Cyan

$PlotterToUse = Read-Host -Prompt "ConfigurePloto: Which Plotter do you want to use? Enter 'Stotik' for Madmax Stotik or enter 'Chia' for official Chia plotter"

if ($PlotterToUse -eq "Stotik" -or $PlotterToUse -eq "stotik")
    {
        
        Write-Host "ConfigurePloto: We will be using MadMax plotter. Pay attention when configuring the JobConfig that you take into consideration how madmax/stotik work" -ForegroundColor Magenta
        $config | % {$_.PlotterUsed  = $PlotterToUse}
        $PathtoStotik = Read-Host -Prompt "ConfigurePloto: Enter fullpath to chia_plots.exe"
        $config | % {$_.PathToUnofficialPlotter  = $PathtoStotik}
    }
else
    {
         Write-Host "ConfigurePloto: We will be using official Chia Plotter." -ForegroundColor Magenta
         $PlotterToUse = "Chia"
         $config | % {$_.PlotterUsed  = $PlotterToUse}
    }


$InputAmountToSpawn = Read-Host -Prompt "ConfigurePloto: How many plots do you want to be spawned overall? (eg: 1000)"
$config.SpawnerConfig | % {$_.InputAmounttoSpawn  = $InputAmountToSpawn}

$IntervallToCheckIn = Read-Host -Prompt "ConfigurePloto: In what intervall do you want to check for new jobs in minutes? (eg: 5)"
$config.SpawnerConfig | % {$_.IntervallToCheckInMinutes = $IntervallToCheckIn}

$WaitSep = Read-Host -Prompt "ConfigurePloto: What stagger time do you want between jobs on separate disks in minutes? (eg. 15)"
$config.SpawnerConfig | % {$_.WaitTimeBetweenPlotOnSeparateDisks = $WaitSep}

$WaitSame = Read-Host -Prompt "ConfigurePloto: What stagger time do you want between jobs on same disks in minutes? (eg. 45)"
$config.SpawnerConfig | % {$_.WaitTimeBetweenPlotOnSameDisk = $WaitSame}

$MaxPa = Read-Host -Prompt "ConfigurePloto: How many Jobs do you want to be run max in parallel? (eg: 15)"
$config.SpawnerConfig | % {$_.MaxParallelJobsOnAllDisks = $MaxPa}

$MaxPaSame = Read-Host -Prompt "ConfigurePloto: How many Jobs do you want to be run max in parallel on the same disk? (eg: 3)"
$config.SpawnerConfig | % {$_.MaxParallelJobsOnSameDisk = $MaxPaSame}

$MaxP1 = Read-Host -Prompt "ConfigurePloto: How many Jobs do you want to be run max in parallel in phase 1? (eg: 9)"
$config.SpawnerConfig | % {$_.MaxParallelJobsInPhase1OnAllDisks = $MaxP1}

$StartE = Read-Host -Prompt "ConfigurePloto: Do you want to start a new Job early? (eg: Yes or No)"
If ($StartE -eq "Yes" -or $StartE -eq "yes" -or $StartE -eq "y")
    {
        $config.SpawnerConfig | % {$_.StartEarly = "true"}
        $config.SpawnerConfig | % {$_.StartEarlyPhase = "4"}
    }
else
    {
        $config.SpawnerConfig | % {$_.StartEarly = "false"} 
    }

if ($PlotterToUse -ne "Stotik" -or $PlotterToUse -ne "stotik")
    {
        $bSize = Read-Host -Prompt "ConfigurePloto: Define BufferSize for jobs (eg: 3390)"
        $config.JobConfig | % {$_.BufferSize = $bSize} 
    }

$buckets = Read-Host -Prompt "ConfigurePloto: Define amount of buckets (eg: 128)"
$config.JobConfig | % {$_.Buckets = $buckets} 

$ts = Read-Host -Prompt "ConfigurePloto: Define amount of Threads for jobs (eg: 4)"
$config.JobConfig | % {$_.Thread = $ts} 

$bf = Read-Host -Prompt "ConfigurePloto: Do you want to disable Bitfield? NOT RECOMMENDED TO DISABLE! (eg. Yes or No)"

if ($bf = "Yes" -or $bf -eq "yes" -or $bf -eq "y")
    {
        $config.JobConfig | % {$_.Bitfield = "false"} 
    }
else
    {
        $config.JobConfig | % {$_.Bitfield = "true"}
    }

Write-Host "--------------------------"


try 
    {
        Write-Host "ConfigurePloto @"(Get-Date)": Saving the config in this folder (where Ploto is stored) with your values..." 
        $config | ConvertTo-Json -Depth 32 | Set-Content $PathToConfig -Force
        Write-Host "InstallPloto @"(Get-Date)": Saved config successfully." -ForegroundColor Green
    }

catch 
    {
        Write-Host "InstallPloto @"(Get-Date)": Could not update config in this folder (where Ploto is stored). See below for details." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        break
    }

Write-Host "ConfigurePloto @"(Get-Date)": Do you want to get this configuration into production?"
Write-Host "ConfigurePloto @"(Get-Date)": If you have a current configuration going, it will be overwritten with the values above. Are your sure you want to continue?" -ForegroundColor Yellow
$consent = Read-Host -Prompt "Enter 'Yes' or 'y' to continue. Every other inpout aborts."

if ($consent -eq "Yes" -or $consent -eq "y")
    {
        try 
            {

                $tempdrives = Get-PlotoTempDrives 
                Write-Host "Will be using the following Drives as TempDrives:"
                $tempdrives | ft

                $outdrives = Get-PlotoOutDrives

                Write-Host "Will be using the following Drives as OutDrives:"
                $outdrives | ft

                $t2drives = Get-PlotoT2Drives 
                Write-Host "Will be using the following Drives as T2Drives:"
                $t2drives  | ft

                $destination = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\"
                Copy-Item -Path $PathToConfig -Destination $destination -Force
                Write-Host "InstallPloto @"(Get-Date)": Copied config successfully to: " $destination -ForegroundColor Green
                Write-Host "InstallPloto @"(Get-Date)": Okay, we are finally ready to roll!" -ForegroundColor Green
            }
        catch 
            {
               Write-Host "InstallPloto @"(Get-Date)": Could not copy config to: "$destination -ForegroundColor Red
               Write-Host $_.Exception.Message -ForegroundColor Red
               break
            }    
    }
else
    {
        Write-Host "InstallPloto @"(Get-Date)": Did not copy saved config to production." 
    }
        
    }
else
    {
        Write-Host "InstallPloto @"(Get-Date)": We skipped setting the config. Only updated Ploto Module." -ForegroundColor Yellow
    }



Write-Host "InstallPloto @"(Get-Date)": Ploto was installed correctly on this System." -ForegroundColor Green

Write-Host "InstallPloto @"(Get-Date)": To launch it, start a PowerShell Session and run 'Start-PlotoSpawns'" 
