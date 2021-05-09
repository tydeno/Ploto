<#
.SYNOPSIS
Name: Ploto
Version: 1.0.6.2
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

$outDrives = get-WmiObject win32_logicaldisk | ? {$_.VolumeName -like "*$OutDriveDenom*"}

#Check Space for outDrives
$collectionWithDisks= New-Object System.Collections.ArrayList
foreach ($drive in $outDrives)
    {

        $DiskSize = [math]::Round($tmpDrive.Size  / 1073741824, 2)
        $FreeSpace = [math]::Round($drive.FreeSpace  / 1073741824, 2)
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
        AmountOfPlotsToHold = [math]::Floor(($FreeSpace / 100))
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

$tmpDrives = get-WmiObject win32_logicaldisk | ? {$_.VolumeName -like "*$TempDriveDenom*"}

#Check Space for outDrives
$collectionWithDisks= New-Object System.Collections.ArrayList
foreach ($tmpDrive in $tmpDrives)
    {
        $FolderCheck = Get-ChildItem $tmpDrive.DeviceId | ? {$_.Attributes -eq "Directory"}
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


        #Get-CurrenJobs
        $activeJobs = Get-PlotoJobs |? {$_.TempDrive -eq $tmpDrive.DeviceId} | ? {$_.Status -ne "Completed"}
        if ($activeJobs)
            {
                $HasPlotInProgress = $true
                $PlotInProgressName = $activeJobs.PlotId
                $PlotInProgressCount = $activeJobs.count

                $AmountOfPlotsToTempMax = [math]::Floor(($FreeSpace / 290))

                if ($PlotInProgressCount -eq $null)
                    {
                        $PlotInProgressCount = 1
                    }
                $AvailableAmounToPlot = $AmountOfPlotsToTempMax - $PlotInProgressCount

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
        $EnableBitfield
		)

 if($verbose) {

   $oldverbose = $VerbosePreference
   $VerbosePreference = "continue" }

if ($MaxParallelJobsOnSameDisk -eq $null)
    {
        $MaxParallelJobsOnSameDisk = 1
    }
if ($WaitTimeBetweenPlotOnSameDisk -eq $null)
    {
        $WaitTimeBetweenPlotOnSameDisk = 0.1
    }

Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Invoking PlotoJobs started.")

$PlottableTempDrives = Get-PlotoTempDrives -TempDriveDenom $TempDriveDenom | ? {$_.IsPlottable -eq $true}   
$PlottableOutDrives = Get-PlotoOutDrives -OutDriveDenom $OutDriveDenom | ? {$_.IsPlottable -eq $true}


if ($PlottableOutDrives -eq $null)
    {
        Throw "Error: No outdrives found"
    } 

$collectionWithPlotJobs= New-Object System.Collections.ArrayList
$JobCountAll0 = (Get-PlotoJobs | ? {$_.Status -ne "Completed"}).Count

if ($PlottableTempDrives -and $JobCountAll0 -lt $MaxParallelJobsOnAllDisks)
    {
         Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Found available temp drives.")
         $PlottableTempDrivesOutput = $PlottableTempDrives | ft
         Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": "+$PlottableTempDrivesOutput)

         foreach ($PlottableTempDrive in $PlottableTempDrives)
            {
                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Iterating trough TempDrive: "+$PlottableTempDrive.DriveLetter)
                #Check amount of Jobs ongoin
                $JobCountAll = (Get-PlotoJobs | ? {$_.Status -ne "Completed"}).Count
                $JobCountOnSameDisk = (Get-PlotoJobs | ? {$_.Status -ne "Completed"} | ? {$_.TempDrive -eq $PlottableTempDrive.DriveLetter}).Count

                if ($JobCountAll -ge $MaxParallelJobsOnAllDisks -or $JobCountOnSameDisk -ge $MaxParallelJobsOnSameDisk)
                    {
                         Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Found available Temp Drives, but -MaxParallelJobsOnAllDisks and or -MaxParallelJobsOnSameDisk prohibits spawning.")
                         Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Amount of Plots in Progress overall: "+$MaxParallelJobsOnAllDisks)
                         Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Amount of Plots in Progress on this Drive: "+$MaxParallelJobsOnSameDisk) 
                         Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Skipping Drive: "+$PlottableTempDrive)
                    }

                else
                    {
                        Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": -MaxParallelJobsOnAllDisks and or -MaxParallelJobsOnSameDisk allow spawning")
                        $max = ($PlottableOutDrives | measure-object -Property FreeSpace -maximum).maximum
                        $OutDrive = $PlottableOutDrives | ? { $_.FreeSpace -eq $max}
                        $OutDriveLetter = $OutDrive.DriveLetter
                        Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Best Outdrive most free space: "+$OutDriveLetter)

                        $PlotoSpawnerJobId = ([guid]::NewGuid()).Guid
                        Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": GUID for PlotoSpawnerID: "+$PlotoSpawnerJobId)

                        $ChiaBasePath = "$env:LOCALAPPDATA\chia-blockchain"

                        $ChiaVersion = ((Get-ChildItem $ChiaBasePath | ? {$_.Name -like "*app*"}).Name.Split("-"))[1]
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

                        if ($EnableBitfield -eq $true -or $EnableBitfield -eq "yes")
                            {
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Bitfield is set to be used.")
                                $ArgumentList = "plots create -k 32 -b "+$BufferSize+" -r "+$Thread+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\"
                            }

                        else
                            {
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Bitfield is not used.")
                                $ArgumentList = "plots create -k 32 -b "+$BufferSize+" -r "+$Thread+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -e"
                            }
                        

                        try 
                            {
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Launching chia.exe with params.")
                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Using ArgumentList:"+$ArgumentList)
                                Add-Content -Path $LogPath1 -Value "ArgumentList: $ArgumentList"
                                $chiaexe = Start-Process $PathToChia -ArgumentList $ArgumentList -RedirectStandardOutput $LogPath -PassThru
                                $pid = $chiaexe.Id
                                Add-Content -Path $LogPath1 -Value "PID: $pid" -Force
                                Write-Verbose ("PlotoSpawner @"+(Get-Date)+": Added PID to LogStatFile.")

                                #Deduct 106GB from OutDrive Capacity in Var
                                $DeductionOutDrive = ($OutDrive.FreeSpace - 106)
                                $OutDrive.FreeSpace="$DeductionOutDrive"
                            }

                        catch
                            {
                                Write-Verbose ("PlotoSpawner @"+(Get-Date)+": ERROR! Could not launch chia.exe. Check chiapath and arguments (make sure version is set correctly!). Arguments used: "+$ArgumentList) 
                                Write-Host "PlotoSpawner @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
                            }


                        if ($PlottableTempDrive.AvailableAmountToPlot -gt 1 -and $MaxParallelJobsOnSameDisk -gt 1)
                            {
                                Write-Verbose ("PlotoSpawner @"+(Get-Date)+": Current drive has space to temp more than 1x Plot and -MaxParallelJobsOnSameDisk param allows it.")
                                $count = 1
                                do
                                    {
                                        $JobCountAll2 = (Get-PlotoJobs | ? {$_.Status -ne "Completed"}).Count
                                        $JobCountOnSameDisk2 = (Get-PlotoJobs | ? {$_.Status -ne "Completed"} | ? {$_.TempDrive -eq $PlottableTempDrive.DriveLetter}).Count
                                        Write-Verbose ("PlotoSpawner @"+(Get-Date)+": Checking if Disk has any active Jobs and if count is higher than what it is allowed to.")
                                        if ($JobCountAll2 -ge $MaxParallelJobsOnAllDisks -or $JobCountOnSameDisk2 -ge $MaxParallelJobsOnSameDisk)
                                            {
                                                Write-Verbose ("PlotoSpawner @"+(Get-Date)+": Disk has active Jobs and count is higher than what is allowed as Input or calculated")
                                            }
                                        else
                                            {
                                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+" : Spawning of Job on Disk "+$PlottableTempDrive.DriveLetter+" is allowed.")
                                                $PlotoSpawnerJobId = ([guid]::NewGuid()).Guid
                                                $ChiaBasePath = "$env:LOCALAPPDATA\chia-blockchain"
                                                $ChiaVersion = ((Get-ChildItem $ChiaBasePath | ? {$_.Name -like "*app*"}).Name.Split("-"))[1]
                                                $PathToChia = $ChiaBasePath+"\app-"+$ChiaVersion+"\resources\app.asar.unpacked\daemon\chia.exe" 
                                                $PlotterBaseLogPath = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\plotter\"
                                                $LogNameBasePath = "PlotoSpawnerLog_"+((Get-Date).Day.ToString())+"_"+(Get-Date).Month.ToString()+"_"+(Get-Date).Hour.ToString()+"_"+(Get-Date).Minute.ToString()+"_"+$PlotoSpawnerJobId+"_Tmp-"+(($PlottableTempDrive).DriveLetter.Split(":"))[0]+"_Out-"+($OutDriveLetter.Split(":"))[0]+".txt"
                                                $LogPath= $PlotterBaseLogPath+$LogNameBasePath

                                                $logstatName = "PlotoSpawnerLog_"+((Get-Date).Day.ToString())+"_"+(Get-Date).Month.ToString()+"_"+(Get-Date).Hour.ToString()+"_"+(Get-Date).Minute.ToString()+"_"+$PlotoSpawnerJobId+"_Tmp-"+(($PlottableTempDrive).DriveLetter.Split(":"))[0]+"_Out-"+($OutDriveLetter.Split(":"))[0]+"@Stat.txt"

                                                $StartTime = (Get-Date)

                                                $logPath1 = (New-Item -Path $PlotterBaseLogPath -Name $logstatName).FullName
                                                Add-Content -Path $LogPath1 -Value "PlotoSpawnerJobId: $PlotoSpawnerJobId"
                                                Add-Content -Path $LogPath1 -Value "OutDrive: $OutDrive"
                                                Add-Content -Path $LogPath1 -Value "TempDrive: $PlottableTempDrive"
                                                Add-Content -Path $LogPath1 -Value "StartTime: $StartTime"
                                                


                                                $max = ($PlottableOutDrives | measure-object -Property FreeSpace -maximum).maximum
                                                $OutDrive = $PlottableOutDrives | ? { $_.FreeSpace -eq $max}
                                                $OutDriveLetter = $OutDrive.DriveLetter

                                                if ($EnableBitfield -eq $true -or $EnableBitfield -eq "yes")
                                                    {
                                                        $ArgumentList = "plots create -k 32 -b "+$BufferSize+" -r "+$Thread+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\"
                                                    }

                                                else
                                                    {
                                                        $ArgumentList = "plots create -k 32 -b "+$BufferSize+" -r "+$Thread+" -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -e"
                                                    }

                                                try 
                                                    {
                                                        Write-Verbose ("PlotoSpawner @ "+(Get-Date)+" : Launching Chia in parallel on same disk.")
                                                        Write-Verbose ("PlotoSpawner @ "+(Get-Date)+" : Using ArgumentList:"+$ArgumentList)
                                                        Add-Content -Path $LogPath1 -Value "ArgumentList: $ArgumentList"
                                                        $chiaexe = Start-Process $PathToChia -ArgumentList $ArgumentList -RedirectStandardOutput $logPath -PassThru
                                                        $pid = $chiaexe.Id
                                                        Add-Content -Path $LogPath1 -Value "PID: $pid" -Force

                                                        #Deduct 106GB from OutDrive Capacity in Var
                                                        $DeductionOutDrive = ($OutDrive.FreeSpace - 106)
                                                        $OutDrive.FreeSpace="$DeductionOutDrive"
                                                    }
                                                catch
                                                    {
                                                        Write-Host "PlotoMover @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
                                                        Write-Host "PlotoSpawner @"(Get-Date)": ERROR! Could not launch chia.exe. Chia Version tried to launch: $ChiaVersion. Check chiapath and arguments (make sure there is only latest installed chia version folder, eg app-1.1.2). Arguments used:"$ArgumentList -ForegroundColor Red
                                                    }


                                                $count++
                                                Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Starting to sleep for"+$WaitTimeBetweenPlotOnSameDisk)
                                                Start-Sleep ($WaitTimeBetweenPlotOnSameDisk*60)
                                            
                                            }
                                    }

                                until ($count -eq $PlottableTempDrive.AvailableAmountToPlot -or $count -eq $MaxParallelJobsOnSameDisk)
                            }


                        #Getting Plot Object Ready
                        $PlotJob = [PSCustomObject]@{
                        JobId = $PlotoSpawnerJobId
                        ProcessID = $chiaexe.Id
                        OutDrive     =  $OutDriveLetter
                        TempDrive = $PlottableTempDrive.DriveLetter
                        ArgumentsList = $ArgumentList
                        ChiaVersionUsed = $ChiaVersion
                        LogPath = $LogPath
                        StartTime = $StartTime
                        }

                        $collectionWithPlotJobs.Add($PlotJob) | Out-Null

                        Write-Host "PlotoSpawner @"(Get-Date)": Spawned the following plot Job:" -ForegroundColor Green
                        $PlotJob | Out-Host

                        Start-Sleep ($WaitTimeBetweenPlotOnSeparateDisks*60)
                    }
                Write-Verbose "--------------------------------------------------------------------"
            }
    }
else
    {
        Write-Host "PlotoSpawner @"(Get-Date)": No Jobs spawned as either no TempDrives available or max parallel jobs reached. Max Parallel Jobs: "$MaxParallelJobsOnAllDisks "Current amount of Jobs: $JobCountAll0" -ForegroundColor Yellow
    }

   $VerbosePreference = $oldverbose
   return $collectionWithPlotJobs
}

function Start-PlotoSpawns
{
	Param(
	[parameter(Mandatory=$true)]
	$InputAmountToSpawn,
	[parameter(Mandatory=$true)]
	$OutDriveDenom,
	[parameter(Mandatory=$true)]
	$WaitTimeBetweenPlotOnSeparateDisks,
	[parameter(Mandatory=$false)]
	$WaitTimeBetweenPlotOnSameDisk,
	[parameter(Mandatory=$true)]
	$TempDriveDenom,
    [parameter(Mandatory=$true)]
    $MaxParallelJobsOnAllDisks,
    [parameter(Mandatory=$false)]
    $MaxParallelJobsOnSameDisk,
    $BufferSize = 3390,
    $Thread = 2,
    $EnableBitfield
    )

    if($verbose) 
        {
            $oldverbose = $VerbosePreference
            $VerbosePreference = "continue" 
        }

    $SpawnedCount = 0

    Do
    {
        
        if ($verbose)
            {
                $SpawnedPlots = Invoke-PlotoJob -BufferSize $BufferSize -Thread $Thread -OutDriveDenom $OutDriveDenom -TempDriveDenom $TempDriveDenom -EnableBitfield $EnableBitfield -WaitTimeBetweenPlotOnSeparateDisks $WaitTimeBetweenPlotOnSeparateDisks -WaitTimeBetweenPlotOnSameDisk $WaitTimeBetweenPlotOnSameDisk -MaxParallelJobsOnAllDisks $MaxParallelJobsOnAllDisks -MaxParallelJobsOnSameDisk $MaxParallelJobsOnSameDisk -Verbose
            }
        else
            {
                $SpawnedPlots = Invoke-PlotoJob -BufferSize $BufferSize -Thread $Thread -OutDriveDenom $OutDriveDenom -TempDriveDenom $TempDriveDenom -EnableBitfield $EnableBitfield -WaitTimeBetweenPlotOnSeparateDisks $WaitTimeBetweenPlotOnSeparateDisks -WaitTimeBetweenPlotOnSameDisk $WaitTimeBetweenPlotOnSameDisk -MaxParallelJobsOnAllDisks $MaxParallelJobsOnAllDisks -MaxParallelJobsOnSameDisk $MaxParallelJobsOnSameDisk
            }
        
        
        if ($SpawnedPlots)
            {
                $SpawnedCount = $SpawnedCount + (@($SpawnedPlots) | Measure-Object).count
                Write-Host "PlotoManager @"(Get-Date)": Amount of spawned Plots in this iteration:"(@($SpawnedPlots) | Measure-Object).count
                Write-Host "PlotoManager @"(Get-Date)": Overall spawned Plots since start of script:"$SpawnedCount
                Write-Host "________________________________________________________________________________________"
            }

        Start-Sleep 300
    }
    
    Until ($SpawnedCount -eq $InputAmountToSpawn)

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
$logs = Get-ChildItem $PlotterBaseLogPath | ? {$_.Name -notlike "*@Stat*"}
$pattern = @("OutDrive", "TempDrive", "Starting plotting progress into temporary dirs:", "ID", "F1 complete, time","Starting phase 1/4", "Computing table 1","Computing table 2", "Computing table 3","Computing table 4","Computing table 5","Computing table 6","Computing table 7", "Starting phase 2/4", "Time for phase 1","Backpropagating on table 7", "Backpropagating on table 6", "Backpropagating on table 5", "Backpropagating on table 4", "Backpropagating on table 3", "Backpropagating on table 2", "Starting phase 3/4", "Compressing tables 1 and 2", "Compressing tables 2 and 3", "Compressing tables 3 and 4", "Compressing tables 4 and 5", "Compressing tables 5 and 6", "Compressing tables 6 and 7", "Starting phase 4/4", "Writing C2 table", "Time for phase 4", "Renamed final file", "Total time", "Could not copy")

Write-Verbose ("PlotoGetJobs@ "+(Get-Date)+": Using plotter base Log Path: "+$PlotterBaseLogPath)
Write-Verbose ("PlotoGetJobs@ "+(Get-Date)+": Scrambling Logs and searching for Keywords to get status...")

$collectionWithPlotJobsOut = New-Object System.Collections.ArrayList

foreach ($log in $logs)
    {        
        $status = get-content ($PlotterBaseLogPath+"\"+$log.name) | Select-String -Pattern $pattern
        $CurrentStatus = $status[($status.count-1)]
        $ErrorActionPreference = "SilentlyContinue"

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

            $Logstatfiles = Get-ChildItem $PlotterBaseLogPath | ? {$_.Name -like "*@Stat*"}
            foreach ($logger in $Logstatfiles)
                {
                    $SearchStat = ($logger.name).split("@")[0]
                    $SearchChia = ($log.name).split(".")[0]

                    if ($SearchStat -eq $SearchChia)
                        {
                           $pattern2 = @("OutDrive", "TempDrive", "PID","PlotoSpawnerJobId", "StartTime", "ArgumentList")
                           $loggerRead = Get-Content ($PlotterBaseLogPath+"\"+$logger.Name) | Select-String -Pattern $pattern2
                           $OutDrive = ($loggerRead -match "OutDrive").line.Split("=").split(";")[1]
                           $tempDrive = ($loggerRead -match "TempDrive").line.Split("=").split(";")[1]
                           $chiaPid = ($loggerRead -match "PID").line.Split(" ")[1]
                           $PlotoSpawnerJobId = ($loggerRead -match "PlotoSpawnerJobId").line.Split(" ")[1]
                           $StartTimeSplitted = ($loggerRead -match "StartTime").line.Split(":")
                           $StartTime = ($StartTimeSplitted[1]+":" + $StartTimeSplitted[2]+":" + $StartTimeSplitted[3]).TrimStart(" ")
                           $ArgumentList = ($loggerRead -match "ArgumentList").line.TrimStart("ArgumentList: ")
                           
                           $StatLogPath = $logger.FullName

                                  
                           $PlotoIdToScramble = $plotId
                           #Scramble temp dir for .tmp files

                           $FileArrToCountSize = Get-ChildItem $TempDrive | ? {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".tmp"} 
                           $SizeOnDisk = "{0:N2} GB" -f (($FileArrToCountSize | measure length -s).Sum /1GB)

                           $FileArrToCountSize = Get-ChildItem $OutDrive | ? {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".plot"} 
                           $SizeOnOutDisk = "{0:N2} GB" -f (($FileArrToCountSize | measure length -s).Sum /1GB)

                           if ($PerfCounter)
                            {
                               if ($StatusReturn -ne "4.3" -or $StatusReturn -ne "Completed")
                                {
                                   Write-Verbose ("PlotoGetJobs @"+(Get-Date)+": Getting Perf counters. This may take a while...")
                                   $p = $((Get-Counter '\Process(*)\ID Process' -ErrorAction SilentlyContinue).CounterSamples | % {[regex]$a = "^.*\($([regex]::Escape($_.InstanceName))(.*)\).*$";[PSCustomObject]@{InstanceName=$_.InstanceName;PID=$_.CookedValue;InstanceId=$a.Matches($($_.Path)).groups[1].value}})
                                   $id = $chiaPID
                                   $p1 = $p | where {$_.PID -eq $id}
                                   $ProcessName = (Get-Process -Id $ProcessPID).Name
                                   $CpuCores = (Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors
                                   $Samples = (Get-Counter -Counter "\Process($($p1.InstanceName+$p1.InstanceId))\% Processor Time").CounterSamples
                                   $cpuout = $Samples | Select `
                                   InstanceName,
                                   @{Name="CPU %";Expression={[Decimal]::Round(($_.CookedValue / $CpuCores), 2)}}
                                   $cpuUsage = $cpuout.'CPU %'
                                   $MemUsage = (Get-WMIObject WIN32_PROCESS | ? {$_.processid -eq $chiapid} | Sort-Object -Property ws -Descending | Select processname,processid, @{Name="Mem Usage(MB)";Expression={[math]::round($_.ws / 1mb)}}).'Mem Usage(MB)'
                                }
                            }
                        }
                }



            #Set certian properties when is Complete
            if ($StatusReturn -eq "4.3")
                {
                    $TimeToComplete = ($status -match "Total time").line.Split("=").Split(" ")[4]
                    $TimeToCompleteCalcInh = ($TimeToComplete / 60) / 60

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
                    OutDrive = $OutDrive
                    PID = $chiaPid
                    PlotSizeOnTempDisk = $SizeOnDisk
                    PlotSizeOnOutDisk = $SizeOnOutDisk
                    ArgumentList = $ArgumentList
                    PlotId = $plotId
                    LogPath = $log.FullName
                    StatLogPath = $StatLogPath
                    CompletionTime = $TimeToCompleteCalcInh
                    }

                }
      


        if ($PerfCounter -and $StatusReturn -eq "Completed")
            {
                
            }
        else
            {
                $collectionWithPlotJobsOut.Add($PlotJobOut) | Out-Null
            }

        $pid= $null
        $StatusReturn = $null
        $tempDrive = $null
        $OutDrive = $null
        $AmountOfThreads = $null
    }


$ErrorActionPreference = "Continue"

$output = $collectionWithPlotJobsOut | sort Status

return $output

}

function Stop-PlotoJob
{
	Param(
		[parameter(Mandatory=$true)]
		$JobId
		)
        $ErrorActionPreference = "Stop"

        $Job = Get-PlotoJobs | ? {$_.JobId -eq $JobId}

        try 
            {
                Stop-Process -id $job.PID
                Write-Host "PlotoStopJob @"(Get-Date)": Stopped chia.exe with PID:" $job.pid -ForegroundColor Green 
            }

        catch
            {
                Write-Host "PlotoStopJob @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Yellow        
            }   



        $PlotoIdToScramble = $job.PlotId
        #Scramble temp dir for .tmp files

        $FileArrToDel = Get-ChildItem $job.TempDrive | ? {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".tmp"} 

        if ($FileArrToDel)
            {
                Write-Host "PlotoStopJob @"(Get-Date)": Found .tmp files for this job to be deleted."
                Write-Host "PlotoStopJob @"(Get-Date)": Sleeping 10 seconds before trying to attempt to delete logs and tmp files..."
                Start-Sleep 10

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

        #Remove logs
        try
            {
                Remove-Item -Path $Job.LogPath
                Remove-Item -Path $Job.StatLogPath
                Write-Host "PlotoStopJob @"(Get-Date)": Removed log files for this job." -ForegroundColor Green     
            }

        catch
            {
               Write-Host "PlotoStopJob @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red 
            }
}

function Remove-AbortedPlotoJobs
{
    $JobsToAbort = Get-PlotoJobs | ? {$_.Status -eq "Aborted"}
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
                    $HasBITSinProgress = Get-BitsTransfer | ? {$_.FileList.RemoteName -eq $plot.Filepath} 

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
                                    $BITSOut = Start-BitsTransfer -Source $source -Destination $DestinationDrive -Description "Moving Plot" -DisplayName "Moving Plot"
                            
                                    while ((Get-BitsTransfer | ? { $_.JobState -eq "Transferring" }).Count -gt 0) {     
                                        $totalbytes=0;    
                                        $bytestransferred=0; 
                                        $timeTaken = 0;    
                                        foreach ($job in (Get-BitsTransfer | ? { $_.JobState -eq "Transferring" } | Sort-Object CreationTime)) {         
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
                    $DestSpaceCheck = get-WmiObject win32_logicaldisk | ? {$_.DeviceID -like "*$DestinationDrive*"}
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

                default {$patterm = "Error"}
            }

$PlotterBaseLogPath = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\log\"
$LogPath= $PlotterBaseLogPath+"debug.log"

$output = Get-content ($LogPath) | Select-String -Pattern $pattern

return $output
}
