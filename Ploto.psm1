<#
.SYNOPSIS
Name: Ploto
Version: 1.1.1
Author: Tydeno

.DESCRIPTION
A basic Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself. Basically spawns and moves Plots around.
https://github.com/tydeno/Ploto
#>

function Get-PlotoOutDrives
{
	Param(
		$Replot
		)


$PathToAlarmConfig = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"

try 
    {
        $config = Get-Content -raw -Path $PathToAlarmConfig | ConvertFrom-Json -ErrorAction Stop
        
        if ($replot)
            {
                $outdrivescfg = $config.DiskConfig.ReplotDrives
            }
        else
            {
                $outdrivescfg = $config.DiskConfig.OutDrives
            }

        if ($outdrivescfg.contains(","))
            {
                $outdrivescfg = $outdrivescfg.split(",")    
            }
    }
catch
    {
         Throw $_.Exception.Message
         exit
    } 



#Check Space for outDrives
$collectionWithDisks= New-Object System.Collections.ArrayList
foreach ($drive in $outdrivescfg)
    {

            if ($drive.contains("\"))
            {
                $drletter = $drive.Split("\")[0]
                $FullPathToUse = $drive
            }
        else
            {
                $drletter = $drive
                $FullPathToUse = ""
            }

        try {
                $drive = Get-CimInstance win32_logicaldisk -Verbose:$false | Where-Object {$_.DeviceID -eq $drletter}
            }
        catch
            {
                Write-Host "GetPlotoTempDrives @ "(Get-Date)": Could not fetch defined drive: "$drletter -ForegroundColor Red
            }

        if ($drive -ne $null)
            {
                $DiskSize = [math]::Round($drive.Size  / 1073741824, 2)
                $FreeSpace = [math]::Round($drive.FreeSpace  / 1073741824, 2)


                $Partition = Get-Partition | Where-Object {$_.DriveLetter -eq ($drive.DeviceId.TrimEnd(":"))}
        
                $oldea = $ErrorActionPreference
                $ErrorActionPreference = "SilentlyContinue"

                #Get Disk from partition
                $Disk = Get-Disk -Number $Partition.DiskNumber
                $PhysicalDisk = Get-PhysicalDisk | Where-Object {$_.FriendlyName -eq $Disk.Model}

                $ErrorActionPreference = $oldea

                If ($Partition.DiskNumber -eq $null)
                    {
                        Write-Host "GetPlotoTempDrives @ "(Get-Date)": Cannot get disks for the logical volume" $tmpDrive.DeviceID "by PowerShell using Get-Partition/Get-Disk cmdlet. Cannot get the disk and temperature for reporting. Can keep going." -ForegroundColor Yellow
                        $Disk = "Not available"
                        $DiskType = "Not available"
                        $DiskBus = "Not available"
                    }
                else
                    {
                        $Disk = $Disk.Model
                        $DiskType = $PhysicalDisk.MediaType
                        $DiskBus = $PhysicalDisk.BusType
                    }


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


                If ($FreeSpace -gt 107 -and $AvailableAmounToPlot -ge 1)
                    {
                        $PlotToDest = $true
                    }
                else
                    {
                        $PlotToDest = $false
                    }

                $outdriveToPass = [PSCustomObject]@{
                DriveLetter     =  $drive.DeviceID
                FullPathToUse = $FullPathToUse
                Disk = $Disk
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
        else
            {
                Write-Host "GetPlotoTempDrives @ "(Get-Date)": Could not fetch defined drive: "$drletter -ForegroundColor Red
            }

      

    }
    return $collectionWithDisks 
}

function Get-PlotoTempDrives
{

$PathToAlarmConfig = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"

try 
    {
        $config = Get-Content -raw -Path $PathToAlarmConfig | ConvertFrom-Json -ErrorAction Stop
        $tempdrivescfg = $config.DiskConfig.TempDrives

        if ($tempdrivescfg.contains(","))
            {
                $tempdrivescfg = $tempdrivescfg.split(",")    
            }
    }
catch
    {
         Throw $_.Exception.Message
         exit
    } 



$GbUsed = 290
if ($Plotter -eq "Stotik" -or $Plotter -eq "stotik")
    {
        $GbUsed = 240
    }


#Check Space for outDrives
$collectionWithDisks= New-Object System.Collections.ArrayList
foreach ($tmpDrive in $tempdrivescfg)
    {
        if ($tmpdrive.contains("\"))
            {
                $drletter = $tmpdrive.Split("\")[0]
                $FullPathToUse = $tmpDrive
            }
        else
            {
                $drletter = $tmpdrive
                $FullPathToUse = ""
            }

        try {
                $tmpdrive = Get-CimInstance win32_logicaldisk -Verbose:$false | Where-Object {$_.DeviceID -eq $drletter}
            }
        catch
            {
                Write-Host "GetPlotoTempDrives @ "(Get-Date)": Could not fetch defined drive: "$drletter -ForegroundColor Red
            }
        if ($tmpDrive -ne $null)
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
        
                $oldea = $ErrorActionPreference
                $ErrorActionPreference = "SilentlyContinue"

                #Get Disk from partition
                $Disk = Get-Disk -Number $Partition.DiskNumber
                $PhysicalDisk = Get-PhysicalDisk | Where-Object {$_.FriendlyName -eq $Disk.Model}

                $ErrorActionPreference = $oldea

                If ($Partition.DiskNumber -eq $null)
                    {
                        Write-Host "GetPlotoTempDrives @ "(Get-Date)": Cannot get disks for the logical volume" $tmpDrive.DeviceID "by PowerShell using Get-Partition/Get-Disk cmdlet. Cannot get the disk and temperature for reporting. Can keep going." -ForegroundColor Yellow
                        Write-Host "GetPlotoTempDrives @ "(Get-Date)": Seems this disk is a RamDisk or a shared drive from another host. Will be using this disk as a RamDisk" -ForegroundColor Yellow
                        $Disk = "RAM"
                        $DiskType = "RAM"
                        $DiskBus = "RAM"
                    }
                else
                    {
                        $Disk = $Disk.Model
                        $DiskType = $PhysicalDisk.MediaType
                        $DiskBus = $PhysicalDisk.BusType
                    }

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
                
                        $RedundencyCheck = $DiskSize - ($FreeSpace + $PlotInProgressCount * $GbUsed)
                        #has addiontal data in the disk
                        if($RedundencyCheck -gt 0)
                            {
                                $AmountOfPlotsToTempMax = [math]::Floor(($FreeSpace / $GbUsed))
                                $AvailableAmounToPlot = $AmountOfPlotsToTempMax - $PlotInProgressCount
                            }
                        else
                            {
                                $AmountOfPlotsinProgressOccupied = [math]::Floor(($PlotInProgressCount * $GbUsed))
                                $AvailableAmounToPlot = [math]::Floor(($DiskSize - $AmountOfPlotsinProgressOccupied) / $GbUsed)
                                $AmountOfPlotsToTempMax = $AvailableAmounToPlot + $PlotInProgressCount
                            }

                    }

                else
                    {
                        $HasPlotInProgress = $false
                        $PlotInProgressName = " "
                        $PlotInProgressCount = 0
                        $AmountOfPlotsToTempMax = [math]::Floor(($FreeSpace / $GbUsed))
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
                FullPathToUse = $FullPathToUse
                ChiaDriveType = "Temp"
                Disk = $Disk
                DiskType = $DiskType
                DiskBus = $DiskBus
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


                $tmpDrive = $null
                
            }
                $collectionWithDisks.Add($driveToPass) | Out-Null
            }
        else
            {
                Write-Host "GetPlotoTempDrives @ "(Get-Date)": Could not fetch defined drive: "$drletter -ForegroundColor Red
            }
    }
    return $collectionWithDisks 
}

function Get-PlotoT2Drives
{

$PathToAlarmConfig = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"

try 
    {
        $config = Get-Content -raw -Path $PathToAlarmConfig | ConvertFrom-Json -ErrorAction Stop
        $t2drivescfg = $config.DiskConfig.Temp2Drives

        if ($t2drivescfg.contains(","))
            {
                $t2drivescfg = $t2drivescfg.split(",")    
            }
    }
catch
    {
         Throw $_.Exception.Message
         exit
    } 


#Check Space for outDrives
$collectionWithDisks = New-Object System.Collections.ArrayList
foreach ($tmp2Drive in $t2drivescfg)
    {
        if ($tmp2drive.contains("\"))
            {
                $drletter = $tmp2drive.Split("\")[0]
                $FullPathToUse = $tmp2Drive
            }
        else
            {
                $drletter = $tmp2drive
                $FullPathToUse = ""
            }

        try {
                $tmp2drive = Get-CimInstance win32_logicaldisk -Verbose:$false | Where-Object {$_.DeviceID -eq $drletter}
            }
        catch
            {
                Write-Host "GetPlotoTempDrives @ "(Get-Date)": Could not fetch defined drive: "$drletter -ForegroundColor Red
            }

        if ($tmp2Drive -ne $null)
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

                $oldea = $ErrorActionPreference
                $ErrorActionPreference = "SilentlyContinue"

                #Get Disk from partition
                $Disk = Get-Disk -Number $Partition.DiskNumber
                $PhysicalDisk = Get-PhysicalDisk | Where-Object {$_.FriendlyName -eq $Disk.Model}

                $ErrorActionPreference = $oldea

                If ($Partition.DiskNumber -eq $null)
                    {
                        Write-Host "GetPlotoT2Drives @ "(Get-Date)": Cannot get disks for the logical volume" $tmp2Drive.DeviceId "by PowerShell using Get-Partition/Get-Disk cmdlet. Cannot get the disk and temperature for reporting. Can keep going." -ForegroundColor Yellow
                        Write-Host "GetPlotoT2Drives @ "(Get-Date)": Seems this disk is a RamDisk. Will be using this disk as a RamDisk" -ForegroundColor Yellow
                        $Disk = "RAM"
                        $DiskType = "RAM"
                        $DiskBus = "RAM"
                    }

                else
                    {
                        $Disk = $Disk.Model
                        $DiskType = $PhysicalDisk.MediaType
                        $DiskBus = $PhysicalDisk.BusType
                    }

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
                FullPathToUse = $FullPathToUse
                ChiaDriveType = "T2"
                Disk = $Disk
                DiskType = $DiskType
                DiskBus = $DiskBus
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
        else
            {
                Write-Host "GetPlotoTempDrives @ "(Get-Date)": Could not fetch defined drive: "$drletter -ForegroundColor Red
            }
    }
    return $collectionWithDisks
}

function Invoke-PlotoJob
{
	Param(
		[parameter(Mandatory=$true)]
		$OutDrives,
	    [parameter(Mandatory=$true)]
	    $InputAmountToSpawn,
		[parameter(Mandatory=$true)]
		$TempDrives,
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
        $T2Drives,
        $WindowStyle,
        $FarmerKey,
        $PoolKey,
        $MaxParallelJobsInPhase1OnSameDisk,
        $MaxParallelJobsInPhase1OnAllDisks,
        $StartEarly,
        $StartEarlyPhase,
        $P2Singleton,
        $ReplotDrives, 
        $Replot,
        $ksize,
        $Plotter,
        $PathToUnofficialPlotter,
        $Buckets
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
    }
catch
    {
         Throw $_.Exception.Message
         exit
    } 


Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Invoking PlotoJobs started.")

$PlottableTempDrives = Get-PlotoTempDrives | Where-Object {$_.IsPlottable -eq $true}
$PlottableOutDrives = Get-PlotoOutDrives | Where-Object {$_.IsPlottable -eq $true}


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

                $PlottableTempDrives = Get-PlotoTempDrives | Where-Object {$_.IsPlottable -eq $true}   

                #Is there an nvme?
                If ($PlottableTempDrives | Where-Object {$_.DiskBus -like "*NVME*"})
                    {
                        $min = ($PlottableTempDrives | Where-Object {$_.DiskBus -like "*NVME*"} | measure-object -Property AmountOfPlotsInProgress -minimum).minimum
                        $PlottableTempDrive = $PlottableTempDrives | Where-Object {$_.DiskBus -like "*NVME*"} | Where-Object { $_.AmountOfPlotsInProgress -eq $min}
                    } 

                $min = ($PlottableTempDrives | measure-object -Property AmountOfPlotsInProgress -minimum).minimum
                $PlottableTempDrive = $PlottableTempDrives | Where-Object { $_.AmountOfPlotsInProgress -eq $min}

                if ($PlottableTempDrive.Count -gt 1)
                {
                    #We have several OutDisks in our Array that could be the best OutDrive. Need to pick one!
                    $PlottableTempDrive = $PlottableTempDrive[0]
                }

                if ($PlottableTempDrive.FullPathToUse -ne "" -or $FullPathToUse -ne $null)
                    {
                        $PlottableTempDriveDriveLetter = $PlottableTempDrive.FullPathToUse
                    }     
                    else
                    {
                        $PlottableTempDriveDriveLetter = $PlottableTempDrive.DriveLetter
                    } 

               Write-Verbose ("PlotoSpawner @ "+(Get-Date)+":  Will be using TempDrive: "+$PlottableTempDrive.DriveLetter+" to check for jobs on it...")

               $JobsAll = Get-PlotoJobs

               if ($StartEarly -eq "true")
                    {
                        Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": StartEarly set to true")
                        #Check amount of Jobs ongoin
                        $JobCountAll = (($JobsAll | Where-Object {$_.Status -lt $StartEarlyPhase -and $_.Status -ne "Completed"}) | Measure-Object).Count
                        $JobCountOnSameDisk = (($JobsAll | Where-Object {$_.Status -lt $StartEarlyPhase} | Where-Object {$_.TempDrive -eq $PlottableTempDrive.DriveLetter}) | Measure-Object).Count
                        $AmountOfJobsInPhase1OnAllDisks = ($JobsAll | Where-Object {$_.Status -ne "Completed" -and $_.Status -ne "Aborted" -and $_.Status -lt 2 } | Measure-Object).Count
                    }
                else 
                    {
                        #Check amount of Jobs ongoin
                        $JobCountAll = (($JobsAll | Where-Object {$_.Status -ne "Completed"}) | Measure-Object).Count
                        $JobCountOnSameDisk = (($JobsAll | Where-Object {$_.Status -ne "Completed"} | Where-Object {$_.TempDrive -eq $PlottableTempDrive.DriveLetter}) | Measure-Object).Count
                        $AmountOfJobsInPhase1OnAllDisks = ($JobsAll | Where-Object {$_.Status -ne "Completed" -and $_.Status -ne "Aborted" -and $_.Status -lt 2 } | Measure-Object).Count
                    }


                #Check JobCountagain
                if ($JobCountAll -lt $MaxParallelJobsOnAllDisks)
                    {
                         Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": -MaxParallelJobsOnAllDisks and MaxParallJobsOnSameDisk allow spawning. Iterating trough TempDrive: "+$PlottableTempDrive.DriveLetter)                
                        if ($JobCountOnSameDisk -lt $MaxParallelJobsOnSameDisk -and $AmountOfJobsInPhase1OnAllDisks -lt $MaxParallelJobsInPhase1OnAllDisks)
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
 
                                    $PlottableOutDrives = Get-PlotoOutDrives | Where-Object {$_.IsPlottable -eq $true}
                                    if ($PlottableOutDrives -eq $null)
                                    {
                                        Throw "Error: No outdrives found"
                                        exit
                                    } 
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": -MaxParallelJobsOnAllDisks and -MaxParallelJobsOnSameDisk allow spawning")


                                    #Building ArgumentList for chia.exe
                                    if ($Replot -eq "true" -and $ReplotDrives -ne "")
                                        {
                                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Replotting enabled. Will delete existing plots shortly upon before a job enters phase 4. Also ignoring the fact that an OutDrive has no space, as a plot will be deleted to make space for new one.")
                                            #Pick an Outdrive from ReplotDenom
                                            $replotDrives = Get-PlotoOutDrives -Replot $true

                                            $min = ($replotDrives | measure-object -Property AmountOfPlotsInProgress -minimum).minimum
                                            $OutDrive = $replotDrives | Where-Object { $_.AmountOfPlotsInProgress -eq $min}
  
                                        }
                                    else
                                        {
                                            
                                            #normal flow as we do not replot
                                            $PlottableOutDrives = Get-PlotoOutDrives | Where-Object {$_.IsPlottable -eq $true}

                                            $min = ($PlottableOutDrives | measure-object -Property AmountOfPlotsInProgress -minimum).minimum
                                            $OutDrive = $PlottableOutDrives | Where-Object { $_.AmountOfPlotsInProgress -eq $min}
                                           
                                        }

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
                                    else
                                        {
                                            if ($OutDrive.FullPathToUse -ne "" -or $FullPathToUse -ne $null)
                                                {
                                                    $OutDriveLetter = $outdrive.FullPathToUse
                                                }     
                                               else
                                                {
                                                    $OutDriveLetter = $OutDrive.DriveLetter
                                                }                                   
                                        }
                                    
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Best Outdrive most least jobs: "+$OutDriveLetter)
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Using FarmerKey: "+$FarmerKey)
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": using PoolKey: "+$PoolKey)

                                    $PlotoSpawnerJobId = ([guid]::NewGuid()).Guid
                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": GUID for PlotoSpawnerID: "+$PlotoSpawnerJobId)

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

                                    if ($Replot -eq "true" -and $ReplotDrives -ne "")
                                        {
                                            Add-Content -Path $LogPath1 -Value "IsReplot: true"
                                        }
                                    else
                                        {
                                            Add-Content -Path $LogPath1 -Value "IsReplot: false"
                                        }

                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Created LogStat file and passed values along.")

                                    if ($EnableBitfield -eq $true -or $EnableBitfield -eq "true")
                                        {
                                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Bitfield is set to be used.")

                                            if ($config.DiskConfig.EnableT2 -eq "true")
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": using T2. Scanning for most suitable...")
                                                    #Get best fitted t2 Drive 
                                                    $PlottableT2Drives = Get-PlotoT2Drives | Where-Object {$_.IsPlottable -eq $true}   
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
                                                            $ArgumentList = "-r "+$Thread+" -u "+$Buckets+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\"
                                                        }
                                                    else
                                                        {
                                                            if ($t2drive.FullPathToUse -ne "" -or $FullPathToUse -ne $null)
                                                            {
                                                                $t2driveletter = $t2drive.FullPathToUse
                                                            }
                                                            $ArgumentList = "-r "+$Thread+" -u "+$Buckets+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -2 "+$t2driveletter+"\"
                                                        }
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Using T2 Drive: "+$t2driveletter)

                                                    Add-Content -Path $LogPath1 -Value "T2Drive: $t2drive"
                                                    
                                                }
                                            else
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Not using T2 drive.")
                                                    Add-Content -Path $LogPath1 -Value "T2Drive: None"
                                                    $t2driveletter = "None"
                                                    $ArgumentList = "-r "+$Thread+" -u "+$Buckets+" -t "+$PlottableTempDriveDriveLetter+"\ -d "+$OutDriveLetter+"\"
                                                } 
                                        }

                                    else
                                        {
                                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Bitfield is not used.")
                                            
                                            if ($config.DiskConfig.EnableT2 -eq "true")
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": using T2. Scanning for most suitable...")
                                                    #Get best fitted t2 Drive 
                                                    $PlottableT2Drives = Get-PlotoT2Drives | Where-Object {$_.IsPlottable -eq $true}   
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
                                                            $ArgumentList = "-r "+$Thread+" -u "+$Buckets+" -t  "+$PlottableTempDriveDriveLetter+"\ -d "+$OutDriveLetter+"\"
                                                        }
                                                    else
                                                        {
                                                        if ($t2drive.FullPathToUse -ne "" -or $FullPathToUse -ne $null)
                                                            {
                                                                $t2driveletter = $t2drive.FullPathToUse
                                                            }
                                                            $ArgumentList = "-r "+$Thread+" -u "+$Buckets+" -t "+$PlottableTempDriveDriveLetter+"\ -d "+$OutDriveLetter+"\ -2 "+$t2driveletter+"\"
                                                        }
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Using T2 Drive: "+$t2driveletter)

                                                    Add-Content -Path $LogPath1 -Value "T2Drive: $t2drive"

                                                }
                                            else
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Not using T2 drive.")
                                                    Add-Content -Path $LogPath1 -Value "T2Drive: None"
                                                    $t2driveletter = "None"
                                                    $ArgumentList = "-r "+$Thread+" -u "+$Buckets+" -t "+$PlottableTempDriveDriveLetter+"\ -d "+$OutDriveLetter+"\ -e"
                                                }
                                           }


                                    if ($P2Singleton -ne "")
                                        {

                                            #Lets check if its a Key
                                            $CharArray = $FarmerKey.ToCharArray()
                                            if ($CharArray.Count -eq 96)
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": This looks like a valid key based on its length")
                                                    $ExpandedArgs = "-f "+$FarmerKey
                                                    $ArgumentList = $ArgumentList+" "+$ExpandedArgs
                                                }
     
                                            $ExpandedArgs1 = 
                                            $ExpandedArgs = "-c "+$P2Singleton
                                            $ArgumentList = $ArgumentList+" "+$ExpandedArgs
                                            Add-Content -Path $LogPath1 -Value "IsPoolablePlot: true"
                                            Add-Content -Path $LogPath1 -Value "P2SingletonAdress: $P2Singleton"
 
                                        }
                                    else
                                        {
                                            if ($FarmerKey -ne "" -or $FarmerKey -ne " ")
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

                                            if ($PoolKey -ne "" -or $PoolKey -ne " ")
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
                                                                                          
                                            Add-Content -Path $LogPath1 -Value "IsPoolablePlot: false"
                                            Add-Content -Path $LogPath1 -Value "P2SingletonAdress: none"
                                        }

                                    #finally launch chia exe

                                    if ($Plotter -eq "" -or $Plotter -eq " ")
                                        {
                                            $Plotter = "Chia"
                                        }

                                    if ($Plotter -eq "Chia")
                                    {
                                        Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Using Chia Official plotter.")
                                        $ChiaBasePath = "$env:LOCALAPPDATA\chia-blockchain"

                                        $ChiaVersion = ((Get-ChildItem $ChiaBasePath | Where-Object {$_.Name -like "*app*"}).Name.Split("-"))[1]
                                        $PathToChia = $ChiaBasePath+"\app-"+$ChiaVersion+"\resources\app.asar.unpacked\daemon\chia.exe" 
                                        Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Calculated path to chia.exe: "+$PathToChia)
             
                                        $baseArgs = "plots create -k 32 -b "+$BufferSize
                                        $ArgumentList = $baseArgs+" "+$ArgumentList
                                        try 
                                            {
                                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Launching chia.exe with params.")
                                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Using ArgumentList:"+$ArgumentList)
                                                Add-Content -Path $LogPath1 -Value "ArgumentList: $ArgumentList"
                                                Add-Content -Path $LogPath1 -Value "PlotterUsed: Chia"

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
                                                PlotterUsed = "Chia Official"
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

                                            if ($procid -eq $null)
                                                {
                                                    Add-Content -Path $LogPath1 -Value "PID: None" -Force
                                                }
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

                                    if ($Plotter -eq "Stotik" -or $Plotter -eq "stotik")
                                        {
                                            Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Will be using Stotik Plotter.")

                                            try 
                                                {
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Launching chia_plot.exe with params.")
                                                    Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Using ArgumentList:"+$ArgumentList)
                                                    Add-Content -Path $LogPath1 -Value "ArgumentList: $ArgumentList"
                                                    Add-Content -Path $LogPath1 -Value "PlotterUsed: Stotik"                                          
                                                    $chiaplotexe = Start-Process $PathToUnofficialPlotter -ArgumentList $ArgumentList -RedirectStandardOutput $LogPath -PassThru -WindowStyle $WindowStyle
                                                    $procid = $chiaplotexe.id

                                                    Add-Content -Path $LogPath1 -Value "PID: $procid" -Force
                                                    Write-Verbose ("PlotoSpawner @"+(Get-Date)+": Added PID to LogStatFile.")

                                                    $counter = $counter+1

                                                    #Getting Plot Object Ready
                                                    $PlotJob = [PSCustomObject]@{
                                                    JobId = $PlotoSpawnerJobId
                                                    ProcessID = $chiaplotexe.Id
                                                    OutDrive     =  $OutDriveLetter
                                                    TempDrive = $PlottableTempDrive.DriveLetter
                                                    T2Drive = $t2driveletter
                                                    ArgumentsList = $ArgumentList
                                                    ChiaVersionUsed = $ChiaVersion
                                                    LogPath = $LogPath
                                                    StartTime = $StartTime
                                                    PlotterUsed = "Stotik"
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
                                                }

                                            catch
                                                {
                                                    if ($procid -eq $null)
                                                        {
                                                            Add-Content -Path $LogPath1 -Value "PID: None" -Force
                                                        }
                                                    Write-Host "PlotoSpawner @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
                                                    Write-Verbose ("PlotoSpawner @"+(Get-Date)+": ERROR! Could not launch chia_plot.exe. Check chiapath and arguments (make sure version is set correctly!). Arguments used: "+$ArgumentList)

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

                                            #Deduct 106GB from OutDrive Capacity in Var
                                            $DeductionOutDrive = ($OutDrive.FreeSpace - 106)
                                            $OutDrive.FreeSpace="$DeductionOutDrive"             
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
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Job count in P1 on all drives: "+$AmountOfJobsInPhase1OnAllDisks) 
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Max allowed on all drives in P1: "+$MaxParallelJobsInPhase1OnAllDisks) 
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Skipping Drive: "+$PlottableTempDrive)
                            }
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

    Write-Host "PlotoManager @"(Get-Date)": Checking paths..."

    $PathToPLotterFolder = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\plotter"

    if (Test-Path $PathToPLotterFolder)
        {
            Write-Host "PlotoManager @"(Get-Date)": plotter folder available." -ForegroundColor Green
        }
    else
        {
           Write-Host "PlotoManager @"(Get-Date)": plotter folder NOT available. Creating now..." -ForegroundColor Yellow
           New-Item -Path $env:HOMEDRIVE$env:HOMEPath"\.chia\mainnet\" -Name plotter -ItemType Directory | out-null
        }

    Write-Host "PlotoManager @"(Get-Date)": Loading config from "$env:HOMEDRIVE$env:HOMEPath"\.chia\mainnet\config\PlotoSpawnerConfig.json..."
    $PathToConfig = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"

    try 
        {
            $config = Get-Content -raw -Path $PathToConfig | ConvertFrom-Json
            Write-Host "PlotoManager @"(Get-Date)": Loaded config successfully." -ForegroundColor Green
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

            throw "Exiting cause there is no readable config."
        } 

    #setting params from config 
    $EnableAlerts = $config.EnableAlerts
    $WindowStyle = $config.ChiaWindowStyle
    $EnableFy = $config.EnablePlotoFyOnStart
    $Plotter = $config.PlotterUsed
    $PathToUnofficialPlotter = $config.PathToUnofficialPlotter

    [int]$IntervallToWait = $config.SpawnerConfig.IntervallToCheckInMinutes
    [int]$InputAmountToSpawn = $config.SpawnerConfig.InputAmountToSpawn 
    [int]$MaxParallelJobsOnAllDisks = $config.SpawnerConfig.MaxParallelJobsOnAllDisks
    [int]$MaxParallelJobsOnSameDisk = $config.SpawnerConfig.MaxParallelJobsOnSameDisk
    [int]$WaitTimeBetweenPlotOnSeparateDisks = $config.SpawnerConfig.WaitTimeBetweenPlotOnSeparateDisks
    [int]$WaitTimeBetweenPlotOnSameDisk = $config.SpawnerConfig.WaitTimeBetweenPlotOnSameDisk
    $MaxParallelJobsInPhase1OnAllDisks = $config.SpawnerConfig.MaxParallelJobsInPhase1OnAllDisks
    $StartEarly = $config.SpawnerConfig.StartEarly
    $StartEarlyPhase = $config.SpawnerConfig.StartEarlyPhase
    $Replot = $config.SpawnerConfig.ReplotForPool

    $OutDrives = $config.DiskConfig.OutDrives
    $TempDrives = $config.DiskConfig.TempDrives
    $t2drives = $config.DiskConfig.Temp2Drives
    $ReplotDrives = $config.DiskConfig.ReplotDrives

    [int]$BufferSize = $config.JobConfig.BufferSize
    [int]$Thread = $config.JobConfig.Thread
    $EnableBitfield = $config.JobConfig.Bitfield
    $FarmerKey = $config.JobConfig.FarmerKey
    $PoolKey = $config.JobConfig.PoolKey
    $P2Singleton = $config.JobConfig.P2SingletonAdress
    $ksize = $config.JobConfig.KSizeToPlot
    $Buckets = $config.JobConfig.Buckets
    Write-Host "--------------------------------------------------------------------------------------------------"

    Write-Host "PlotoManager @"(Get-Date)": BaseConfig:" -ForegroundColor Cyan

    Write-Host "PlotoManager @"(Get-Date)": AlertsEnabled:"$EnableAlerts -ForegroundColor Cyan
    Write-Host "PlotoManager @"(Get-Date)": WindowStyle:"$WindowStyle -ForegroundColor Cyan
    Write-Host "PlotoManager @"(Get-Date)": EnableAlertWatchdogOnStartUp:"$EnableFy -ForegroundColor Cyan
    Write-Host "PlotoManager @"(Get-Date)": UsingPlotter:"$Plotter -ForegroundColor Cyan
    Write-Host "PlotoManager @"(Get-Date)": CustomPlotterPath"$PathToUnofficialPlotter -ForegroundColor Cyan

    Write-Host "--------------------------------------------------------------------------------------------------"

    Write-Host "PlotoManager @"(Get-Date)": SpawnerConfig" -ForegroundColor Magenta
    Write-Host "PlotoManager @"(Get-Date)": Total amount of Plots to generate: "$InputAmountToSpawn -ForegroundColor Magenta
    Write-Host "PlotoManager @"(Get-Date)": Intervall to check between possible Spawns in Minutes: "$IntervallToWait -ForegroundColor Magenta
    Write-Host "PlotoManager @"(Get-Date)": Max parallel Jobs across all Disks allowed: "$MaxParallelJobsOnAllDisks -ForegroundColor Magenta
    Write-Host "PlotoManager @"(Get-Date)": Max parallel Jobs across one single Disk allowed: "$MaxParallelJobsOnSameDisk -ForegroundColor Magenta
    Write-Host "PlotoManager @"(Get-Date)": Max parallel Jobs across all disks in Phase 1 allowed: "$MaxParallelJobsInPhase1OnAllDisks -ForegroundColor Magenta
    Write-Host "PlotoManager @"(Get-Date)": Stagger time in minutes to wait between jobs on the same disk: "$WaitTimeBetweenPlotOnSameDisk -ForegroundColor Magenta
    Write-Host "PlotoManager @"(Get-Date)": Stagger time in minutes to wait between jobs on another disk: "$WaitTimeBetweenPlotOnSeparateDisks -ForegroundColor Magenta
    Write-Host "PlotoManager @"(Get-Date)": Start a new job when another finished starts phase 4: "$StartEarly -ForegroundColor Magenta
    Write-Host "PlotoManager @"(Get-Date)": Replotting is enabled (delete a Plot when on matching drive if a new one enter phase 4): "$Replot -ForegroundColor Magenta

    Write-Host "--------------------------------------------------------------------------------------------------"

    Write-Host "PlotoManager @"(Get-Date)": DiskConfig" -ForegroundColor Gray
    Write-Host "PlotoManager @"(Get-Date)": Using temp drives: "$TempDrives -ForegroundColor Gray
    Write-Host "PlotoManager @"(Get-Date)": Using -2 drives: "$t2drives -ForegroundColor Gray
    Write-Host "PlotoManager @"(Get-Date)": Using destination drives: "$OutDrives -ForegroundColor Gray
    Write-Host "PlotoManager @"(Get-Date)": Common denominator for destination drives to replot (name of logical volume): "$ReplotDrives -ForegroundColor Gray

    Write-Host "--------------------------------------------------------------------------------------------------"

    Write-Host "PlotoManager @"(Get-Date)": JobConfig" -ForegroundColor DarkYellow
    Write-Host "PlotoManager @"(Get-Date)": ThreadCount:"$Thread -ForegroundColor DarkYellow
    Write-Host "PlotoManager @"(Get-Date)": BufferSize:"$BufferSize -ForegroundColor DarkYellow
    Write-Host "PlotoManager @"(Get-Date)": Buckets:"$Buckets -ForegroundColor DarkYellow
    Write-Host "PlotoManager @"(Get-Date)": kSize:"$ksize -ForegroundColor DarkYellow
    Write-Host "PlotoManager @"(Get-Date)": EnableBitfield:"$EnableBitfield -ForegroundColor DarkYellow
    Write-Host "PlotoManager @"(Get-Date)": PoolKey:"$PoolKey -ForegroundColor DarkYellow
    Write-Host "PlotoManager @"(Get-Date)": FarmerKey:"$FarmerKey -ForegroundColor DarkYellow
    Write-Host "PlotoManager @"(Get-Date)": P2Singleton: "$P2Singleton  -ForegroundColor DarkYellow
    Write-Host "--------------------------------------------------------------------------------------------------"

    if ($EnableFy -eq "true")
        {
            Write-Host "PlotoManager @"(Get-Date)": PlotoFy is set to startup. Checking for active PlotoFy jobs..."

            $bgjobs = Get-Job | Where-Object {$_.Name -like "*PlotoFy*"}
            if ($bgjobs)
                {
                    Write-Host "PlotoManager @"(Get-Date)": We have found active PlotoFy jobs. Stopping it and starting fresh..."
                    $bgjobs | Stop-Job | Remove-Job
                }
            try 
                {
                    Start-PlotoFy
                    Write-Host "PlotoManager @"(Get-Date)": Started PlotoFy successfully. Check your Discord" -ForegroundColor Green
                }
            catch
                {
                    Write-Host "PlotoManager @"(Get-Date)": Could not launch PlotoFy!" -ForegroundColor Red
                }

           Write-Host "---------------------------------------------------------------------------------"
            
        }

    if ($Replot -eq "true")
        {
            Write-Host "PlotoManager @"(Get-Date)": Replotting is enabled. Checking for active Watchdog jobs..."

            $bgjobs = Get-Job | Where-Object {$_.Name -like "*ReplotWatchDog*"}
            if ($bgjobs)
                {
                    Write-Host "PlotoManager @"(Get-Date)": We have found active ReplotWatchdog jobs. Stopping it and starting fresh..."
                    $bgjobs | Stop-Job | Remove-Job
                }
            try 
                {
                    Start-ReplotWatchDog
                    Write-Host "PlotoManager @"(Get-Date)": Started ReplotWatchDog successfully." -ForegroundColor Green
                }
            catch
                {
                    Write-Host "PlotoManager @"(Get-Date)": Could not launch ReplotWatchDog!" -ForegroundColor Red
                }

           Write-Host "---------------------------------------------------------------------------------"
            
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
                $SpawnedPlots = Invoke-PlotoJob -BufferSize $BufferSize -Thread $Thread -Buckets $Buckets -OutDrives $OutDrives -TempDrives $TempDrives -EnableBitfield $EnableBitfield -WaitTimeBetweenPlotOnSeparateDisks $WaitTimeBetweenPlotOnSeparateDisks -WaitTimeBetweenPlotOnSameDisk $WaitTimeBetweenPlotOnSameDisk -MaxParallelJobsOnAllDisks $MaxParallelJobsOnAllDisks -MaxParallelJobsOnSameDisk $MaxParallelJobsOnSameDisk -EnableAlerts $EnableAlerts -InputAmountToSpawn $InputAmountToSpawn -CountSpawnedJobs $SpawnedCountOverall -T2Drives $t2drives -WindowStyle $WindowStyle -FarmerKey $FarmerKey -PoolKey $PoolKey -MaxParallelJobsInPhase1OnSameDisk $MaxParallelJobsInPhase1OnSameDisk -MaxParallelJobsInPhase1OnAllDisks $MaxParallelJobsInPhase1OnAllDisks -StartEarly $StartEarly -StartEarlyPhase $StartEarlyPhase -P2Singleton $P2Singleton -ReplotDrives $ReplotDrives -Replot $Replot -ksize $ksize -Plotter $Plotter -PathToUnofficialPlotter $PathToUnofficialPlotter -Verbose
            }
        else
            {
                $SpawnedPlots = Invoke-PlotoJob -BufferSize $BufferSize -Thread $Thread -Buckets $Buckets -OutDrives $OutDrives -TempDrives $TempDrives -EnableBitfield $EnableBitfield -WaitTimeBetweenPlotOnSeparateDisks $WaitTimeBetweenPlotOnSeparateDisks -WaitTimeBetweenPlotOnSameDisk $WaitTimeBetweenPlotOnSameDisk -MaxParallelJobsOnAllDisks $MaxParallelJobsOnAllDisks -MaxParallelJobsOnSameDisk $MaxParallelJobsOnSameDisk -EnableAlerts $EnableAlerts -InputAmountToSpawn $InputAmountToSpawn -CountSpawnedJobs $SpawnedCountOverall -T2Drives $t2drives -WindowStyle $WindowStyle -FarmerKey $FarmerKey -PoolKey $PoolKey -MaxParallelJobsInPhase1OnSameDisk $MaxParallelJobsInPhase1OnSameDisk -MaxParallelJobsInPhase1OnAllDisks $MaxParallelJobsInPhase1OnAllDisks -StartEarly $StartEarly -StartEarlyPhase $StartEarlyPhase -P2Singleton $P2Singleton -ReplotDrives $ReplotDrives -Replot $Replot -ksize $ksize -Plotter $Plotter -PathToUnofficialPlotter $PathToUnofficialPlotter
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
$logs = Get-ChildItem $PlotterBaseLogPath | Where-Object {$_.Name -notlike "*@Stat*" -and $_.Name -notlike "*plotter*"}
$pattern = @("OutDrive", "TempDrive", "Starting plotting progress into temporary dirs:", "ID", "F1 complete, time","Starting phase 1/4", "Computing table 1","Computing table 2", "Computing table 3","Computing table 4","Computing table 5","Computing table 6","Computing table 7", "Starting phase 2/4", "Time for phase 1","Backpropagating on table 7", "Backpropagating on table 6", "Backpropagating on table 5", "Backpropagating on table 4", "Backpropagating on table 3", "Backpropagating on table 2", "Starting phase 3/4", "Compressing tables 1 and 2", "Compressing tables 2 and 3", "Compressing tables 3 and 4", "Compressing tables 4 and 5", "Compressing tables 5 and 6", "Compressing tables 6 and 7", "Starting phase 4/4", "Writing C2 table", "Time for phase 4", "Renamed final file", "Total time", "Could not copy", "Time for phase 3", "Time for phase 2")


$collectionWithPlotJobsOut = New-Object System.Collections.ArrayList

foreach ($log in $logs)
    {   
        #Get statlog of this log 
        $StatLogToCheck = (($PlotterBaseLogPath+$log.Name).Replace(".txt", "@Stat")+".txt")
        $patternPlotter = @("PlotterUsed")
        $loggerPlotter = Get-Content $StatLogToCheck | Select-String -Pattern $patternPlotter

        if ($loggerPlotter -eq $null)
            {
                $PlotterUsed = "Chia"
                Write-Host "Get-PlotoJobs @"(Get-Date)": This Job has 'PlotterUsed' not set in LogStat. Was created using an old version." -ForegroundColor Yellow
                Write-Host "Get-PlotoJobs @"(Get-Date)": Setting PlotterUsed in logstat to 'Chia'" -ForegroundColor Yellow
                

            }
        else
            {
                $PlotterUsed = $loggerPlotter.line.TrimStart("PlotterUsed: ")
            }

        If ($PlotterUsed -eq "Chia" -or $PlotterUsed -eq "chia")
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

        }

        If ($PlotterUsed -eq "Stotik" -or $PlotterUsed -eq "stotik")
            {

            $patternStotik = @("P1] Table 1", "P1] Table 2", "P1] Table 3", "P1] Table 4", "P1] Table 5", "P1] Table 6", "P1] Table 7", "Phase 1 took", "Phase 2 took", "P2] Table 7 rewrite", "P2] Table 6 rewrite", "P2] Table 5 rewrite", "P2] Table 4 rewrite", "P2] Table 3 rewrite", "P2] Table 2 rewrite", "P2] Phase 2 took", 'P3-2] Table 2 rewrite took', 'P3-2] Table 3 rewrite took', 'P3-2] Table 4 rewrite took', 'P3-2] Table 5 rewrite took', 'P3-2] Table 6 rewrite took', 'P3-2] Table 7 rewrite took', 'Phase 3 took', 'P4] Finished writing C2 table', "Phase 4 took", "Plot Name", "Process ID", "Total plot creation", "Started copy", "Copy to")

            $status = get-content ($PlotterBaseLogPath+"\"+$log.name) | Select-String -Pattern $patternStotik
            $ErrorActionPreference = "SilentlyContinue"
            $CurrentStatus = $status[($status.count-1)]

  
            $CompletionTimeP1 = ($status -match "Phase 1 took").line.Split(" ")[3]
            $CompletionTimeP2 = ($status -match "Phase 2 took").line.Split(" ")[3]
            $CompletionTimeP3 = ($status -match "Phase 3 took").line.Split(" ")[3]
            $CompletionTimeP4 = ($status -match "Phase 4 took").line.Split(" ")[3]

            $plotId = (($status -match "Plot Name:").line.Split("-"))[7]

            switch -Wildcard ($CurrentStatus)
                {
                    "Process ID*" {$StatusReturn = "Initializing"}
                    "Plot Name*" {$StatusReturn = "1.1"}
                    "*P1] Table 1*" {$StatusReturn = "1.2"}
                    "*P1] Table 2*" {$StatusReturn = "1.3"}
                    "*P1] Table 3*" {$StatusReturn = "1.4"}
                    "*P1] Table 4*" {$StatusReturn = "1.5"}
                    "*P1] Table 5*" {$StatusReturn = "1.6"}
                    "*P1] Table 6*" {$StatusReturn = "1.7"}
                    "*P1] Table 7*" {$StatusReturn = "1.8"}
                    "Phase 1 took*" {$StatusReturn = "2.0"}
                    "*P2] Table 7 rewrite*" {$StatusReturn = "2.1"}
                    "*P2] Table 6 rewrite*" {$StatusReturn = "2.2"}
                    "*P2] Table 5 rewrite*" {$StatusReturn = "2.3"}
                    "*P2] Table 4 rewrite*" {$StatusReturn = "2.4"}
                    "*P2] Table 3 rewrite*" {$StatusReturn = "2.5"}
                    "*P2] Table 2 rewrite*" {$StatusReturn = "2.6"}
                    "Phase 2 took*" {$StatusReturn = "3.0"}
                    "*P3-2] Table 2 rewrite took*" {$StatusReturn = "3.1"}
                    "*P3-2] Table 3 rewrite took*" {$StatusReturn = "3.2"}
                    "*P3-2] Table 4 rewrite took*" {$StatusReturn = "3.3"}
                    "*P3-2] Table 5 rewrite took*" {$StatusReturn = "3.4"}
                    "*P3-2] Table 6 rewrite took*" {$StatusReturn = "3.5"}
                    "*P3-2] Table 7 rewrite took*" {$StatusReturn = "3.6"}
                    "Phase 3 took*" {$StatusReturn = "4.0"}
                    "*P4] Finished writing C2 table*" {$StatusReturn = "4.1"}
                    "Phase 4 took*" {$StatusReturn = "4.2"}
                    "Total plot creation*" {$StatusReturn = "4.2"}
                    "Started copy*" {$StatusReturn = "4.3"}
                    "Copy to*" {$StatusReturn = "4.3"}
                    "Could not copy*" {$StatusReturn = "Error"}

                    default {$StatusReturn = "Could not fetch Status"}
                }

            }

            $Logstatfiles = Get-ChildItem $PlotterBaseLogPath | Where-Object {$_.Name -like "*@Stat*"}
            foreach ($logger in $Logstatfiles)
                {
                    $SearchStat = ($logger.name).split("@")[0]
                    $SearchChia = ($log.name).split(".")[0]

                    if ($SearchStat -eq $SearchChia)
                        {
                            $pattern2 = @("OutDrive", "TempDrive", "PID","PlotoSpawnerJobId", "StartTime", "ArgumentList", "T2Drive" , "Time for phase 1", "Time for phase 2", "Time for phase 3", "Time for phase 4", "IsPoolablePlot", "P2SingletonAdress", "IsReplot" )
                            $loggerRead = Get-Content ($PlotterBaseLogPath+"\"+$logger.Name) | Select-String -Pattern $pattern2
                            $OutDrive = ($loggerRead -match "OutDrive").line.Split("=").split(";")[1]
                            $tempDrive = ($loggerRead -match "TempDrive").line.Split("=").split(";")[1]
                            $t2drive = ($loggerRead -match "T2Drive").line.Split("=").split(";")[1]
                            $chiaPid = ($loggerRead -match "PID").line.Split(" ")[1]
                            $PlotoSpawnerJobId = ($loggerRead -match "PlotoSpawnerJobId").line.Split(" ")[1]
                            $StartTimeSplitted = ($loggerRead -match "StartTime").line.Split(":")
                            $StartTime = ($StartTimeSplitted[1]+":" + $StartTimeSplitted[2]+":" + $StartTimeSplitted[3]).TrimStart(" ")
                            $ArgumentList = ($loggerRead -match "ArgumentList").line.TrimStart("ArgumentList: ")

                            $IsPoolablePlot = ($loggerRead -match "IsPoolablePlot")
                            if ($IsPoolablePlot -eq $null)
                                {
                                    Write-Host "Get-PlotoJobs @"(Get-Date)": This Job has 'IsPoolablePlot' not set in LogStat. Was created using an old version." -ForegroundColor Yellow
                                    Write-Host "Get-PlotoJobs @"(Get-Date)": Setting IsPoolablePlot in logstat to 'false'" -ForegroundColor Yellow
                                    Add-Content -Path $StatLogToCheck -Value "PlotterUsed: false"
                                    $IsPoolablePlot = "false"
                                }
                            else
                                {
                                    $IsPoolablePlot = $IsPoolablePlot.line.TrimStart("IsPoolablePlot: ")
                                }

                            
                            $P2Adress = ($loggerRead -match "P2SingletonAdress")

                            if ($P2Adress -eq $null)
                                {
                                    Write-Host "Get-PlotoJobs @"(Get-Date)": This Job has 'P2SingletonAdress' not set in LogStat. Was created using an old version." -ForegroundColor Yellow
                                    Write-Host "Get-PlotoJobs @"(Get-Date)": Setting IsPoolablePlot in logstat to 'none'" -ForegroundColor Yellow
                                    Add-Content -Path $StatLogToCheck -Value "P2SingletonAdress: none"
                                    $P2Adress = "none"
                                }
                            else
                                {
                                    $P2Adress = $P2Adress.line.TrimStart("P2SingletonAdress: ")
                                }
                                
                                
                           $IsReplot = ($loggerRead -match "IsReplot")
                           if ($IsReplot -eq $null)
                                {
                                    Write-Host "Get-PlotoJobs @"(Get-Date)": This Job has 'ISReplot' not set in LogStat. Was created using an old version." -ForegroundColor Yellow
                                    Write-Host "Get-PlotoJobs @"(Get-Date)": Setting IsReplot in logstat to 'false'" -ForegroundColor Yellow
                                    Add-Content -Path $StatLogToCheck -Value "IsReplot: false"
                                    $IsReplot = "false"                                
                                }

                            else
                                {
                                    $IsReplot = $IsReplot.line.TrimStart("IsReplot: ")
                                }


                           $StatLogPath = $logger.FullName
                                  
                           $PlotoIdToScramble = $plotId
                           #Scramble temp dir for .tmp files

                           $FileArrToCountSize = Get-ChildItem $TempDrive | Where-Object {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".tmp"} 
                           $SizeOnDisk = "{0:N2} GB" -f (($FileArrToCountSize | Measure-Object length -s).Sum /1GB)

                           $FileArrToCountSize = Get-ChildItem $OutDrive | Where-Object {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".plot"} 
                           $SizeOnOutDisk = "{0:N2} GB" -f (($FileArrToCountSize | Measure-Object length -s).Sum /1GB)


                           if ($t2drive -ne $null)
                            {
                               $FileArrToCountSize = Get-ChildItem $t2drive | Where-Object {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".tmp"} 
                               $SizeOnT2Disk = "{0:N2} GB" -f (($FileArrToCountSize | Measure-Object length -s).Sum /1GB)
                            }

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


            #Set certian properties when is Complete
            if ($StatusReturn -eq "4.3")
                {
                if ($PlotterUsed -eq "Chia" -or $PlotterUsed -eq "chia")
                    {
                        $TimeToComplete = ($status -match "Total time").line.Split("=").Split(" ")[4]
                    }
                if ($PlotterUsed -eq "Stotik" -or $PlotterUsed -eq "stotik")
                    {
                        $TimeToComplete = ($status -match "Total plot").line.Split(" ")[5]
                    }

                    #$TimeToCompleteCalcInh = ($TimeToComplete / 60) / 60
                    $TimeToCompleteCalcInh =  [Math]::round((($TimeToComplete / 60) / 60),3)
                    $EndDate = (Get-Date $StartTime).AddHours($TimeToCompleteCalcInh)

                    $StatusReturn =  "Completed"
                    $chiaPid = "None"
                }
  
            else
                {
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

            if ($IsPoolablePlot -ne "true")
                {
                    $IsPoolablePlot = "false"
                }
            if ($IsReplot -eq "rue" -or $IsReplot -eq "true")
                {
                    $IsReplot = "true"
                }
            else
                {
                    $IsReplot = "false"
                }
            $countchars = ($ArgumentList.ToCharArray()).Count
            if ($countchars -gt 199)
                {
                    $ArgumentList = $ArgumentList -replace ".{199}$"
                    $exArgs = "-f YourKeys -p YourKeys"
                    $ArgumentList = $ArgumentList+$exArgs
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
                    PlotSizeOnT2Disk = $SizeOnT2Disk
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
                    EndDate = $EndDate
                    IsPoolablePlot = $IsPoolablePlot
                    P2SingletonAdress = $P2Adress
                    IsReplot = $IsReplot
                    PlotterUsed = $PlotterUsed
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
                    PlotSizeOnT2Disk = $SizeOnT2Disk
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
                    IsPoolablePlot = $IsPoolablePlot
                    P2SingletonAdress = $P2Adress
                    IsReplot = $IsReplot
                    PlotterUsed = $PlotterUsed
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
        $IsReplot = $null
        $P2Adress = $null
        $IsPoolablePlot = $null
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

        Write-Host "PlotoStopJob @"(Get-Date)": Found the job to be aborted with JobId: "$Job.JobId

        if ($Job.pid -ne "None" -or $null)
            {
                Write-Host "PlotostopJob @"(Get-Date)": Process with PID: "$Job.pid "is still running. Stopping it..."
                try 
                    {
                        Stop-Process -id $job.PID
                        Write-Host "PlotoStopJob @"(Get-Date)": stopped chia.exe with PID:" $job.pid -ForegroundColor Green 
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

            
                Write-Host "PlotoStopJob @"(Get-Date)": Sleeping 5 seconds before trying to attempt to delete logs and tmp files..."
                Start-Sleep 5
            }

        $PlotoIdToScramble = $job.PlotId
        #Scramble temp dir for .tmp files

        $FileArrToDel = Get-ChildItem $job.TempDrive -Recurse | Where-Object {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".tmp"} 

        if ($FileArrToDel)
            {
                Write-Host "PlotoStopJob @"(Get-Date)": Found .tmp files for this job to be deleted on TempDrive: "$Job.TempDrive


                try 
                    {
                        $FileArrToDel | Remove-Item -Force
                        Write-Host "PlotoStopJob @"(Get-Date)": Removed temp files on"$Job.TempDrive -ForegroundColor Green   
                    }

                catch
                    {
                        Write-Host "PlotoStopJob @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red   
                    }               
            }     

        if ($job.T2Drive -ne $null -or $job.T2Drive -ne "None")
            {
                $T2FileArrayToDel = Get-ChildItem $job.T2Drive -Recurse | Where-Object {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".tmp"} 

                If ($T2FileArrayToDel)
                    {
                        Write-Host "PlotoStopJob @"(Get-Date)": Found .tmp files for this job to be deleted on T2 drive."

                        try 
                            {
                                $T2FileArrayToDel | Remove-Item -Force
                                Write-Host "PlotoStopJob @"(Get-Date)": Removed temp files on t2drive: "$Job.T2Drive -ForegroundColor Green   
                            }

                        catch
                            {
                                Write-Host "PlotoStopJob @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red   
                            }    
            
                    }
            }
        
        #Remove logs

        if (Test-Path $Job.LogPath)
            {
                Write-Host "PlotoStopJob @"(Get-Date)": Found logfiles tor this job. Going ahead with deletion..."
                try
                    {
                        Remove-Item -Path $Job.LogPath
                        Write-Host "PlotStopJob @"(Get-Date)": Removed log files for this job." -ForegroundColor Green     
                    }

                catch
                    {
                       Write-Host "PlotoStopJob @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red 
                    }
            }
        if (Test-Path $Job.StatLogPath)
            {
                Write-Host "PlotoStopJob @"(Get-Date)": Found statlogfile tor this job. Going ahead with deletion..."
                try
                    {
                        Remove-Item -Path $Job.StatLogPath
                        Write-Host "PlotoStopJob @"(Get-Date)": Removed statlog files for this job." -ForegroundColor Green     
                    }

                catch
                    {
                       Write-Host "PlotostopJob @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red 
                    }
            }

}

function Remove-AbortedPlotoJobs
{
    $JobsToAbort = Get-PlotoJobs | Where-Object {$_.Status -eq "Aborted"}
    Write-Host "PlotoRemoveAbortedJobs @"(Get-Date)": Found aborted Jobs to be deleted:"$JobsToAbort.JobId
    Write-Host "PlotoRemoveAbortedJobs @"(Get-Date)": Cleaning up..."
    $count = 0

    $collectionWithJobsToReport= New-Object System.Collections.ArrayList
    foreach ($job in $JobsToAbort)
        {
            if ($job.CompletionTime -eq "None")
                {
                    $completiontime = 0
                }
            else
                {
                    $completiontime = $job.CompletionTime
                }
            [datetime]$StartTime = Get-Date ($job.starttime)

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
            EndDate = (Get-Date $StartTime).AddHours($completiontime)
            }

            #Send notification about spotted Job that is aborted
            if ($EnableAlerts -eq $true)
            {
                #Create embed builder object via the [DiscordEmbed] class
                $embedBuilder = [DiscordEmbed]::New(
                                    'A job in progress was aborted.',
                                    'Just letting you know that I found an aborted Job. Claning it now.'
                                )
                $StaId = "ArgumentList"
                $JobDetailsStartTimeMsg = $job.ArgumentList
                $embedBuilder.AddField(
                    [DiscordField]::New(
                        $StaId,
                        $JobDetailsStartTimeMsg, 
                        $true
                    )
                )

                $StaId = "StartTime"
                $JobDetailsStartTimeMsg = $job.StartTime
                $embedBuilder.AddField(
                    [DiscordField]::New(
                        $StaId,
                        $JobDetailsStartTimeMsg, 
                        $true
                    )
                )

                #Add purple color
                $embedBuilder.WithColor(
                    [DiscordColor]::New(
                        'yellow'
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
           
            Stop-PlotoJob -JobId $job.jobid
            Write-Host "-----------------------------------------------------------------------"
            $count++
        }
    Write-Host "PlotoRemoveAbortedJobs @"(Get-Date)": Removed Amount of aborted Jobs:"$count

}

function Get-PlotoPlots
{
	Param(
    $replot
		)

#Scan for final Plot Files to Move

if ($replot)
    {
        $OutDrivesToScan = Get-PlotoOutDrives -Replot $true
    }
else
    {
        $OutDrivesToScan = Get-PlotoOutDrives
    }


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
                            CreationTime = $item.CreationTime
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

$PlotsToMove = Get-PlotoPlots

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

function Invoke-PlotoDeleteForReplot
{

	Param(
		[parameter(Mandatory=$true)]
		$ReplotDrives
		)

    #Get active jobs entering phase 4.
    $activeJobs = Get-PlotoJobs | Where-Object {$_.Status -ge 3.9} | Where-Object {$_.IsReplot -eq "true"}
    if ($activeJobs)
        {
            Write-Host ("PlotoDeleteForReplot @ "+(Get-Date)+": Found active jobs that are about to enter phase 4")

            foreach ($job in $activeJobs)
                {
                        Write-Host ("PlotoDeleteForReplot @ "+(Get-Date)+": Checking if selected ReplotDrive has enough space or oldest plot needs to be deleted..")
                        #Check if we need to delete a plot on that OutDrive spacewise, with active jobs to it in mind.
                        $OutDriveToCheck = Get-PlotoOutDrives -Replot $true | Where-Object {$_.DriveLetter -eq $job.OutDrive}

                        if ($OutDriveToCheck.FreeSpace -lt 107 -and $OutDriveToCheck.AvailableAmountToPlot -le 1)
                            {
                                Write-Host ("PlotoDeleteForReplot @ "+(Get-Date)+": Not enough space available for new plot, need to delete oldest one for replotting... ")
                                #pick oldest plottodel
                                $plottoDel = (Get-PlotoPlots -replot $true | sort creationtime)[0]
                                Write-Host ("PlotoDeleteForReplot @ "+(Get-Date)+": Oldest Plot in ReplotDrive "+$OutDriveToCheck.DriveLetter+ " of job with id "+$job.JobId+" that is about to finish: "+$plottoDel.FilePath)

                                $plotitemtodel = Get-ChildItem $plottoDel.FilePath
                                try 
                                    {
                                       $plotitemtodel | Remove-Item
                                       Start-Sleep 30
                                    } 
                                catch
                                    {
                                        Write-Host ("PlotoDeleteForReplot @ "+(Get-Date)+": ERROR: Could not delete Plot! See below for details. ") -ForegroundColor Red
                                        Write-Host $_.Exception.Message -ForegroundColor Red
                                    }
                            }
                        else
                            {
                                Write-Host ("PlotoDeleteForReplot @ "+(Get-Date)+": Selected ReplotDrive (OutDrive of PlotJob) "+$OutDriveToCheck.DriveLetter+" has enough space. No deletion needed.")
                            }
                }
        }
    else
        {
            Write-Host ("PlotoDeleteForReplot @ "+(Get-Date)+": No active jobs that are about to enter phase 4.")
        }

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

    $ReportPeriod = $config.SpawnerAlerts.PeriodOfReportInHours

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
                        
                        $countchars = ($j.ArgumentList.ToCharArray()).Count
                        if ($countchars -gt 199)
                            {
                                $arglistun = $j.ArgumentList
                                $ArgumentList = $arglistun -replace ".{199}$"
                                $exArgs = "-f YourKeys -p YourKeys"
                                $JobDetailsArgListMsg = $ArgumentList+$exArgs
                            }
                        else
                            {
                                 $JobDetailsArgListMsg = $j.ArgumentList.TrimStart("plots create ")
                            }


                       
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
                $AvgDur = [math]::Round($AvgDur,3)

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

                $WebHookURL = $config.SpawnerAlerts.DiscordWebHookURL

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

                $WebHookURL = $config.SpawnerAlerts.DiscordWebHookURL

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

                $WebHookURL = $config.SpawnerAlerts.DiscordWebHookURL

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
    for ($count -lt 10000000)
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
        
        $sleep = $config.SpawnerAlerts.PeriodOfReportInHours
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
             Write-Verbose "Loaded Config successfully"
         }
     catch
         {
             Throw $_.Exception.Message
         } 
 
    $PathToPloto = $config.PathToPloto 
    Unblock-File $PathToPloto
    Import-Module $PathToPloto -Force
    Request-PlotoFyStatusReport -ErrorAction stop
    } -ArgumentList $PathToPloto, $PathToPloto -Name PlotoFy

}

function Request-CheckForDeletion
{

$PathToAlarmConfig = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"

try 
    {
        $config = Get-Content -raw -Path $PathToAlarmConfig | ConvertFrom-Json -ErrorAction Stop
    }
catch
    {
         Throw $_.Exception.Message
         exit
    } 

$ReplotDriveDenom = $config.DiskConfig.DenomForOutDrivesToReplotForPools

$count = 0
    for ($count -lt 100000000000)
        {
           Invoke-PlotoDeleteForReplot -ReplotDriveDenom $ReplotDriveDenom
           $count++
           Start-Sleep 300 
        }

}

function Start-ReplotWatchDog
{

    Start-Job -ScriptBlock {
        try 
            {
                 $PathToAlarmConfig = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\config\PlotoSpawnerConfig.json"
                 $config = Get-Content -raw -Path $PathToAlarmConfig | ConvertFrom-Json -ErrorAction Stop
                 Write-Verbose "Loaded Config successfully"
             }
         catch
             {
                 Throw $_.Exception.Message
             } 

       $PathToModule = $config.PathToPloto
       Unblock-File $PathToModule
       Import-Module $PathToModule -Force
       Request-CheckForDeletion
    } -ArgumentList $PathToModule -Name ReplotWatchDog 
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
