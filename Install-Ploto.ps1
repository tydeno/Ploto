<#
.SYNOPSIS
Name: Ploto
Version: 0.623
Author: Tydeno


.DESCRIPTION
"Installs" Ploto from your downloaded clone of Ploto. 
A basic Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself. Basically spawns and moves Plots around.
https://github.com/tydeno/Ploto
#>


Write-Host "InstallPloto @"(Get-Date)": Hello there! My Name is Ploto. This script guides you trough the setup of myself." -ForegroundColor Magenta

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

Write-Verbose ("InstallPloto @"+(Get-Date)+": Path I got launched from: "+$scriptPath)

$PathToPloto = $scriptPath+"\Ploto.psm1"
Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Found available temp drives.")

Write-Verbose ("InstallPloto @"+(Get-Date)+": Path I calculated for where Ploto Module has to be:"+$scriptPath)

Write-Verbose ("InstallPloto @"+(Get-Date)+": Stitching together Module form source...")

#Get Version of ploto in source for folder name (posh structure)
$Pattern = "Version:"
$PlotoVersionInSource = (Get-Content $PathToPloto | Select-String $pattern).Line.Trimstart("Version: ")

Write-Host "InstallPloto @"(Get-Date)": Installing Version: $PlotoVersionInSource of Ploto on this machine." 
 
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

    $installedcfg = Get-Content -raw -Path $env:HOMEDRIVE$env:HOMEPath"\.chia\mainnet\config\PlotoSpawnerConfig.json" | ConvertFrom-Json
    $sourcecfg = Get-Content -raw -Path $scriptPath"\PlotoSpawnerConfig.json" | ConvertFrom-Json

    $contentEqual = ($sourcecfg | ConvertTo-Json -Depth 32 -Compress) -eq 
                    ($installedcfg | ConvertTo-Json -Depth 32 -Compress)

    if ($contentEqual -eq $false)
        {
            $compare = Compare-Object (($sourcecfg | ConvertTo-Json -Depth 32) -split '\r?\n') `
                    (($installedcfg | ConvertTo-Json -Depth 32) -split '\r?\n')

            if ($compare -ne $null)
                {
                    Write-Host "InstallPloto @"(Get-Date)": We are missing some properties in installed config. Need to update." -ForegroundColor Yellow
                    Write-Host "InstallPloto @"(Get-Date)": The following properties are missing in productive config:" -ForegroundColor Yellow         
                    
                    foreach ($missingprop in $compare.inputobject)
                        {
                            Write-Host "InstallPloto @"(Get-Date)":"$missingprop -ForegroundColor Yellow
                        }


                }
            else
                {
                    Write-Host "InstallPloto @"(Get-Date)": We are NOT missing any properties in installed, productive config. NO need to update." -ForegroundColor Green 
                }
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

$TempDriveDenom = Read-Host -Prompt "ConfigurePloto: Define your TempDrive Denom (eg: plot)"
$config.DiskConfig | % {$_.TempDriveDenom = $TempDriveDenom}
$tempdrives = Get-PlotoTempDrives -TempDriveDenom $TempDriveDenom
Write-Host "Will be using the following Drives as TempDrives:"
$tempdrives | ft


$OutDriveDenom = Read-Host -Prompt "ConfigurePloto: Define your OutDrive Denom (eg: out)"
$config.DiskConfig | % {$_.OutDriveDenom = $OutDriveDenom}
$outdrives = Get-PlotoOutDrives -OutDriveDenom $OutDriveDenom

Write-Host "Will be using the following Drives as OutDrives:"
$outdrives | ft



$EnableT2 = Read-Host -Prompt "ConfigurePloto: Do you want to enable T2 drives? (eg: Yes or No)"


if ($EnableT2 -eq "Yes" -or $EnableT2 -eq "yes" -or $EnableT2 -eq "y")
    {
        $config.DiskConfig | % {$_.EnableT2 = "true"}
        $t2denom = Read-Host -Prompt "ConfigurePloto: Define your t2 drivedenom (eg: t2)"
        $t2drives = Get-PlotoT2Drives -T2Denom $t2denom
        Write-Host "Will be using the following Drives as T2Drives:"
        $t2drives  | ft

    }
else
    {
        $config.DiskConfig | % {$_.EnableT2 = "false"}
        $t2denom = ""        
    }

$config.DiskConfig | % {$_.Temp2Denom = $t2denom}




$replot = Read-Host -Prompt "ConfigurePloto: Do you want to replot existing plots? (eg: Yes or No)"
if ($replot -eq "Yes" -or $replot -eq "yes" -or $replot -eq "y")
     {
        Write-Host "ConfigurePloto: Will be replotting." -ForegroundColor Magenta
        $config.SpawnerConfig | % {$_.ReplotForPool = "true"}
        $replotDenom = Read-Host "Define your replot Denom (eg: redeploy)"
        $config.DiskConfig | % {$_.DenomForOutDrivesToReplotForPools = $replotDenom}

        
    }
else
    {
        Write-Host "ConfigurePloto: Will not be replotting." -ForegroundColor Magenta
        $config.DiskConfig | % {$_.DenomForOutDrivesToReplotForPools = ""}   
        $config.SpawnerConfig | % {$_.ReplotForPool = "false"}
    }
    
$PlotForPools = Read-Host "ConfigurePloto: Do you want to create poolable, portable plots? (eg: Yes or No)"
if ($P2 -eq "" -or $P2 -eq " ")
    {
        $config.JobConfig | % {$_.PoolKey = $pk}
        $config.JobConfig | % {$_.FarmerKey = $fk}
    }



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
