<#
.SYNOPSIS
Name: Ploto
Version: 1.0.9.4.4
Author: Tydeno


.DESCRIPTION
A basic Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself. Basically spawns and moves Plots around.
https://github.com/tydeno/Ploto
#>

function Get-PlotoOutDrives
{
	Param(
		[parameter(Mandatory=$true)]
		$OutDriveDenom
		)

$outDrives = Get-CimInstance win32_logicaldisk -Verbose:$false | Where-Object {$_.VolumeName -like "*$OutDriveDenom*"} 

#Check Space for outDrives
$collectionWithDisks= New-Object System.Collections.ArrayList
foreach ($drive in $outDrives)
    {

        $DiskSize = [math]::Round($tmpDrive.Size  / 1073741824, 2)
        $FreeSpace = [math]::Round($drive.FreeSpace  / 1073741824, 2)

                #Get-CurrenJobs
        $activeJobs = Get-PlotoJobs | Where-Object {$_.OutDrive -eq $drive.DeviceId} | Where-Object {$_.Status -ne "Completed"}
        if ($activeJobs)
            {
                $HasPlotInProgress = $true
                $PlotInProgressName = $activeJobs.PlotId
                $PlotInProgressCount = $activeJobs.count
                $PlotInProgressPhase = $activeJobs.Status

                if ($PlotInProgressCount -eq $null)
                    {
                        $PlotInProgressCount = 1
                    }
                
                $RedundencyCheck = $DiskSize - ($FreeSpace + $PlotInProgressCount * 107)
                #has addiontal data in the disk
                if($RedundencyCheck -gt 0)
                    {
                        $AmountOfPlotsToTempMax = [math]::Floor(($FreeSpace / 107))
                        $AvailableAmounToPlot = $AmountOfPlotsToTempMax - $PlotInProgressCount
                    }
                else
                    {
                        $AmountOfPlotsinProgressOccupied = [math]::Floor(($PlotInProgressCount * 107))
                        $AvailableAmounToPlot = [math]::Floor(($DiskSize - $AmountOfPlotsinProgressOccupied) / 107)
                        $AmountOfPlotsToTempMax = $AvailableAmounToPlot + $PlotInProgressCount
                    }

            }

        else
            {
                $HasPlotInProgress = $false
                $PlotInProgressName = " "
                $PlotInProgressCount = 0
                $AmountOfPlotsToTempMax = [math]::Floor(($FreeSpace / 107))
                $AvailableAmounToPlot = $AmountOfPlotsToTempMax
            }


        if ($AvailableAmounToPlot -ge 1)
            {
                $IsPlottable = $true
            }
        else
            {
                $IsPlottable = $false
            }


        If ($FreeSpace -gt 107)
            {
                $PlotToDest = $true
            }
        else
            {
                $PlotToDest = $false
            }

        $outdriveToPass = [PSCustomObject]@{
        DriveLetter     =  $drive.DeviceID
        ChiaDriveType = "Out"
        VolumeName = $drive.VolumeName
        FreeSpace = $FreeSpace
        TotalSpace = $DiskSize
        IsPlottable    = $PlotToDest
        HasPlotInProgress = $HasPlotInProgress
        AmountOfPlotsInProgress =  $PlotInProgressCount
        AmountOfPlotsToTempMax = $AmountOfPlotsToTempMax
        AvailableAmountToPlot = $AvailableAmounToPlot
        PlotInProgressID = $PlotInProgressName
        PlotInProgressPhase = $PlotInProgressPhase
        }

        $collectionWithDisks.Add($outdriveToPass) | Out-Null

    }
    return $collectionWithDisks 
}

function Get-PlotoTempDrives
{
	Param(
        [parameter(Mandatory=$true)]
		$TempDriveDenom
		)

$tmpDrives = Get-CimInstance win32_logicaldisk -Verbose:$false | Where-Object {$_.VolumeName -like "*$TempDriveDenom*"}


#Check Space for outDrives
$collectionWithDisks= New-Object System.Collections.ArrayList
foreach ($tmpDrive in $tmpDrives)
    {
        $FolderCheck = Get-ChildItem $tmpDrive.DeviceId | Where-Object {$_.Attributes -eq "Directory"}
        if ($FolderCheck)
            {
                $HasFolder = $true
            }
        else
            {
                $HasFolder = $false
            }
        
        $DiskSize = ([math]::Round($tmpDrive.Size  / 1073741824, 2))
        $FreeSpace = [math]::Round($tmpDrive.FreeSpace  / 1073741824, 2)

        $Partition = Get-Partition | Where-Object {$_.DriveLetter -eq ($tmpDrive.DeviceId.TrimEnd(":"))}

        If ($Partition.DiskNumber -eq $null)
            {
                Write-Host "PlotoSpawner @ "(Get-Date)": Cannot get disks for the logical volume" $tmpDrive.DeviceID "by PowerShell using Get-Partition/Get-Disk cmdlet. Cannot get the disk and temperature for reporting. Can keep going." -ForegroundColor Yellow
            }

        #$approxDiskModel = $Partition.DiskPathsplit("&")[2].trimstart("prod_").Replace("_", " ").Split("#")[0]

        $oldea = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"

        #Get Disk from partition
        $Disk = Get-Disk -Number $Partition.DiskNumber
        $PhysicalDisk = Get-PhysicalDisk | Where-Object {$_.FriendlyName -eq $Disk.Model}

        $ErrorActionPreference = $oldea

        #Get-CurrenJobs
        $activeJobs = Get-PlotoJobs | Where-Object {$_.TempDrive -eq $tmpDrive.DeviceId} | Where-Object {$_.Status -ne "Completed"}
        if ($activeJobs)
            {
                $HasPlotInProgress = $true
                $PlotInProgressName = $activeJobs.PlotId
                $PlotInProgressCount = $activeJobs.count
                $PlotInProgressPhase = $activeJobs.Status

                if ($PlotInProgressCount -eq $null)
                    {
                        $PlotInProgressCount = 1
                    }
                
                $RedundencyCheck = $DiskSize - ($FreeSpace + $PlotInProgressCount * 290)
                #has addiontal data in the disk
                if($RedundencyCheck -gt 0)
                    {
                        $AmountOfPlotsToTempMax = [math]::Floor(($FreeSpace / 290))
                        $AvailableAmounToPlot = $AmountOfPlotsToTempMax - $PlotInProgressCount
                    }
                else
                    {
                        $AmountOfPlotsinProgressOccupied = [math]::Floor(($PlotInProgressCount * 290))
                        $AvailableAmounToPlot = [math]::Floor(($DiskSize - $AmountOfPlotsinProgressOccupied) / 290)
                        $AmountOfPlotsToTempMax = $AvailableAmounToPlot + $PlotInProgressCount
                    }

            }

        else
            {
                $HasPlotInProgress = $false
                $PlotInProgressName = " "
                $PlotInProgressCount = 0
                $AmountOfPlotsToTempMax = [math]::Floor(($FreeSpace / 290))
                $AvailableAmounToPlot = $AmountOfPlotsToTempMax
            }


        if ($AvailableAmounToPlot -ge 1)
            {
                $IsPlottable = $true
            }
        else
            {
                $IsPlottable = $false
            }

        
        $driveToPass = [PSCustomObject]@{
        DriveLetter     =  $tmpDrive.DeviceID
        ChiaDriveType = "Temp"
        Disk = $Disk.Model
        DiskType = $PhysicalDisk.MediaType
        DiskBus = $PhysicalDisk.BusType
        VolumeName = $tmpDrive.VolumeName
        FreeSpace = $FreeSpace
        TotalSpace = $DiskSize
        hasFolder = $HasFolder
        IsPlottable    = $IsPlottable
        HasPlotInProgress = $HasPlotInProgress
        AmountOfPlotsInProgress =  $PlotInProgressCount
        AmountOfPlotsToTempMax = $AmountOfPlotsToTempMax
        AvailableAmountToPlot = $AvailableAmounToPlot
        PlotInProgressID = $PlotInProgressName
        PlotInProgressPhase = $PlotInProgressPhase

        }

        $collectionWithDisks.Add($driveToPass) | Out-Null

    }
    return $collectionWithDisks 
}

function Get-PlotoT2Drives
{

	Param(
        [parameter(Mandatory=$true)]
		$T2Denom
		)

$tmp2drives = Get-CimInstance win32_logicaldisk -Verbose:$false | Where-Object {$_.VolumeName -like "*$T2Denom*"}


#Check Space for outDrives
$collectionWithDisks= New-Object System.Collections.ArrayList
foreach ($tmp2Drive in $tmp2Drives)
    {
        $FolderCheck = Get-ChildItem $tmp2Drive.DeviceId | Where-Object {$_.Attributes -eq "Directory"}
        if ($FolderCheck)
            {
                $HasFolder = $true
            }
        else
            {
                $HasFolder = $false
            }
        
        $DiskSize = ([math]::Round($tmp2Drive.Size  / 1073741824, 2))
        $FreeSpace = [math]::Round($tmp2Drive.FreeSpace  / 1073741824, 2)

        $Partition = Get-Partition | Where-Object {$_.DriveLetter -eq ($tmp2Drive.DeviceId.TrimEnd(":"))}

        If ($Partition.DiskNumber -eq $null)
            {
                Write-Host "PlotoSpawner @ "(Get-Date)": Cannot get disks for the logical volume" $tmp2Drive.DeviceId "by PowerShell using Get-Partition/Get-Disk cmdlet. Cannot get the disk and temperature for reporting. Can keep going." -ForegroundColor Yellow
            }

        #$approxDiskModel = $Partition.DiskPathsplit("&")[2].trimstart("prod_").Replace("_", " ").Split("#")[0]

        $oldea = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"

        #Get Disk from partition
        $Disk = Get-Disk -Number $Partition.DiskNumber
        $PhysicalDisk = Get-PhysicalDisk | Where-Object {$_.FriendlyName -eq $Disk.Model}

        $ErrorActionPreference = $oldea

        #Get-CurrenJobs
        $activeJobs = Get-PlotoJobs | Where-Object {$_.T2Drive -eq $tmp2Drive.DeviceId} | Where-Object {$_.Status -ne "Completed"}
        if ($activeJobs)
            {
                $HasPlotInProgress = $true
                $PlotInProgressName = $activeJobs.PlotId
                $PlotInProgressCount = $activeJobs.count
                $PlotInProgressPhase = $activeJobs.Status

                

                if ($PlotInProgressCount -eq $null)
                    {
                        $PlotInProgressCount = 1
                    }
                
                $RedundencyCheck = $DiskSize - ($FreeSpace + $PlotInProgressCount * 107)
                #has addiontal data in the disk
                if($RedundencyCheck -gt 0)
                    {
                        $AmountOfPlotsToTempMax = [math]::Floor(($FreeSpace / 107))
                        $AvailableAmounToPlot = $AmountOfPlotsToTempMax - $PlotInProgressCount
                    }
                else
                    {
                        $AmountOfPlotsinProgressOccupied = [math]::Floor(($PlotInProgressCount * 107))
                        $AvailableAmounToPlot = [math]::Floor(($DiskSize - $AmountOfPlotsinProgressOccupied) / 107)
                        $AmountOfPlotsToTempMax = $AvailableAmounToPlot + $PlotInProgressCount
                    }
            }

        else
            {
                $HasPlotInProgress = $false
                $PlotInProgressName = " "
                $PlotInProgressCount = 0
                $AmountOfPlotsToTempMax = [math]::Floor(($FreeSpace / 107))
                $AvailableAmounToPlot = $AmountOfPlotsToTempMax
            }


        if ($AvailableAmounToPlot -ge 1)
            {
                $IsPlottable = $true
            }
        else
            {
                $IsPlottable = $false
            }

        
        $driveToPass = [PSCustomObject]@{
        DriveLetter     =  $tmp2Drive.DeviceId
        ChiaDriveType = "T2"
        Disk = $Disk.Model
        DiskType = $PhysicalDisk.MediaType
        DiskBus = $PhysicalDisk.BusType
        VolumeName = $tmp2Drive.VolumeName
        FreeSpace = $FreeSpace
        TotalSpace = $DiskSize
        hasFolder = $HasFolder
        IsPlottable    = $IsPlottable
        HasPlotInProgress = $HasPlotInProgress
        AmountOfPlotsInProgress =  $PlotInProgressCount
        AmountOfPlotsToTempMax = $AmountOfPlotsToTempMax
        AvailableAmountToPlot = $AvailableAmounToPlot
        PlotInProgressID = $PlotInProgressName
        PlotInProgressPhase = $PlotInProgressPhase
        }

        $collectionWithDisks.Add($driveToPass) | Out-Null

    }
    return $collectionWithDisks


}

function Invoke-PlotoJob
{
	Param(
		[parameter(Mandatory=$true)]
		$OutDriveDenom,
	    [parameter(Mandatory=$true)]
	    $InputAmountToSpawn,
		[parameter(Mandatory=$true)]
		$TempDriveDenom,
	    [parameter(Mandatory=$true)]
	    $WaitTimeBetweenPlotOnSeparateDisks,
	    [parameter(Mandatory=$false)]
	    $WaitTimeBetweenPlotOnSameDisk,
        [Parameter(Mandatory=$true)]
        $MaxParallelJobsOnAllDisks,
        [Parameter(Mandatory=$false)]
        $MaxParallelJobsOnSameDisk,
        [Parameter(Mandatory=$false)]
        $BufferSize=3390,
        $Thread=2,
        $EnableBitfield=$true,
        $EnableAlerts,
        $CountSpawnedJobs,
        $T2Denom,
        $WindowStyle,
        $FarmerKey,
        $PoolKey,
        $MaxParallelJobsInPhase1OnSameDisk,
        $MaxParallelJobsInPhase1OnAllDisks,
        $StartEarly,
        $StartEarlyPhase
		)

 if($verbose) {

   $oldverbose = $VerbosePreference
   $VerbosePreference = "continue" }

if ($MaxParallelJobsOnSameDisk -eq $null)
    {
        $MaxParallelJobsOnSameDisk = 15
    }
if ($WaitTimeBetweenPlotOnSameDisk -eq $null)
    {
        $WaitTimeBetweenPlotOnSameDisk = 30
    }

$PathToAlarmConfig = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"

try 
    {
        $config = Get-Content -raw -Path $PathToAlarmConfig | ConvertFrom-Json -ErrorAction Stop
        Write-Verbose "Loaded Alarmconfig successfully"
    }
catch
    {
         Throw $_.Exception.Message
         exit
    } 


Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Invoking PlotoJobs started.")

$PlottableTempDrives = Get-PlotoTempDrives -TempDriveDenom $TempDriveDenom | Where-Object {$_.IsPlottable -eq $true}   
$PlottableOutDrives = Get-PlotoOutDrives -OutDriveDenom $OutDriveDenom | Where-Object {$_.IsPlottable -eq $true}



if ($PlottableOutDrives -eq $null)
    {
        Throw "Error: No outdrives found"
        exit
    } 

$collectionWithPlotJobs= New-Object System.Collections.ArrayList
$JobCountAll0 = ((Get-PlotoJobs | Where-Object {$_.Status -ne "Completed"}) | Measure-Object).Count

$counter = $CountSpawnedJobs

if ($PlottableTempDrives -and $JobCountAll0 -lt $MaxParallelJobsOnAllDisks)
    {
         Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Found available temp drives.")
         foreach ($PlottableTempDrive in $PlottableTempDrives)
            {
                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+":  We have drives available that allow jobs to be spawned based on -MaxParallelJobsOnAllDisks and $MaxParallJobsOnSameDisk")
                #Lets get the best suited TempDrive (The one with least amount of jobs ongoing)
                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+":  Scanning for the drive with least amount of jobs...")
                $PlottableTempDrives = Get-PlotoTempDrives -TempDriveDenom $TempDriveDenom | Where-Object {$_.IsPlottable -eq $true}   

                $min = ($PlottableTempDrives | measure-object -Property AmountOfPlotsInProgress -minimum).minimum
                $PlottableTempDrive = $PlottableTempDrives | Where-Object { $_.AmountOfPlotsInProgress -eq $min}

                if ($PlottableTempDrive.Count -gt 1)
                {
                    #We have several OutDisks in our Array that could be the best OutDrive. Need to pick one!
                    $PlottableTempDrive = $PlottableTempDrive[0]
                }

               Write-Verbose ("PlotoSpawner @ "+(Get-Date)+":  Will be using TempDrive: "+$PlottableTempDrive.DriveLetter+" to check for jobs on it...")

               $JobsAll = Get-PlotoJobs

               if ($StartEarly -eq "true")
                    {
                        Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": StartEarly set to true")
                        #Check amount of Jobs ongoin
                        $JobCountAll = (($JobsAll | Where-Object {$_.Status -lt $StartEarlyPhase}) | Measure-Object).Count
                        $JobCountOnSameDisk = (($JobsAll | Where-Object {$_.Status -lt $StartEarlyPhase} | Where-Object {$_.TempDrive -eq $PlottableTempDrive.DriveLetter}) | Measure-Object).Count
                        $AmountOfJobsInPhase1OnThisDisk = ($JobsAll| Where-Object {$_.TempDrive -eq $PlottableTempDrive.DriveLetter} | Where-Object {$_.Status -lt 2 -and $Status -ne "Completed" -or $_.Status -ne "Aborted" } | Measure-Object).Count
                        $AmountOfJobsInPhase1OnAllDisks = ($JobsAll | Where-Object {$_.Status -lt 2 -and $Status -ne "Completed" -or $_.Status -ne "Aborted" } | Measure-Object).Count
                    }
                else 
                    {
                        #Check amount of Jobs ongoin
                        $JobCountAll = (($JobsAll | Where-Object {$_.Status -ne "Completed"}) | Measure-Object).Count
                        $JobCountOnSameDisk = (($JobsAll | Where-Object {$_.Status -ne "Completed"} | Where-Object {$_.TempDrive -eq $PlottableTempDrive.DriveLetter}) | Measure-Object).Count
                        $AmountOfJobsInPhase1OnThisDisk = ($JobsAll | Where-Object {$_.TempDrive -eq $PlottableTempDrive.DriveLetter} | Where-Object {$_.Status -lt 2 -and $Status -ne "Completed" -or $_.Status -ne "Aborted" } | Measure-Object).Count
                        $AmountOfJobsInPhase1OnAllDisks = ($JobsAll | Where-Object {$_.Status -lt 2 -and $Status -ne "Completed" -or $_.Status -ne "Aborted" } | Measure-Object).Count
                    }


                #Check JobCountagain
                if ($JobCountAll -lt $MaxParallelJobsOnAllDisks)
                    {

                         Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": -MaxParallelJobsOnAllDisks and MaxParallJobsOnSameDisk allow spawning. Iterating trough TempDrive: "+$PlottableTempDrive.DriveLetter)

                                                
                        if ($JobCountOnSameDisk -lt $MaxParallelJobsOnSameDisk -and $AmountOfJobsInPhase1OnThisDisk -lt $MaxParallelJobsInPhase1OnSameDisk -and $AmountOfJobsInPhase1OnAllDisks -lt $MaxParallelJobsInPhase1OnAllDisks)
                            {

                                # Did we spawn a PlotJob on this Disk within the duration specified in -WaitTimeBetweenPlotOnSameDisk? If yes, we gotta skip
                                $CheckPeriod = (Get-Date).AddMinutes(-$WaitTimeBetweenPlotOnSameDisk)
                                if ($StartEarly -eq "true")
                                    {
                                        $JobsOnThisDiskIPWithinCheckPeriod = Get-PlotoJobs | Where-Object {$_.Status -lt $StartEarlyPhase} | Where-Object {$_.StartTime -gt $CheckPeriod } | Where-Object {$_.TempDrive -eq $PlottableTempDrive.DriveLetter}

                                    }
                                else
                                    {
                                        $JobsOnThisDiskIPWithinCheckPeriod = Get-PlotoJobs | Where-Object {$_.StartTime -gt $CheckPeriod } | Where-Object {$_.TempDrive -eq $PlottableTempDrive.DriveLetter}
                                    }

                                if (!$JobsOnThisDiskIPWithinCheckPeriod)
                                    {
 
                                    $PlottableOutDrives = Get-PlotoOutDrives -OutDriveDenom $OutDriveDenom | Where-Object {$_.IsPlottable -eq $true}
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": -MaxParallelJobsOnAllDisks and -MaxParallelJobsOnSameDisk allow spawning")
                                    $min = ($PlottableOutDrives | measure-object -Property AmountOfPlotsInProgress -minimum).minimum
                                    $OutDrive = $PlottableOutDrives | Where-Object { $_.AmountOfPlotsInProgress -eq $min}

                                    if ($OutDrive.Count -gt 1)
                                        {
                                            #We have several OutDisks in our Array that could be the best OutDrive. Need to pick one!
                                            $OutDrive = $OutDrive[0]
                                        }

                                    if ($OutDrive -eq $null)
                                        {

                                        if ($EnableAlerts -eq $true -and $config.SpawnerAlerts.WhenNoOutDrivesAvailable -eq $true)
                                            {
                                                #Create embed builder object via the [DiscordEmbed] class
                                                $embedBuilder = [DiscordEmbed]::New(
                                                                    'Sorry to bother you but we cant move on. No Outdrives available. ',
                                                                    'I ran into trouble. I wanted to spawn a new plot, but it seems we either ran out of space on our OutDrives or I just cant find them. You sure you gave the right denominator for them? I stopped myself now. Please check your OutDrives, and if applicable, move some final plots away from it.'
                                                                )

                                                #Add purple color
                                                $embedBuilder.WithColor(
                                                    [DiscordColor]::New(
                                                        'red'
                                                    )
                                                )

                                                $plotname = $config.PlotterName
                                                $footie = "Ploto: "+$plotname
                                                #Add a footer
                                                $embedBuilder.AddFooter(
                                                    [DiscordFooter]::New(
                                                        $footie
                                                    )
                                                )

                                                $WebHookURL = $config.SpawnerAlerts.DiscordWebHookURL

                                                Invoke-PsDsHook -CreateConfig $WebHookURL -Verbose:$false
                                                Invoke-PSDsHook $embedBuilder -Verbose:$false
                                    
                                            }
                                
                                        Throw "Error: No outdrives found"
                                        exit
                                        
                                        }

                                    $OutDriveLetter = $OutDrive.DriveLetter
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Best Outdrive most least jobs: "+$OutDriveLetter)

                                    $PlotoSpawnerJobId = ([guid]::NewGuid()).Guid
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": GUID for PlotoSpawnerID: "+$PlotoSpawnerJobId)

                                    $ChiaBasePath = "$env:LOCALAPPDATA\chia-blockchain"

                                    $ChiaVersion = ((Get-ChildItem $ChiaBasePath | Where-Object {$_.Name -like "*app*"}).Name.Split("-"))[1]
                                    $PathToChia = $ChiaBasePath+"\app-"+$ChiaVersion+"\resources\app.asar.unpacked\daemon\chia.exe" 
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Calculated path to chia.exe: "+$PathToChia)

                                    $PlotterBaseLogPath = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\plotter\"
                                    $LogNameBasePath = "PlotoSpawnerLog_"+((Get-Date).Day.ToString())+"_"+(Get-Date).Month.ToString()+"_"+(Get-Date).Hour.ToString()+"_"+(Get-Date).Minute.ToString()+"_"+$PlotoSpawnerJobId+"_Tmp-"+(($PlottableTempDrive).DriveLetter.Split(":"))[0]+"_Out-"+($OutDriveLetter.Split(":"))[0]+".txt"
                                    $LogPath= $PlotterBaseLogPath+$LogNameBasePath
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Calculated LogPath "+$LogPath)

                                    $StartTime = (Get-Date)

                                    $logstatName = "PlotoSpawnerLog_"+((Get-Date).Day.ToString())+"_"+(Get-Date).Month.ToString()+"_"+(Get-Date).Hour.ToString()+"_"+(Get-Date).Minute.ToString()+"_"+$PlotoSpawnerJobId+"_Tmp-"+(($PlottableTempDrive).DriveLetter.Split(":"))[0]+"_Out-"+($OutDriveLetter.Split(":"))[0]+"@Stat.txt"
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Calculated LogStatName "+$logstatName)

                                    $logPath1 = (New-Item -Path $PlotterBaseLogPath -Name $logstatName).FullName
                                    Add-Content -Path $LogPath1 -Value "PlotoSpawnerJobId: $PlotoSpawnerJobId"
                                    Add-Content -Path $LogPath1 -Value "OutDrive: $OutDrive"
                                    Add-Content -Path $LogPath1 -Value "TempDrive: $PlottableTempDrive"
                                    Add-Content -Path $LogPath1 -Value "StartTime: $StartTime"
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Created LogStat file and passed values along.")

                                    if ($EnableBitfield -eq $true -or $EnableBitfield -eq "true")
                                        {
                                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Bitfield is set to be used.")

                                            if ($T2Denom -and $config.DiskConfig.EnableT2 -eq "true")
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": using T2. Scanning for most suitable...")
                                                    #Get best fitted t2 Drive 
                                                    $PlottableT2Drives = Get-PlotoT2Drives -T2denom $T2Denom | Where-Object {$_.IsPlottable -eq $true}   
                                                    $min = ($PlottableT2Drives | measure-object -Property AmountOfPlotsInProgress -minimum).minimum
                                                    $t2drive = $PlottableT2Drives | Where-Object { $_.AmountOfPlotsInProgress -eq $min}
                                            
                                                    if ($t2drive.Count -gt 1)
                                                        {
                                                            #We have several OutDisks in our Array that could be the best OutDrive. Need to pick one!
                                                            $t2drive = $t2drive[0]
                                                            $t2driveletter = $t2drive.DriveLetter
                                                        }

                                                    else
                                                        {
                                                            $t2driveletter = $t2drive.DriveLetter
                                                        }

                                                    

                                                    if ($t2drive -eq $null)
                                                        {
                                                            $t2drive = "None"
                                                            $t2driveletter = "None"
                                                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": T2 is set to be used, but currently no T2 available. Will be using no T2 for this job.")
                                                            $ArgumentList = "plots create -k 32 -b "+$BufferSize+" -r "+$Thread+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\"
                                                        }
                                                    else
                                                        {
                                                            $ArgumentList = "plots create -k 32 -b "+$BufferSize+" -r "+$Thread+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -2 "+$t2driveletter+"\"
                                                        }
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Using T2 Drive: "+$t2driveletter)

                                                    Add-Content -Path $LogPath1 -Value "T2Drive: $t2drive"
                                                    
                                                }
                                            else
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Not using T2 drive.")
                                                    Add-Content -Path $LogPath1 -Value "T2Drive: None"
                                                    $t2driveletter = "None"
                                                    $ArgumentList = "plots create -k 32 -b "+$BufferSize+" -r "+$Thread+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\"
                                                } 
                                        }

                                    else
                                        {
                                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Bitfield is not used.")
                                            
                                            if ($T2Denom -and $config.DiskConfig.EnableT2 -eq "true")
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": using T2. Scanning for most suitable...")
                                                    #Get best fitted t2 Drive 
                                                    $PlottableT2Drives = Get-PlotoT2Drives -T2denom $T2Denom | Where-Object {$_.IsPlottable -eq $true}   
                                                    $min = ($PlottableT2Drives | measure-object -Property AmountOfPlotsInProgress -minimum).minimum
                                                    $t2drive = $PlottableT2Drives | Where-Object { $_.AmountOfPlotsInProgress -eq $min}
                                            
                                                    if ($t2drive.Count -gt 1)
                                                        {
                                                            #We have several OutDisks in our Array that could be the best OutDrive. Need to pick one!
                                                            $t2drive = $t2drive[0]
                                                            $t2driveletter = $t2drive.DriveLetter
                                                        }

                                                    else
                                                        {
                                                            $t2driveletter = $t2drive.DriveLetter
                                                        }

                                                    

                                                    if ($t2drive -eq $null)
                                                        {
                                                            $t2drive = "None"
                                                            $t2driveletter = "None"
                                                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": T2 is set to be used, but currently no T2 available. Will be using no T2 for this job.")
                                                            $ArgumentList = "plots create -k 32 -b "+$BufferSize+" -r "+$Thread+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\"
                                                        }
                                                    else
                                                        {
                                                            $ArgumentList = "plots create -k 32 -b "+$BufferSize+" -r "+$Thread+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -2 "+$t2driveletter+"\"
                                                        }
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Using T2 Drive: "+$t2driveletter)

                                                    Add-Content -Path $LogPath1 -Value "T2Drive: $t2drive"

                                                }
                                            else
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Not using T2 drive.")
                                                    Add-Content -Path $LogPath1 -Value "T2Drive: None"
                                                    $t2driveletter = "None"
                                                    $ArgumentList = "plots create -k 32 -b "+$BufferSize+" -r "+$Thread+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -e"
                                                }
                                           }

                                    if ($FarmerKey -ne $null -or $FarmerKey -ne "")
                                        {
                                            #Lets check if its a Key
                                            $CharArray = $FarmerKey.ToCharArray()
                                            if ($CharArray.Count -eq 96)
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": This looks like a valid key based on its length")
                                                    $ExpandedArgs = "-f "+$FarmerKey
                                                    $ArgumentList = $ArgumentList+" "+$ExpandedArgs
                                                }

                                        }

                                    if ($PoolKey -ne $null -or $PoolKey -ne "")
                                        {
                                            #Lets check if its a Key
                                            $CharArray = $PoolKey.ToCharArray()
                                            if ($CharArray.Count -eq 96)
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": This looks like a valid key based on its length")
                                                    $ExpandedArgs = "-p "+$PoolKey
                                                    $ArgumentList = $ArgumentList+" "+$ExpandedArgs
                                                }

                                        }

                                    try 
                                        {
                                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Launching chia.exe with params.")
                                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Using ArgumentList:"+$ArgumentList)
                                            Add-Content -Path $LogPath1 -Value "ArgumentList: $ArgumentList"


                                            $chiaexe = Start-Process $PathToChia -ArgumentList $ArgumentList -RedirectStandardOutput $LogPath -PassThru -WindowStyle $WindowStyle
                                            $procid = $chiaexe.Id
                                            Add-Content -Path $LogPath1 -Value "PID: $procid" -Force
                                            Write-Verbose ("PlotoSpawner @"+(Get-Date)+": Added PID to LogStatFile.")
                                            $counter = $counter+1

                                            #Getting Plot Object Ready
                                            $PlotJob = [PSCustomObject]@{
                                            JobId = $PlotoSpawnerJobId
                                            ProcessID = $chiaexe.Id
                                            OutDrive     =  $OutDriveLetter
                                            TempDrive = $PlottableTempDrive.DriveLetter
                                            T2Drive = $t2driveletter
                                            ArgumentsList = $ArgumentList
                                            ChiaVersionUsed = $ChiaVersion
                                            LogPath = $LogPath
                                            StartTime = $StartTime
                                            }

                                            $AmountOfJobsSpawned = $AmountOfJobsSpawned++
                                
                                            $collectionWithPlotJobs.Add($PlotJob) | Out-Null

                                            Write-Host "PlotoSpawner @"(Get-Date)": Spawned the following plot Job:" -ForegroundColor Green
                                            $PlotJob | Out-Host
                                            Write-Host "--------------------------------------------------------------------"
                               

                                            if ($EnableAlerts -eq $true -and $config.SpawnerAlerts.WhenJobSpawned -eq "true")
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        {
                                                Write-Host "PlotoSpawner @"(Get-Date)": Event notification in config defined. Sending Discord Notification about spawned job..."

                                                try 
                                                    {
                                                        #Create embed builder object via the [DiscordEmbed] class
                                                        $embedBuilder = [DiscordEmbed]::New(
                                                                            'New Job Spawned',
                                                                            'Hei its Ploto here. I spawned a new plot job for you.'
                                                                        )

                                                        #Create the field and then add it to the embed. The last value ($true) is if you want it to be in-line or not
                                                        $embedBuilder.AddField(
                                                            [DiscordField]::New(
                                                                'JobId', 
                                                                $PlotoSpawnerJobId, 
                                                                $true
                                                            )
                                                        )

                                                        $embedBuilder.AddField(
                                                            [DiscordField]::New(
                                                                'StartTime',
                                                                $StartTime, 
                                                                $true
                                                            )
                                                        )

                                                        $embedBuilder.AddField(
                                                            [DiscordField]::New(
                                                                'ProcessId',
                                                                $procid, 
                                                                $true
                                                            )
                                                        )

                                                        $tempdriveoutp = $PlottableTempDrive.DriveLetter
                                                        $embedBuilder.AddField(
                                                            [DiscordField]::New(
                                                                'TempDrive',
                                                                $tempdriveoutp, 
                                                                $true
                                                            )
                                                        )


                                                        $embedBuilder.AddField(
                                                            [DiscordField]::New(
                                                                'OutDrive',
                                                                $OutDriveLetter, 
                                                                $true
                                                            )
                                                        )

                                                        $embedBuilder.AddField(
                                                            [DiscordField]::New(
                                                                'ArgumentList',
                                                                $ArgumentList, 
                                                                $true
                                                            )
                                                        )

                                                        $embedBuilder.AddField(
                                                            [DiscordField]::New(
                                                                'Max parallel Jobs in progress allowed',
                                                                $MaxParallelJobsOnAllDisks, 
                                                                $true
                                                            )
                                                        )



                                                        #Add purple color
                                                        $embedBuilder.WithColor(
                                                            [DiscordColor]::New(
                                                                'blue'
                                                            )
                                                        )


                                                        $plotname = $config.PlotterName
                                                        $footie = "Ploto: "+$plotname

                                                        #Add a footer
                                                        $embedBuilder.AddFooter(
                                                            [DiscordFooter]::New(
                                                                $footie
                                                            )
                                                        )

                                                        $WebHookURL = $config.SpawnerAlerts.DiscordWebHookURL

                                                        Invoke-PsDsHook -CreateConfig $WebHookURL -Verbose:$false | Out-Null
                                                        Invoke-PSDsHook $embedBuilder -Verbose:$false | Out-Null 
                                                    }
                                                catch
                                                    {
                                                        Write-Host "PlotoSpawner @"(Get-Date)": ERROR! Could not send Discord API Call or received Bad request" -ForegroundColor Red
                                                        Write-Host "PlotoSpawner @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
                                                    }

                                            }

                                            #Deduct 106GB from OutDrive Capacity in Var
                                            $DeductionOutDrive = ($OutDrive.FreeSpace - 106)
                                            $OutDrive.FreeSpace="$DeductionOutDrive"

                                        }

                                    catch
                                        {
                                            Write-Host "PlotoSpawner @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
                                            Write-Verbose ("PlotoSpawner @"+(Get-Date)+": ERROR! Could not launch chia.exe. Check chiapath and arguments (make sure version is set correctly!). Arguments used: "+$ArgumentList)

                                            if ($EnableAlerts -eq $true -and $config.SpawnerAlerts.WhenJobCouldNotBeSpawned -eq $true)
                                                                                                                                                                                                                                                                                                                            {

                                                #Create embed builder object via the [DiscordEmbed] class
                                                $embedBuilder = [DiscordEmbed]::New(
                                                                    'Woops. Something happened. Could not spawn a job ',
                                                                    'I ran into trouble. I wanted to spawn a new plot, but something generated an error. Could Either not launch chia.exe due to missing parameters or potentially more than 1 version directory of chia is available. See below for details.'
                                                                )
                                                $embedBuilder.AddField(
                                                    [DiscordField]::New(
                                                        'JobId', 
                                                        $PlotoSpawnerJobId, 
                                                        $true
                                                    )
                                                )

                                                $embedBuilder.AddField(
                                                    [DiscordField]::New(
                                                        'StartTime',
                                                        $StartTime, 
                                                        $true
                                                    )
                                                )

                                                $embedBuilder.AddField(
                                                    [DiscordField]::New(
                                                        'ProcessId',
                                                        $procid, 
                                                        $true
                                                    )
                                                )

                                                $tempdriveoutp = $PlottableTempDrive.DriveLetter
                                                $embedBuilder.AddField(
                                                    [DiscordField]::New(
                                                        'TempDrive',
                                                        $tempdriveoutp, 
                                                        $true
                                                    )
                                                )


                                                $embedBuilder.AddField(
                                                    [DiscordField]::New(
                                                        'OutDrive',
                                                        $OutDriveLetter, 
                                                        $true
                                                    )
                                                )

                                                $embedBuilder.AddField(
                                                    [DiscordField]::New(
                                                        'ArgumentList',
                                                        $ArgumentList, 
                                                        $true
                                                    )
                                                )


                                                #Add purple color
                                                $embedBuilder.WithColor(
                                                    [DiscordColor]::New(
                                                        'red'
                                                    )
                                                )

                                                $plotname = $config.PlotterName
                                                $footie = "Ploto: "+$plotname
                                                #Add a footer
                                                $embedBuilder.AddFooter(
                                                    [DiscordFooter]::New(
                                                        $footie
                                                    )
                                                )

                                                $WebHookURL = $config.SpawnerAlerts.DiscordWebHookURL

                                                Invoke-PsDsHook -CreateConfig $WebHookURL -Verbose:$false | Out-Null
                                                Invoke-PSDsHook $embedBuilder -Verbose:$false | Out-Null
                                    
                                            }
                                        }                 
                                    }

                                     if ($Counter -ge $InputAmountToSpawn)
                                        {
                                            Write-Host "We are done!" -ForegroundColor Green
                                            break
                                        }

                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Starting to sleep for"+$WaitTimeBetweenPlotOnSeparateDisks+" Minutes, to comply with Param.")
                                    Start-Sleep ($WaitTimeBetweenPlotOnSeparateDisks*60)
                                }
                        else
                            {

                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Plotting not allowed. Is prohibited by MaxParallelJobsOnSameDisk, MaxParallelJobsInPhase1OnSameDisk, or MaxParallelJobsInPhase1OnAllDisks.")  
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Job count all jobs on dthis drive: "+$JobCountOnSameDisk) 
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Max allowed on this drive in all phases: "+$MaxParallelJobsOnSameDisk)
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Job count in P1 on this drive: "+$AmountOfJobsInPhase1OnThisDisk) 
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Max allowed on this drive in P1: "+$MaxParallelJobsInPhase1OnSameDisk)                    
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Job count in P1 on all drives: "+$AmountOfJobsInPhase1OnAllDisks) 
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Max allowed on all drives in P1: "+$MaxParallelJobsInPhase1OnAllDisks) 
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Skipping Drive: "+$PlottableTempDrive)
                            }
                     }


                else
                    {
                                
                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Found an available Temp Drive, but -MaxParallelJobsOnAllDisks,  -MaxParallelJobsOnSameDisk or -WaitTimeBetweenPlotsOnSameDisk prohibits spawning for now.")  
                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Amount of Plots in Progress overall: "+$JobCountAll)                    
                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Amount of Plots in Progress on this Drive: "+$JobCountOnSameDisk) 
                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Skipping Drive: "+$PlottableTempDrive)
                    }                             

                }
                         
    }    
else
    {
        Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": No Jobs spawned as either no TempDrives available or max parallel jobs reached. Max Parallel Jobs: "+$MaxParallelJobsOnAllDisks+ "Current amount of Jobs: "+ $JobCountAll0 )
    }

   $VerbosePreference = $oldverbose
   return $collectionWithPlotJobs
 
}

function Start-PlotoSpawns
{
	Param(
    [switch]$Verbose
    )

    if($verbose) 
        {
            $oldverbose = $VerbosePreference
            $VerbosePreference = "continue" 
        }

    Write-Host "PlotoManager @"(Get-Date)": Ploto Manager started."
    Write-Host "PlotoManager @"(Get-Date)": Loading config from C:\Users\me\.chia\mainnet\config..."
    $PathToConfig = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"

    try 
        {
            $config = Get-Content -raw -Path $PathToConfig | ConvertFrom-Json
            Write-Verbose "Loaded config successfully"
        }
    catch
        {
             Throw $_.Exception.Message
        } 

    #setting params from config 
    [int]$IntervallToWait= $config.JobConfig.IntervallToCheckInMinutes
    [int]$InputAmountToSpawn = $config.JobConfig.InputAmountToSpawn 
    [int]$WaitTimeBetweenPlotOnSeparateDisks = $config.JobConfig.WaitTimeBetweenPlotOnSeparateDisks
    [int]$WaitTimeBetweenPlotOnSameDisk = $config.JobConfig.WaitTimeBetweenPlotOnSameDisk
    $OutDriveDenom = $config.DiskConfig.OutDriveDenom
    $TempDriveDenom = $config.DiskConfig.TempDriveDenom
    $t2denom = $config.DiskConfig.Temp2Denom
    [int]$MaxParallelJobsOnAllDisks = $config.JobConfig.MaxParallelJobsOnAllDisks
    [int]$MaxParallelJobsOnSameDisk = $config.JobConfig.MaxParallelJobsOnSameDisk
    [int]$BufferSize = $config.JobConfig.BufferSize
    [int]$Thread = $config.JobConfig.Thread
    $EnableBitfield = $config.JobConfig.Bitfield
    $EnableAlerts = $config.EnableAlerts
    $WindowStyle = $config.ChiaWindowStyle
    $FarmerKey = $config.JobConfig.FarmerKey
    $PoolKey = $config.JobConfig.PoolKey
    $MaxParallelJobsInPhase1OnSameDisk = $config.JobConfig.MaxParallelJobsInPhase1OnSameDisk
    $MaxParallelJobsInPhase1OnAllDisks = $config.JobConfig.MaxParallelJobsInPhase1OnAllDisks
    $StartEarly = $config.JobConfig.StartEarly
    $StartEarlyPhase = $config.JobConfig.StartEarlyPhase
    $EnableFy = $config.EnablePlotoFyOnStart


    Write-Host "PlotoManager @"(Get-Date)": InputAmountToSpawn:" $InputAmountToSpawn
    Write-Host "PlotoManager @"(Get-Date)": Intervall to wait:" $IntervallToWait

    if ($EnableFy -eq "true")
        {
            Write-Host "PlotoManager @"(Get-Date)": PlotoFy is set to startup. Checking for active PlotoFy jobs..."

            $bgjobs = Get-Job | Where-Object {$_.Name -like "*PlotoFy*"}
            if ($bgjobs)
                {
                    $bgjobs | Stop-Job | Remove-Job
                }
            try 
                {
                    Start-PlotoFy
                }
            catch
                {
                    Write-Host "Could not launch PlotoFy!" -ForegroundColor Red
                }
            
        }

    $SpawnedCountOverall = 0 

    Do
    {
            if  (Get-PlotoJobs | Where-Object {$_.Status -eq "Aborted"})

                {
                    Write-Host "PlotoManager @"(Get-Date)": Detected aborted jobs. Removing them..."
                    Remove-AbortedPlotoJobs
                }

        if ($verbose)
            {
                $SpawnedPlots = Invoke-PlotoJob -BufferSize $BufferSize -Thread $Thread -OutDriveDenom $OutDriveDenom -TempDriveDenom $TempDriveDenom -EnableBitfield $EnableBitfield -WaitTimeBetweenPlotOnSeparateDisks $WaitTimeBetweenPlotOnSeparateDisks -WaitTimeBetweenPlotOnSameDisk $WaitTimeBetweenPlotOnSameDisk -MaxParallelJobsOnAllDisks $MaxParallelJobsOnAllDisks -MaxParallelJobsOnSameDisk $MaxParallelJobsOnSameDisk -EnableAlerts $EnableAlerts -InputAmountToSpawn $InputAmountToSpawn -CountSpawnedJobs $SpawnedCountOverall -T2Denom $t2denom -WindowStyle $WindowStyle -FarmerKey $FarmerKey -PoolKey $PoolKey -MaxParallelJobsInPhase1OnSameDisk $MaxParallelJobsInPhase1OnSameDisk -MaxParallelJobsInPhase1OnAllDisks $MaxParallelJobsInPhase1OnAllDisks -StartEarly $StartEarly -StartEarlyPhase $StartEarlyPhase -Verbose
            }
        else
            {
                $SpawnedPlots = Invoke-PlotoJob -BufferSize $BufferSize -Thread $Thread -OutDriveDenom $OutDriveDenom -TempDriveDenom $TempDriveDenom -EnableBitfield $EnableBitfield -WaitTimeBetweenPlotOnSeparateDisks $WaitTimeBetweenPlotOnSeparateDisks -WaitTimeBetweenPlotOnSameDisk $WaitTimeBetweenPlotOnSameDisk -MaxParallelJobsOnAllDisks $MaxParallelJobsOnAllDisks -MaxParallelJobsOnSameDisk $MaxParallelJobsOnSameDisk -EnableAlerts $EnableAlerts -InputAmountToSpawn $InputAmountToSpawn -CountSpawnedJobs $SpawnedCountOverall -T2Denom $t2denom -WindowStyle $WindowStyle -FarmerKey $FarmerKey -PoolKey $PoolKey -MaxParallelJobsInPhase1OnSameDisk $MaxParallelJobsInPhase1OnSameDisk -MaxParallelJobsInPhase1OnAllDisks $MaxParallelJobsInPhase1OnAllDisks -StartEarly $StartEarly -StartEarlyPhase $StartEarlyPhase
            }
        
        
        if ($SpawnedPlots)
            {
                $SpawnedCountThisIteration = ($SpawnedPlots | Measure-Object).Count
                $SpawnedCountOverall = $SpawnedCountOverall + $SpawnedCountThisIteration

                Write-Host "PlotoManager @"(Get-Date)": Amount of spawned Plots in this iteration:" $SpawnedCountThisIteration
                Write-Host "PlotoManager @"(Get-Date)": Overall spawned Plots since start of script:" $SpawnedCountOverall
                Write-Host "________________________________________________________________________________________"
            }

        Start-Sleep ($IntervallToWait*60)
    }
    
    Until ($SpawnedCountOverall -ge $InputAmountToSpawn)
    Write-Host "We are done!" -ForegroundColor Green

    $VerbosePreference = $oldverbose

}

function Get-PlotoJobs
{
	Param(
    [switch]$PerfCounter,
    [switch]$Verbose
    )

 if($verbose) {

   $oldverbose = $VerbosePreference
   $VerbosePreference = "continue" }

$PlotterBaseLogPath = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\plotter\"
$logs = Get-ChildItem $PlotterBaseLogPath | Where-Object {$_.Name -notlike "*@Stat*"}
$pattern = @("OutDrive", "TempDrive", "Starting plotting progress into temporary dirs:", "ID", "F1 complete, time","Starting phase 1/4", "Computing table 1","Computing table 2", "Computing table 3","Computing table 4","Computing table 5","Computing table 6","Computing table 7", "Starting phase 2/4", "Time for phase 1","Backpropagating on table 7", "Backpropagating on table 6", "Backpropagating on table 5", "Backpropagating on table 4", "Backpropagating on table 3", "Backpropagating on table 2", "Starting phase 3/4", "Compressing tables 1 and 2", "Compressing tables 2 and 3", "Compressing tables 3 and 4", "Compressing tables 4 and 5", "Compressing tables 5 and 6", "Compressing tables 6 and 7", "Starting phase 4/4", "Writing C2 table", "Time for phase 4", "Renamed final file", "Total time", "Could not copy", "Time for phase 3", "Time for phase 2")


$collectionWithPlotJobsOut = New-Object System.Collections.ArrayList

foreach ($log in $logs)
    {        
        $status = get-content ($PlotterBaseLogPath+"\"+$log.name) | Select-String -Pattern $pattern
        $ErrorActionPreference = "SilentlyContinue"
        $CurrentStatus = $status[($status.count-1)]
  
        $CompletionTimeP1 = (($status -match "Time for phase 1").line.Split("=")[1]).TrimStart(" ")
        $CompletionTimeP2 = (($status -match "Time for phase 2").line.Split("=")[1]).TrimStart(" ")
        $CompletionTimeP3 = (($status -match "Time for phase 3").line.Split("=")[1]).TrimStart(" ")
        $CompletionTimeP4 = (($status -match "Time for phase 4").line.Split("=")[1]).TrimStart(" ")

        $plotId = ($status -match "ID").line.Split(" ")[1]

        switch -Wildcard ($CurrentStatus)
            {
                "Starting plotting progress into temporary dirs:*" {$StatusReturn = "Initializing"}
                "Starting phase 1/4*" {$StatusReturn = "1.0"}
                "Computing table 1" {$StatusReturn = "1.1"}
                "F1 complete, time*" {$StatusReturn = "1.2"}
                "Computing table 2" {$StatusReturn = "1.3"}
                "Computing table 3" {$StatusReturn = "1.4"}
                "Computing table 4" {$StatusReturn = "1.5"}
                "Computing table 5" {$StatusReturn = "1.6"}
                "Computing table 6" {$StatusReturn = "1.7"}
                "Computing table 7" {$StatusReturn = "1.8"}
                "Starting phase 2/4*" {$StatusReturn = "2.0"}
                "Backpropagating on table 7" {$StatusReturn = "2.1"}
                "Backpropagating on table 6" {$StatusReturn = "2.2"}
                "Backpropagating on table 5" {$StatusReturn = "2.3"}
                "Backpropagating on table 4" {$StatusReturn = "2.4"}
                "Backpropagating on table 3" {$StatusReturn = "2.5"}
                "Backpropagating on table 2" {$StatusReturn = "2.6"}
                "Starting phase 3/4*" {$StatusReturn = "3.0"}
                "Compressing tables 1 and 2" {$StatusReturn = "3.1"}
                "Compressing tables 2 and 3" {$StatusReturn = "3.2"}
                "Compressing tables 3 and 4" {$StatusReturn = "3.3"}
                "Compressing tables 4 and 5" {$StatusReturn = "3.4"}
                "Compressing tables 5 and 6" {$StatusReturn = "3.5"}
                "Compressing tables 6 and 7" {$StatusReturn = "3.6"}
                "Starting phase 4/4*" {$StatusReturn = "4.0"}
                "Writing C2 table*" {$StatusReturn = "4.1"}
                "Time for phase 4*" {$StatusReturn = "4.2"}
                "Renamed final file*" {$StatusReturn = "4.3"}
                "Could not copy*" {$StatusReturn = "ResumableError"}

                default {$StatusReturn = "Could not fetch Status"}
            }

            $Logstatfiles = Get-ChildItem $PlotterBaseLogPath | Where-Object {$_.Name -like "*@Stat*"}
            foreach ($logger in $Logstatfiles)
                {
                    $SearchStat = ($logger.name).split("@")[0]
                    $SearchChia = ($log.name).split(".")[0]

                    if ($SearchStat -eq $SearchChia)
                        {
                           $pattern2 = @("OutDrive", "TempDrive", "PID","PlotoSpawnerJobId", "StartTime", "ArgumentList", "T2Drive" , "Time for phase 1", "Time for phase 2", "Time for phase 3", "Time for phase 4" )
                           $loggerRead = Get-Content ($PlotterBaseLogPath+"\"+$logger.Name) | Select-String -Pattern $pattern2
                           $OutDrive = ($loggerRead -match "OutDrive").line.Split("=").split(";")[1]
                           $tempDrive = ($loggerRead -match "TempDrive").line.Split("=").split(";")[1]
                           $t2drive = ($loggerRead -match "T2Drive").line.Split("=").split(";")[1]
                           $chiaPid = ($loggerRead -match "PID").line.Split(" ")[1]
                           $PlotoSpawnerJobId = ($loggerRead -match "PlotoSpawnerJobId").line.Split(" ")[1]
                           $StartTimeSplitted = ($loggerRead -match "StartTime").line.Split(":")
                           $StartTime = ($StartTimeSplitted[1]+":" + $StartTimeSplitted[2]+":" + $StartTimeSplitted[3]).TrimStart(" ")
                           $ArgumentList = ($loggerRead -match "ArgumentList").line.TrimStart("ArgumentList: ")


                           if ($t2drive -eq "2")
                            {$t2drive = ""}

                           $StatLogPath = $logger.FullName
                                  
                           $PlotoIdToScramble = $plotId
                           #Scramble temp dir for .tmp files

                           $FileArrToCountSize = Get-ChildItem $TempDrive | Where-Object {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".tmp"} 
                           $SizeOnDisk = "{0:N2} GB" -f (($FileArrToCountSize | Measure-Object length -s).Sum /1GB)

                           $FileArrToCountSize = Get-ChildItem $OutDrive | Where-Object {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".plot"} 
                           $SizeOnOutDisk = "{0:N2} GB" -f (($FileArrToCountSize | Measure-Object length -s).Sum /1GB)

                           if ($PerfCounter)
                            {
                               if ($StatusReturn -ne "4.3" -or $StatusReturn -ne "Completed")
                                {
                                   Write-Verbose ("PlotoGetJobs @"+(Get-Date)+": Getting Perf counters. This may take a while...")
                                   $p = $((Get-Counter '\Process(*)\ID Process' -ErrorAction SilentlyContinue).CounterSamples | ForEach-Object {[regex]$a = "^.*\($([regex]::Escape($_.InstanceName))(.*)\).*$";[PSCustomObject]@{InstanceName=$_.InstanceName;PID=$_.CookedValue;InstanceId=$a.Matches($($_.Path)).groups[1].value}})
                                   $id = $chiaPID
                                   $p1 = $p | Where-Object {$_.PID -eq $id}
                                   $CpuCores = (Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors
                                   $Samples = (Get-Counter -Counter "\Process($($p1.InstanceName+$p1.InstanceId))\% Processor Time").CounterSamples
                                   $cpuout = $Samples | Select-Object `
                                   InstanceName,
                                   @{Name="CPU %";Expression={[Decimal]::Round(($_.CookedValue / $CpuCores), 2)}}
                                   $cpuUsage = $cpuout.'CPU %'
                                   $MemUsage = (Get-WMIObject WIN32_PROCESS | Where-Object {$_.processid -eq $chiapid} | Sort-Object -Property ws -Descending | Select-Object processname,processid, @{Name="Mem Usage(MB)";Expression={[math]::round($_.ws / 1mb)}}).'Mem Usage(MB)'
                                }
                            }
                        }
                }

            #split off "plots create" for output

            $ArgumentList = $ArgumentList.TrimStart("plots create ")

            #Set certian properties when is Complete
            if ($StatusReturn -eq "4.3")
                {
                    $TimeToComplete = ($status -match "Total time").line.Split("=").Split(" ")[4]
                    $TimeToCompleteCalcInh = ($TimeToComplete / 60) / 60
                    $EndDate = (Get-Date $StartTime).AddHours($TimeToCompleteCalcInh)

                    $StatusReturn =  "Completed"
                    $chiaPid = "None"

                }
            else
                {
                    #check if is aborted

                    $ChiaProc = Get-Process -Id $chiaPid

                    if ($ChiaProc -eq $null)
                        {
                            $StatusReturn = "Aborted"
                            $TimeToCompleteCalcInh = "None"
                            $chiaPid = "None"
                        }
                    else
                        {
                            $TimeToCompleteCalcInh = "Still in progress"
                        }
                }


            if ($StatusReturn -eq "ResumableError")
                {
                    $StatusReturn = "Error: Check Logs of job"
                }

            if ($PerfCounter)
                {
                    #Getting Plot Object Ready
                    $PlotJobOut = [PSCustomObject]@{
                    JobId = $PlotoSpawnerJobId
                    Status = $StatusReturn
                    StartTime = $StartTime
                    TempDrive = $tempDrive
                    T2Drive = $t2drive
                    OutDrive = $OutDrive
                    PID = $chiaPid
                    PlotSizeOnTempDisk = $SizeOnDisk
                    PlotSizeOnOutDisk = $SizeOnOutDisk
                    cpuUsage = $cpuUsage
                    memUsage = $MemUsage
                    ArgumentList = $ArgumentList
                    PlotId = $plotId
                    LogPath = $log.FullName
                    StatLogPath = $StatLogPath
                    CompletionTime = $TimeToCompleteCalcInh
                    CompletionTimeP1 = $CompletionTimeP1
                    CompletionTimeP2 = $CompletionTimeP2
                    CompletionTimeP3 = $CompletionTimeP3
                    CompletionTimeP4 = $CompletionTimeP4
                    }
                
                }

            else
                {
                    #Getting Plot Object Ready
                    $PlotJobOut = [PSCustomObject]@{
                    JobId = $PlotoSpawnerJobId
                    Status = $StatusReturn
                    StartTime = $StartTime
                    TempDrive = $tempDrive
                    T2Drive = $t2drive
                    OutDrive = $OutDrive
                    PID = $chiaPid
                    PlotSizeOnTempDisk = $SizeOnDisk
                    PlotSizeOnOutDisk = $SizeOnOutDisk
                    ArgumentList = $ArgumentList
                    PlotId = $plotId
                    LogPath = $log.FullName
                    StatLogPath = $StatLogPath
                    CompletionTime = $TimeToCompleteCalcInh
                    CompletionTimeP1 = $CompletionTimeP1
                    CompletionTimeP2 = $CompletionTimeP2
                    CompletionTimeP3 = $CompletionTimeP3
                    CompletionTimeP4 = $CompletionTimeP4
                    EndDate = $EndDate
                    }

                }
      


        if ($PerfCounter -and $StatusReturn -eq "Completed")
            {
                
            }
        else
            {
                $collectionWithPlotJobsOut.Add($PlotJobOut) | Out-Null
            }


        #Clear values from former iteration
        $StatusReturn = $null
        $t2drive = $null
        $tempDrive = $null
        $OutDrive = $null
        $TimeToCompleteCalcInh = $null
        $TimeToComplete = $null
        $CompletionTimeP1 = $null
        $CompletionTimeP2 = $null
        $CompletionTimeP3 = $null
        $CompletionTimeP4 = $null
    }


$ErrorActionPreference = "Continue"

$output = $collectionWithPlotJobsOut | Sort-Object Status

return $output

}

function Stop-PlotoJob
{
	Param(
		[parameter(Mandatory=$true)]
		$JobId
		)
        $ErrorActionPreference = "stop"

        $Job = Get-PlotoJobs | Where-Object {$_.JobId -eq $JobId}

        try 
            {
                Stop-Process -id $job.PID
                
            }

        catch
            {
                If ($_.Exception.Message -like "*Cannot bind parameter 'Id'*")
                    {
                        Write-Host "PlotoStopJob @"(Get-Date)": stopped chia.exe with PID:" $job.pid -ForegroundColor Green 
                    }
                else
                    {
                        Write-Host "PlotoStopJob @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Yellow
                    }
      
            }   


        $PlotoIdToScramble = $job.PlotId
        #Scramble temp dir for .tmp files

        $FileArrToDel = Get-ChildItem $job.TempDrive | Where-Object {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".tmp"} 

        if ($FileArrToDel)
            {
                Write-Host "PlotostopJob @"(Get-Date)": Found .tmp files for this job to be deleted."
                Write-Host "PlotostopJob @"(Get-Date)": Sleeping 4 seconds before trying to attempt to delete logs and tmp files..."
                Start-Sleep 4

                try 
                    {
                        $FileArrToDel | Remove-Item -Force
                        Write-Host "PlotostopJob @"(Get-Date)": Removed temp files on"$Job.TempDrive -ForegroundColor Green   
                    }

                catch
                    {
                        Write-Host "PlotostopJob @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red   
                    }               
            }     

        #Remove logs
        try
            {
                Remove-Item -Path $Job.LogPath
                Remove-Item -Path $Job.StatLogPath
                Write-Host "PlotostopJob @"(Get-Date)": Removed log files for this job." -ForegroundColor Green     
            }

        catch
            {
               Write-Host "PlotostopJob @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red 
            }
}

function Remove-AbortedPlotoJobs
{
    $JobsToAbort = Get-PlotoJobs | Where-Object {$_.Status -eq "Aborted"}
    Write-Host "PlotoRemoveAbortedJobs @"(Get-Date)": Found aborted Jobs to be deleted:"$JobsToAbort.JobId
    Write-Host "PlotoRemoveAbortedJobs @"(Get-Date)": Cleaning up..."
    $count = 0
    foreach ($job in $JobsToAbort)
        {
            Stop-PlotoJob -JobId $job.jobid
            $count++
        }
    Write-Host "PlotoRemoveAbortedJobs @"(Get-Date)": Removed Amount of aborted Jobs:"$count

}

function Get-PlotoPlots
{
	Param(
		[parameter(Mandatory=$true)]
		$OutDriveDenom
		)

#Scan for final Plot Files to Move
$OutDrivesToScan = Get-PlotoOutDrives -OutDriveDenom $OutDriveDenom

if ($OutDrivesToScan)
    {
        $collectionWithFinalPlots= New-Object System.Collections.ArrayList

        foreach ($OutDriveToScan in $OutDrivesToScan)
        {
            Write-Host "Iterating trough Drive: "$OutDriveToScan

            $ItemsInDrive = Get-ChildItem $OutDriveToScan.DriveLetter
            Write-Host "Checking if any item in that drive contains .PLOT as file ending..."

            If ($ItemsInDrive)

            {
                foreach ($item in $ItemsInDrive)
                {
                    If ($item.Extension -eq ".PLOT")
                        {
                            Write-Host -ForegroundColor Green "Found a Final plot: "$item
                    
                            $FilePath = $item.Directory.Name + $item.name
                            $Size = [math]::Round($item.Length  / 1073741824, 2)

                            $PlotToMove = [PSCustomObject]@{
                            FilePath     =  $FilePath
                            Name = $item.Name
                            Size = $Size
                            }

                            $collectionWithFinalPlots.Add($PlotToMove) | Out-Null
                        }
                    else
                        {
                            Write-Host "This is no plot: "$item -ForegroundColor Yellow
                        }
                }
            }

            else
                {
                    Write-Host "This drive does not contain any files or folders." -ForegroundColor yellow
                }

        }

    }
else
    {
        Write-Host "No drives to Scan. Make sure you set your denominator correctly. Dont specify the drive, speficy the denom across all drives!" -ForegroundColor Red
    }
    
    Write-Host "--------------------------------------------------------------------------------------------------"

    return $collectionWithFinalPlots
}

function Move-PlotoPlots
{
	Param(
		[parameter(Mandatory=$true)]
		$DestinationDrive,
		[parameter(Mandatory=$true)]
		$OutDriveDenom,
		[parameter(Mandatory=$true)]
        [ValidateSet("BITS", "Move-Item", IgnoreCase = $true)]
		$TransferMethod
		)

$PlotsToMove = Get-PlotoPlots -OutDriveDenom $OutDriveDenom

if ($PlotsToMove)
    {
        Write-Host "PlotoMover @"(Get-Date)": There are Plots found to be moved: "
        foreach ($plot in $PlotsToMove)
            {
                Write-Host $plot.filepath -ForegroundColor Green
            }
        Write-Host "PlotoMover @"(Get-Date)": A total of "$PlotsToMove.Count" plot have been found."
                          

        foreach ($plot in $PlotsToMove)
        {
            If ($TransferMethod -eq "BITS")
                {
                    #Check if BITS Transfer already in progress:
                    $HasBITSinProgress = Get-BitsTransfer | Where-Object {$_.FileList.RemoteName -eq $plot.Filepath} 

                    if ($HasBITSinProgress)
                        {
                            Write-Host "PlotoMover @"(Get-Date)": WARN:" $plot.FilePath "has already a BITS transfer in progress"
                        }

                    else
                        {
                             try 
                                {
                                    Write-Host "PlotoMover @"(Get-Date)": Moving plot: "$plot.FilePath "to" $DestinationDrive "using BITS"
                                    $source = $plot.FilePath
                                    Start-BitsTransfer -Source $source -Destination $DestinationDrive -Description "Moving Plot" -DisplayName "Moving Plot"
                            
                                    while ((Get-BitsTransfer | Where-Object { $_.JobState -eq "Transferring" }).Count -gt 0) {     
                                        $totalbytes=0;    
                                        $bytestransferred=0; 
                                        $timeTaken = 0;    
                                        foreach ($job in (Get-BitsTransfer | Where-Object { $_.JobState -eq "Transferring" } | Sort-Object CreationTime)) {         
                                            $totalbytes += $job.BytesTotal;         
                                            $bytestransferred += $job.bytestransferred     
                                            if ($timeTaken -eq 0) { 
                                                #Get the time of the oldest transfer aka the one that started first
                                                $timeTaken = ((Get-Date) - $job.CreationTime).TotalMinutes 
                                            }
                                        }    
                                        #TimeRemaining = (TotalFileSize - BytesDownloaded) * TimeElapsed/BytesDownloaded
                                        if ($totalbytes -gt 0) {        
                                            [int]$timeLeft = ($totalBytes - $bytestransferred) * ($timeTaken / $bytestransferred)
                                            [int]$pctComplete = $(($bytestransferred*100)/$totalbytes);     
                                            Write-Progress -Status "Transferring $bytestransferred of $totalbytes ($pctComplete%). $timeLeft minutes remaining." -Activity "Dowloading files" -PercentComplete $pctComplete  
                                        }
                                    }
                                }

                            catch
                                {
                                    Write-Host "PlotoMover @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
                                }        
                        }
                    }

            else
                {
                    #Check local destination drive space
                    $DestSpaceCheck = get-WmiObject win32_logicaldisk | Where-Object {$_.DeviceID -like "*$DestinationDrive*"}
                    $FreeSpaceDestDrive = [math]::Round($destspaceCheck.FreeSpace  / 1073741824, 2)

                    if ($FreeSpaceDestDrive -gt 107)
                        {
                            Write-Host "PlotoMover @"(Get-Date)": Moving plot: "$plot.FilePath "to" $DestinationDrive "using Move-Item."

                            try 
                                {
                                    Move-Item -Path $plot.FilePath -Destination $DestinationDrive
                                }
                            catch
                                {
                                    Write-Host "PlotoMover @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
                                }
                            
                        }
                    else
                        {
                            Write-Host "PlotoMover @"(Get-Date)": Local Destination Drive does not have enough disk space. Cant move." -ForegroundColor Red
                        }
                }
        }
    }

else
    {
        Write-Host "PlotoMover @"(Get-Date)": No Final plots found." 
    }

}

function Start-PlotoMove
{
	Param(
		[parameter(Mandatory=$true)]
		$DestinationDrive,
		[parameter(Mandatory=$true)]
		$OutDriveDenom,
        [ValidateSet("BITS", "Move-Item", IgnoreCase = $true)]
        $TransferMethod
		)

    $count = 0
    $endlessCount = 1000

    Do
        {
            Move-PlotoPlots -DestinationDrive $DestinationDrive -OutDriveDenom $OutDriveDenom -TransferMethod $TransferMethod
            Start-Sleep 900
        }

    Until ($count -eq $endlessCount)
}


function Get-PlotoFarmLog
{
	Param(
		[parameter(Mandatory=$true)]
        [ValidateSet("EligiblePlots", "Error", "Warning", IgnoreCase = $true)]
		$LogLevel
		)

        switch -Wildcard ($LogLevel)
            {
                "EligiblePlots" {$pattern = @("plots were eligible for farming")}
                "Error" {$pattern = @("ERROR")}
                "Warning" {$pattern = @("WARN")}

                default {$pattern = "Error"}
            }

$PlotterBaseLogPath = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\log\"
$LogPath= $PlotterBaseLogPath+"debug.log"

$output = Get-content ($LogPath) | Select-String -Pattern $pattern

return $output
}


function Invoke-PlotoFyStatusReport
{
    try 
       {
            $PathToAlarmConfig = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"
            $config = Get-Content -raw -Path $PathToAlarmConfig | ConvertFrom-Json -ErrorAction Stop
            Write-Verbose "Loaded Alarmconnfig successfully"
        }
    catch
        {
            Throw $_.Exception.Message
        } 

    $ReportPeriod = $config.PlotoFyAlerts.PeriodOfReportInHours

    #get completed jobs in last X minutes
    $PeriodToCheck = (Get-Date).AddHours(-$ReportPeriod)

    #Get only jobs that were affected the last 2 days
    $collectionWithJobsToReport= New-Object System.Collections.ArrayList

    $Jobs = Get-PlotoJobs | Where-Object {$_.Status -eq "Completed"}

    foreach ($job in $jobs) 
        {
            $CompletionTimeConverted = (Get-Date $job.EndDate)
            if ($CompletionTimeConverted -gt $PeriodToCheck) 
                {
                    Write-Host "Thats a job do check: "$job.jobid

                    $JobToReport = [PSCustomObject]@{
                        JobId     =  $job.jobid
                        StartTime = $job.Starttime
                        PlotId = $job.PlotId
                        ArgumentList = $job.ArgumentList
                        TempDrive = $job.TempDrive
                        OutDrive = $job.OutDrive
                        CompletionTime = $job.CompletionTime
                        CompletionTimeP1 = $job.CompletionTimeP1
                        CompletionTimeP2 = $job.CompletionTimeP2
                        CompletionTimeP3 = $job.CompletionTimeP3
                        CompletionTimeP4 = $job.CompletionTimeP4
                        EndDate = (Get-Date $job.StartTime).AddHours($job.CompletionTime)
                        }

                        $collectionWithJobsToReport.Add($JobToReport) | Out-Null
                }
        }

    $jops = Get-PlotoJobs | Where-Object {$_.Status -ne "Completed" -and $_.Status -ne "Aborted"}
    $jip = ($jops | Measure-Object).Count
    
    if ($collectionWithJobsToReport -ne 0)
        {
            
            try 
            {
                $SummaryHeader = "Plotting Summary Completed Jobs last "+$ReportPeriod+" hours" 
                $SummaryVal = "PlotoFy calling in, as you wished. We plotted "+$collectionWithJobsToReport.Count+" jobs."
                #Create embed builder object via the [DiscordEmbed] class
                $embedBuilder = [DiscordEmbed]::New(
                                    $SummaryHeader,
                                    $SummaryVal
                                )
                $counter = 0
                foreach ($j in $collectionWithJobsToReport)
                    {
                        $counter++
                        $ArgId = "ArgumentList Job "+$counter
                        $JobDetailsArgListMsg = $j.ArgumentList.TrimStart("plots create ")
                        $embedBuilder.AddField(
                            [DiscordField]::New(
                                $ArgId,
                                $JobDetailsArgListMsg, 
                                $true
                            )
                        )
                        $StaId = "StartTime Job "+$counter
                        $JobDetailsStartTimeMsg = $j.StartTime
                        $embedBuilder.AddField(
                            [DiscordField]::New(
                                $StaId,
                                $JobDetailsStartTimeMsg, 
                                $true
                            )
                        )

                        $EndId = "EndDate Job "+$counter
                        $JobDetailsEndTimeMsg = $j.EndDate
                        $embedBuilder.AddField(
                            [DiscordField]::New(
                                $EndId,
                                $JobDetailsEndTimeMsg, 
                                $true
                            )
                        )                
                    }

                $AvgDur = ($collectionWithJobsToReport | Measure-Object -Property CompletionTime -Average).Average
                $AvgDur = [math]::Floor($AvgDur)
                $JobsAvgDurMsg = "It took "+$AvgDur+" (floored value) hours to complete a plot on average in that period."
                $embedBuilder.AddField(
                    [DiscordField]::New(
                        'Average Duration Total',
                        $JobsAvgDurMsg, 
                        $true
                    )
                )
                
                #Add purple color
                $embedBuilder.WithColor(
                    [DiscordColor]::New(
                        'Purple'
                    )
                )

                $plotname = $config.PlotterName
                $footie = "Ploto: "+$plotname

                #Add a footer
                $embedBuilder.AddFooter(
                    [DiscordFooter]::New(
                        $footie
                    )
                )

                $WebHookURL = $config.PlotoFyAlerts.DiscordWebHookURL

                Invoke-PsDsHook -CreateConfig $WebHookURL 
                Invoke-PSDsHook $embedBuilder     
            }
        catch
            {
                Write-Host "PlotoSpawner @"(Get-Date)": ERROR! Could not send Discord API Call or received Bad request" -ForegroundColor Red
                Write-Host "PlotoMover @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
            }
        }
    if ($jip -ne 0)
        {
            try 
            {
                $SummaryHeader = "Plotting Summary for Jobs in Progress" 
                $SummaryVal = "PlotoFy calling in, as you wished. We are currently plotting a total of "+$jip+" jobs."
                 #Create embed builder object via the [DiscordEmbed] class
                 $embedBuilder = [DiscordEmbed]::New(
                    $SummaryHeader,
                    $SummaryVal
                )
                $countji= 0
                foreach ($ji in $jops)
                {   
                    $countji++
                    $ArgId = "ArgumentList Job "+$countji
                    $JobDetailsArgListMsg = $ji.ArgumentList.TrimStart("plots create ")
                    $embedBuilder.AddField(
                        [DiscordField]::New(
                            $ArgId,
                            $JobDetailsArgListMsg, 
                            $true
                        )
                    )
                    $StaId = "StartTime Job "+$countji
                    $JobDetailsStartTimeMsg = $ji.StartTime
                    $embedBuilder.AddField(
                        [DiscordField]::New(
                            $StaId,
                            $JobDetailsStartTimeMsg, 
                            $true
                        )
                    )

                    $EndId = "Phase Job"+$countji
                    $JobDetailsStatMsg = $ji.Status
                    $embedBuilder.AddField(
                        [DiscordField]::New(
                            $EndId,
                            $JobDetailsStatMsg, 
                            $true
                        )
                    )                
                }

                $embedBuilder.AddField(
                    [DiscordField]::New(
                        'Total Jobs in progress',
                        $jip, 
                        $true
                    )
                )

                #Add purple color
                $embedBuilder.WithColor(
                    [DiscordColor]::New(
                        'Green'
                    )
                )

                $plotname = $config.PlotterName
                $footie = "Ploto: "+$plotname

                #Add a footer
                $embedBuilder.AddFooter(
                    [DiscordFooter]::New(
                        $footie
                    )
                )

                $WebHookURL = $config.PlotoFyAlerts.DiscordWebHookURL

                Invoke-PsDsHook -CreateConfig $WebHookURL 
                Invoke-PSDsHook $embedBuilder     
            }
        catch
            {
                Write-Host "PlotoSpawner @"(Get-Date)": ERROR! Could not send Discord API Call or received Bad request" -ForegroundColor Red
                Write-Host "PlotoMover @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
            }

        }
    else 
        {
            try 
            {
                $SummaryHeader = "Plotting Summary for Jobs in Progress. Nothing is going on." 
                $SummaryVal = "PlotoFy calling in, as you wished. We are currently NOT plotting any job!"
                 #Create embed builder object via the [DiscordEmbed] class
                 $embedBuilder = [DiscordEmbed]::New(
                    $SummaryHeader,
                    $SummaryVal
                )


                #Add purple color
                $embedBuilder.WithColor(
                    [DiscordColor]::New(
                        'red'
                    )
                )

                $plotname = $config.PlotterName
                $footie = "Ploto: "+$plotname

                #Add a footer
                $embedBuilder.AddFooter(
                    [DiscordFooter]::New(
                        $footie
                    )
                )

                $WebHookURL = $config.PlotoFyAlerts.DiscordWebHookURL

                Invoke-PsDsHook -CreateConfig $WebHookURL 
                Invoke-PSDsHook $embedBuilder     
            }
        catch
            {
                Write-Host "PlotoSpawner @"(Get-Date)": ERROR! Could not send Discord API Call or received Bad request" -ForegroundColor Red
                Write-Host "PlotoMover @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
            }
        }
    
    else
        {
            if ($jip -ne 0)
                {
                    $SummaryHeader = "Plotting Summary for Jobs in Progress for "+$ReportPeriod+" hours" 
                    $SummaryVal = "PlotoFy calling in, as you wished. Unfortunately, we did not complete any jobs in the last "+$config.PlotoFyAlerts.PeriodOfReportInHours+"hour. However, we do have Jobs in progress."
                    $color = "green"
                }
            else 
                {
                    $SummaryHeader = "Summary Report for "+$ReportPeriod+" hours. Nothing going on"
                    $SummaryVal = "PlotoFy calling in, as you wished. Unfortunately, we did not complete any jobs in the last "+$config.PlotoFyAlerts.PeriodOfReportInHours+"hour. And there are no jobs in Progress. Is Ploto running at all?"
                    $color = "red"
                }
            
            try 
            {                
                #Create embed builder object via the [DiscordEmbed] class
                $embedBuilder = [DiscordEmbed]::New(
                                    $SummaryHeader,
                                    $SummaryVal
                                )
                $countjie = 0
                foreach ($ji in $jops)
                {
                    $countjie++
                    $ArgId = "ArgumentList Job "+$countjie
                    $JobDetailsArgListMsg = $ji.ArgumentList.TrimStart("plots create ")
                    $embedBuilder.AddField(
                        [DiscordField]::New(
                            $ArgId,
                            $JobDetailsArgListMsg, 
                            $true
                        )
                    )
                    $StaId = "StartTime Job "+$countjie
                    $JobDetailsStartTimeMsg = $ji.StartTime
                    $embedBuilder.AddField(
                        [DiscordField]::New(
                            $StaId,
                            $JobDetailsStartTimeMsg, 
                            $true
                        )
                    )

                    $EndId = "Phase"+$countjie
                    $JobDetailsStatMsg = $ji.Status
                    $embedBuilder.AddField(
                        [DiscordField]::New(
                            $EndId,
                            $JobDetailsStatMsg, 
                            $true
                        )
                    )                
                }

                $embedBuilder.AddField(
                    [DiscordField]::New(
                        'Total Jobs in progress',
                        $jip, 
                        $true
                    )
                )

                #Add purple color
                $embedBuilder.WithColor(
                    [DiscordColor]::New(
                        $color
                    )
                )

                $plotname = $config.PlotterName
                $footie = "Ploto: "+$plotname

                #Add a footer
                $embedBuilder.AddFooter(
                    [DiscordFooter]::New(
                        $footie
                    )
                )

                $WebHookURL = $config.PlotoFyAlerts.DiscordWebHookURL

                Invoke-PsDsHook -CreateConfig $WebHookURL 
                Invoke-PSDsHook $embedBuilder     
            }
            catch
            {
                Write-Host "PlotoSpawner @"(Get-Date)": ERROR! Could not send Discord API Call or received Bad request" -ForegroundColor Red
                Write-Host "PlotoMover @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
            }


        }

    
    return $collectionWithJobsToReport
}

function Request-PlotoFyStatusReport
{
    $count = 0
    for ($count -lt 1000000)
        {
            try 
                {
                    $PathToAlarmConfig = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"
                    $config = Get-Content -raw -Path $PathToAlarmConfig | ConvertFrom-Json -ErrorAction Stop
                    Write-Verbose "Loaded Alarmconfig successfully"
                }
            catch
                {
                    Throw $_.Exception.Message
                } 
        Invoke-PlotoFyStatusReport
        
        $sleep = $config.PlotoFyAlerts.PeriodOfReportInHours
        Write-Host "Sleep defined in config in h:"$sleep
        $Sleep2 = ($sleep -as [decimal])*(60*60)
        Write-Host "Sleeping for:"$Sleep2 "seconds..."
        Start-Sleep $sleep2
        $count++
        }
}

Function Start-PlotoFy
{

    Start-Job -ScriptBlock {
    try 
        {
             $PathToAlarmConfig = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"
             $config = Get-Content -raw -Path $PathToAlarmConfig | ConvertFrom-Json -ErrorAction Stop
             Write-Verbose "Loaded Alarmcoinfig successfully"
         }
     catch
         {
             Throw $_.Exception.Message
         } 
 
    $PathToPloto = $config.PlotoFyAlerts.PathToPloto 
    Unblock-File $PathToPloto
    Import-Module $PathToPloto -Force
    Request-PlotoFyStatusReport -ErrorAction stop
    } -ArgumentList $PathToPloto, $PathToPloto -Name PlotoFy

}


#Helpers here. Would have loved to correctly used the module as a dependency. Just doesnt work when using with classes. Got to use the using module statement, which needs to be at the very beginning of a module or script.
#I just load locally, this means we cannot use in the functions we call. The classes and functions wont be available within functions, thats why I baked them in directly. Massive credits to Mike Roberts! -> https://github.com/gngrninja



class DiscordImage {    
    [string]$url      = [string]::Empty
    [string]$proxyUrl = [string]::Empty
    [int]$width       = $null
    [int]$height      = $null

    DiscordImage([string]$url)
    {
        if ([string]::IsNullOrEmpty($url))
        {
            Write-Error "Please provide a url!"
        }
        else
        {            
            $this.url = $url
        }
    }

    DiscordImage(   
        [string]$url,         
        [string]$proxyUrl
    )
    {
        if ([string]::IsNullOrEmpty($url) -and [string]::IsNullOrEmpty($proxyUrl))
        {
            Write-Error "Please provide: a url and proxyurl"
        }
        else
        {
            $this.url      = $url
            $this.proxyUrl = $proxyUrl
        }
    }

    DiscordImage(
        [string]$url,         
        [string]$proxyUrl,
        [int]$width, 
        [int]$height
    )
    {
        if (
            [string]::IsNullOrEmpty($url)      -and 
            [string]::IsNullOrEmpty($proxyUrl) -and
            !$width -and !($height)
        )
        {
            Write-Error "Please provide: a url and proxyurl"
        }
        else
        {
            $this.url      = $url
            $this.proxyUrl = $proxyUrl        
            $this.height   = $height
            $this.width    = $width
        }
    }
}

class DiscordThumbnail {
    [string]$url = [string]::Empty
    [int]$width  = $null
    [int]$height = $null

    DiscordThumbnail([string]$url)
    {
        if ([string]::IsNullOrEmpty($url))
        {
            Write-Error "Please provide a url!"
        }
        else
        {            
            $this.url = $url
        }
    }

    DiscordThumbnail(
            [int]$width, 
            [int]$height, 
            [string]$url
    )
    {
        if ([string]::IsNullOrEmpty($url))
        {
            Write-Error "Please provide a url!"
        }
        else
        {
            $this.url    = $url
            $this.height = $height
            $this.width  = $width
        }
    }
}

class DiscordAuthor {
    [string]$name           = [string]::Empty
    [string]$url            = [string]::Empty
    [string]$icon_url       = [string]::Empty
    [string]$proxy_icon_url = [string]::Empty

    DiscordAuthor([string]$name)
    {
        if ([string]::IsNullOrEmpty($name))
        {
            Write-Error "Please provide a name!"
        }
        else
        {            
            $this.name = $name
        }
    }

    DiscordAuthor(
        [string]$name, 
        [string]$icon_url
    )
    {
        if ([string]::IsNullOrEmpty($name))
        {
            Write-Error "Please provide a name and icon url"
        }
        else
        {
            $this.name       = $name
            $this.'icon_url' = $icon_url
        }
    }
}

class DiscordColor {
    [int]$DecimalColor = $null
    [string]$HexColor  = [string]::Empty

    DiscordColor()
    {
        $embedColor = 8311585
        $this.HexColor     = "0x$([Convert]::ToString($embedColor, 16).ToUpper())"
        $this.DecimalColor = $embedColor
    }

    DiscordColor([int]$hex)
    {
        $this.DecimalColor = $hex
        $this.HexColor     = "0x$([Convert]::ToString($hex, 16).ToUpper())"
    }

    DiscordColor([string]$color)
    {

        [int]$embedColor = $null

        try {

            $embedColor = $color

        }
        catch {
            switch ($Color) {

                'blue' {

                    $embedColor = 4886754
                }

                'red' {

                    $embedColor = 13632027

                }

                'orange' {

                    $embedColor = 16098851

                }

                'yellow' {

                    $embedColor = 16312092

                }

                'brown' {

                    $embedColor = 9131818

                }

                'lightGreen' {

                    $embedColor = 8311585

                }

                'green' {

                    $embedColor = 4289797

                }

                'pink' {

                    $embedColor = 12390624

                }

                'purple' {

                    $embedColor = 9442302

                }

                'black' {

                    $embedColor = 1
                }

                'white' {

                    $embedColor = 16777215

                }

                'gray' {

                    $embedColor = 10197915

                }

                default {

                    $embedColor = 1

                }
            }
        }

        $this.HexColor     = "0x$([Convert]::ToString($embedColor, 16).ToUpper())"
        $this.DecimalColor = $embedColor

    }

    DiscordColor(
        [int]$r, 
        [int]$g, 
        [int]$b
    )
    {
        $this.DecimalColor = $this.ConvertFromRgb($r, $g, $b)
    }

    [string]ConvertFromHex([string]$hex)
    {
        [int]$decimalValue = [Convert]::ToDecimal($hex)

        return $decimalValue
    }

    [string]ConvertFromRgb(
        [int]$r, 
        [int]$g, 
        [int]$b
    )
    {
        $hexR = [Convert]::ToString($r, 16).ToUpper()
        if ($hexR.Length -eq 1)
        {
            $hexR = "0$hexR"
        }

        $hexG = [Convert]::ToString($g, 16).ToUpper()
        if ($hexG.Length -eq 1)
        {
            $hexG = "0$hexG"
        }

        $hexB = [Convert]::ToString($b, 16).ToUpper()
        if ($hexB.Length -eq 1)
        {
            $hexB = "0$hexB"
        }

        [string]$hexValue     = "0x$hexR$hexG$hexB"
        $this.HexColor        = $HexValue
        [string]$decimalValue = $this.ConvertFromHex([int]$hexValue)

        return $decimalValue
    }

    [string]ToString()
    {
        return $this.DecimalColor
    }
}

class DiscordEmbed {
    [string]$title                        = [string]::Empty
    [string]$description                  = [string]::Empty
    [System.Collections.ArrayList]$fields = @()
    [string]$color                        = [DiscordColor]::New().ToString()   
    $thumbnail                            = [string]::Empty
    $image                                = [string]::Empty
    $author                               = [string]::Empty
    $footer                               = [string]::Empty
    $url                                  = [string]::Empty

    DiscordEmbed()
    {
        Write-Error "Please provide a title and description (and optionally, a color)!"
    }

    DiscordEmbed(
        [string]$embedTitle, 
        [string]$embedDescription
    )
    {
        $this.title       = $embedTitle
        $this.description = $embedDescription
    }

    DiscordEmbed(
        [string]      $embedTitle, 
        [string]      $embedDescription, 
        [DiscordColor]$embedColor
    )
    {
        $this.title       = $embedTitle
        $this.description = $embedDescription
        $this.color       = $embedColor.ToString()
    }

    [void]AddField($field) 
    {
        if ($field.PsObject.TypeNames[0] -eq 'DiscordField')
        {
            Write-Verbose "Adding field to field array!"
            $this.Fields.Add($field) | Out-Null
        } 
        else
        {
            Write-Error "Did not receive a [DiscordField] object!"
        }
    }

    [void]AddThumbnail($thumbNail)
    {
        if ($thumbNail.PsObject.TypeNames[0] -eq 'DiscordThumbnail')
        {
            $this.thumbnail = $thumbNail
        } 
        else 
        {
            Write-Error "Did not receive a [DiscordThumbnail] object!"
        }
    }

    [void]AddImage($image)
    {
        if ($image.PsObject.TypeNames[0] -eq 'DiscordImage')
        {
            $this.image = $image
        } 
        else 
        {
            Write-Error "Did not receive a [DiscordImage] object!"
        }
    }

    [void]AddAuthor($author)
    {
        if ($author.PsObject.TypeNames[0] -eq 'DiscordAuthor')
        {
            $this.author = $author
        } 
        else 
        {
            Write-Error "Did not receive a [DiscordAuthor] object!"
        }
    }

    [void]AddFooter($footer)
    {
        if ($footer.PsObject.TypeNames[0] -eq 'DiscordFooter')
        {
            $this.footer = $footer
        } 
        else 
        {
            Write-Error "Did not receive a [DiscordFooter] object!"
        }
    }

    [void]WithUrl($url)
    {
        if (![string]::IsNullOrEmpty($url))
        {
            $this.url = $url
        } 
        else 
        {
            Write-Error "Please provide a url!"
        }
    }

    [void]WithColor([DiscordColor]$color)
    {
        $this.color = $color
    }
    
    [System.Collections.ArrayList] ListFields()
    {
        return $this.Fields
    }
}

class DiscordField {    
    [string]$name
    [string]$value
    [bool]$inline = $false

    DiscordField(
        [string]$name, 
        [string]$value
    )
    {
        $this.name  = $name
        $this.value = $value
    }

    DiscordField(
        [string]$name, 
        [string]$value, 
        [bool]$inline
    )
    {
        $this.name   = $name
        $this.value  = $value
        $this.inline = $inline
    }
}

class DiscordFooter {
    [string]$text           = [string]::Empty
    [string]$icon_url       = [string]::Empty
    [string]$proxy_icon_url = [string]::Empty

    DiscordFooter([string]$text)
    {
        if ([string]::IsNullOrEmpty($text))
        {
            Write-Error "Please provide some footer text!"
        }
        else
        {            
            $this.text = $text
        }
    }

    DiscordFooter(
        [string]$text, 
        [string]$icon_url
    )
    {
        if ([string]::IsNullOrEmpty($text))
        {
            Write-Error "Please provide some text and an icon url"
        }
        else
        {
            $this.text       = $text
            $this.'icon_url' = $icon_url
        }
    }
}

class DiscordConfig {
    [string]$HookUrl = [string]::Empty

    DiscordConfig([string]$configPath)
    {               
        $this.ImportConfig($configPath)    
    }

    DiscordConfig(
        [string]$url, 
        [string]$path
    )
    {
        $this.HookUrl      = $url      
        $this.ExportConfig($path)
    }

    [void]ExportConfig([string]$path)
    {
        Write-Verbose "Exporting configuration information to -> [$path]"

        $folderPath = Split-Path -Path $path

        if (!(Test-Path -Path $folderPath))
        {
            Write-Verbose "Creating folder -> [$folderPath]"
            New-Item -ItemType Directory -Path $folderPath            
        }

        $this | ConvertTo-Json | Out-File -FilePath $path
    }

    [void]ImportConfig([string]$configPath)
    {    
        Write-Verbose "Importing configuration from -> [$configPath]"

        $configSettings = Get-Content -Path $configPath -ErrorAction stop | ConvertFrom-Json

        $this.HookUrl = $configSettings.HookUrl 
    }
}

$userDir = $env:USERPROFILE
$script:separator = [IO.Path]::DirectorySeparatorChar
$script:defaultPsDsDir = (Join-Path -Path $userDir -ChildPath '.psdshook')
$script:configDir      = "$($defaultPsDsDir)$($separator)configs"

function Invoke-PSDsHook {
    <#
    .SYNOPSIS
    Invoke-PSDsHook
    Use PowerShell classes to make using Discord Webhooks easy and extensible

    .DESCRIPTION
    This function allows you to use Discord Webhooks with embeds, files, and various configuration settings

    .PARAMETER CreateConfig
    If specified, will create a configuration file containing the webhook URL as the argument.
    You can use the ConfigName parameter to create another configuration separate from the default.

    .PARAMETER WebhookUrl   
    If used with an embed or file, this URL will be used in the webhook call.

    .PARAMETER ConfigName
    Specified a name for the configuration file. 
    Can be used when creating a configuration file, as well as when passing embeds/files.

    .PARAMETER ListConfigs
    Lists configuration files

    .PARAMETER EmbedObject
    Accepts an array of [EmbedObject]'s to pass in the webhook call.

    .EXAMPLE
    (Create a configuration file)
    Configuration files are stored in a sub directory of your user's home directory named .psdshook/configs

    Invoke-PsDsHook -CreateConfig "www.hook.com/hook"
    .EXAMPLE
    (Create a configuration file with a non-standard name)
    Configuration files are stored in a sub directory of your user's home directory named .psdshook/configs

    Invoke-PsDsHook -CreateConfig "www.hook.com/hook2" -ConfigName 'config2'

    .EXAMPLE
    (Send an embed with the default config)

    using module PSDsHook

    If the module is not in one of the folders listed in ($env:PSModulePath -split "$([IO.Path]::PathSeparator)")
    You must specify the full path to the psm1 file in the above using statement
    Example: using module 'C:\users\thegn\repos\PsDsHook\out\PSDsHook\0.0.1\PSDsHook.psm1'

    Create embed builder object via the [DiscordEmbed] class
    $embedBuilder = [DiscordEmbed]::New(
                        'title',
                        'description'
                    )

    Add blue color
    $embedBuilder.WithColor(
        [DiscordColor]::New(
                'blue'
        )
    )
    
    Finally, call the function that will send the embed array to the webhook url via the default configuraiton file
    Invoke-PSDsHook $embedBuilder -Verbose

    .EXAMPLE
    (Send an webhook with just text)

    Invoke-PSDsHook -HookText 'this is the webhook message' -Verbose
    #>    
    [cmdletbinding()]
    param(
        [Parameter(
            ParameterSetName = 'createDsConfig'
        )]
        [string]
        $CreateConfig,

        [Parameter(
        )]
        [string]
        $WebhookUrl,

        [Parameter(
            Mandatory,
            ParameterSetName = 'file'
        )]
        [string]
        $FilePath,

        [Parameter(

        )]
        [string]
        $ConfigName = 'config',

        [Parameter(
            ParameterSetName = 'configList'
        )]
        [switch]
        $ListConfigs,

        [Parameter(
            ParameterSetName = 'embed',
            Position = 0
        )]
        $EmbedObject,

        [Parameter(
            ParameterSetName = 'simple'
        )]
        [string]
        $HookText
    )

    begin {            

        #Create full path to the configuration file
        $configPath = "$($configDir)$($separator)$($ConfigName).json"
                    
        #Ensure we can access the path, and error out if we cannot
        if (!(Test-Path -Path $configPath -ErrorAction SilentlyContinue) -and !$CreateConfig -and !$WebhookUrl) {

            throw "Unable to access [$configPath]. Please provide a valid configuration name. Use -ListConfigs to list configurations, or -CreateConfig to create one."

        } elseif (!$CreateConfig -and $WebhookUrl) {

            $hookUrl = $WebhookUrl

            Write-Verbose "Manual mode enabled..."

        } elseif ((!$CreateConfig -and !$WebhookUrl) -and $configPath) {

            #Get configuration information from the file specified                 
            $config = [DiscordConfig]::New($configPath)                
            $hookUrl = $config.HookUrl             

        }        
    }

    process {
            
        switch ($PSCmdlet.ParameterSetName) {

            'embed' {

                $payload = Invoke-PayloadBuilder -PayloadObject $EmbedObject

                Write-Verbose "Sending:"
                Write-Verbose ""
                Write-Verbose ($payload | ConvertTo-Json -Depth 4)

                try {

                    Invoke-RestMethod -Uri $hookUrl -Body ($payload | ConvertTo-Json -Depth 4) -ContentType 'Application/Json' -Method Post

                }
                catch {

                    $errorMessage = $_.Exception.Message
                    throw "Error executing Discord Webhook -> [$errorMessage]!"

                }
            }

            'file' {

                if ($PSVersionTable.PSVersion.Major -lt 6) {

                    throw "Support for sending files is not yet available in PowerShell 5.x"
                    
                } else {

                    $fileInfo = Invoke-PayloadBuilder -PayloadObject $FilePath
                    $payload  = $fileInfo.Content
    
                    Write-Verbose "Sending:"
                    Write-Verbose ""
                    Write-Verbose ($payload | Out-String)
    
                    #If it is a file, we don't want to include the ContentType parameter as it is included in the body
                    try {
    
                        Invoke-RestMethod -Uri $hookUrl -Body $payload -Method Post
    
                    }
                    catch {
    
                        $errorMessage = $_.Exception.Message
                        throw "Error executing Discord Webhook -> [$errorMessage]!"
    
                    }
                    finally {
    
                        $fileInfo.Stream.Dispose()
                        
                    }
                } 
            }

            'simple' {

                $payload = Invoke-PayloadBuilder -PayloadObject $HookText

                Write-Verbose "Sending:"
                Write-Verbose ""
                Write-Verbose ($payload | ConvertTo-Json -Depth 4)

                try {
                    
                    Invoke-RestMethod -Uri $hookUrl -Body ($payload | ConvertTo-Json -Depth 4) -ContentType 'Application/Json' -Method Post

                }
                catch {

                    $errorMessage = $_.Exception.Message
                    throw "Error executing Discord Webhook -> [$errorMessage]!"

                }
            }

            'createDsConfig' {
                
                [DiscordConfig]::New($CreateConfig, $configPath)

            }

            'configList' {

                $configs = (Get-ChildItem -Path (Split-Path $configPath) | Where-Object {$PSitem.Extension -eq '.json'} | Select-Object -ExpandProperty Name)
                if ($configs) {

                    Write-Host "Configuration files in [$configDir]:"
                    return $configs

                } else {

                    Write-Host "No configuration files found in [$configDir]"

                }
            }
        }        
    }
}

function Invoke-PayloadBuilder {
    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory
        )]
        $PayloadObject
    )
    
    process {

        $type = $PayloadObject | Get-Member | Select-Object -ExpandProperty TypeName -Unique
    
        switch ($type) {
                        
            'DiscordEmbed' {

                [bool]$createArray = $true

                #check if array
                $PayloadObject.PSObject.TypeNames | ForEach-Object {

                    switch ($_) {

                        {$_ -match '^System\.Collections\.Generic\.List.+'} {
                            
                            $createArray = $false

                        }

                        'System.Array' {

                            $createArray = $false

                        }

                        'System.Collections.ArrayList' {
                            
                            $createArray = $false

                        }
                    }
                }

                if (!$createArray) {

                    $payload = [PSCustomObject]@{

                        embeds = $PayloadObject
    
                    }

                } else {

                    $embedArray = New-Object 'System.Collections.Generic.List[DiscordEmbed]'
                    $embedArray.Add($PayloadObject) | Out-Null

                    $payload = [PSCustomObject]@{

                        embeds = $embedArray

                    }
                }
            }

            'System.String' {

                if (Test-Path $PayloadObject -ErrorAction SilentlyContinue) {

                    $payload = [DiscordFile]::New($payloadObject)

                } else {

                    $payload = [PSCustomObject]@{

                        content = ($PayloadObject | Out-String)

                    }
                }                
            }
        }
    }
    
    end {

        return $payload

    }
}


function Measure-Latest {
    BEGIN { $latest = $null }
    PROCESS {
            if (($_ -ne $null) -and (($latest -eq $null) -or ($_ -gt $latest))) {
                $latest = $_ 
            }
    }
    END { $latest }
}
