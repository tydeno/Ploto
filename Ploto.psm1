<#
.SYNOPSIS
Name: Ploto
Version: 1.0.1
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
        $DiskSize = [math]::Round($tmpDrive.Size  / 1073741824, 2)
        $FreeSpace = [math]::Round($tmpDrive.FreeSpace  / 1073741824, 2)
        $TempPlotFiles = Get-ChildItem $tmpDrive.DeviceID | ? {$_.Extension -eq ".tmp"}

        If ($FreeSpace -gt 290)
            {

                if ($TempPlotFiles)
                    {
                        $HasPlotInProgress = $true
                        $PlotInProgressName = ((($TempPlotFiles)[0].Name).Split("."))[0]

                        #Get Amount of Plot Jobs on Disk. Alist of files. If more than 1 file with other name within same notation, more than pigress.
                        $baseNotation = "plot-k32-"

                        $ErrorActionPreference = “silentlycontinue”

                        $collectionWithJobs= New-Object System.Collections.ArrayList
                        $Job1 = ($eqbase = Get-ChildItem $tmpDrive.DeviceID | ? {$_.Name -like "*$baseNotation*"})[0].Name.Split(".")[0] 
                        if ($job1) {$collectionWithJobs.Add($Job1) | Out-Null}

                        $Job2 = (($eqbase | ? {$_.Name -notlike "*$Job1*"})[0]).Name.Split(".")[0]
                        if ($job2) {$collectionWithJobs.Add($Job2) | Out-Null}

                        $Job3 = (($eqbase | ? {$_.Name -notlike "*$Job1*" -and $_.Name -notlike "*$Job2*"})[0]).Name.Split(".")[0] 
                        if ($job3) {$collectionWithJobs.Add($Job3) | Out-Null}

                        $Job4 = (($eqbase | ? {$_.Name -notlike "*$Job1*" -and $_.Name -notlike "*$Job2*" -and $_.Name -notlike "*$Job3*"})[0]).Name.Split(".")[0]
                        if ($job4) {$collectionWithJobs.Add($Job4) | Out-Null}

                        $Job5 = (($eqbase | ? {$_.Name -notlike "*$Job1*" -and $_.Name -notlike "*$Job2*" -and $_.Name -notlike "*$Job3*" -and $_.Name -notlike "*$Job4*"})[0]).Name.Split(".")[0]
                        if ($job5) {$collectionWithJobs.Add($Job5) | Out-Null}

                        $AmountofPlotsInProgress = $collectionWithJobs.Count

                        $AmountOfPlotsToTempMax = ([math]::Floor(($FreeSpace / 290))) - $AmountofPlotsInProgress
                        $ErrorActionPreference = "continue"

                        if ($AmountOfPlotsToTempMax -gt 0)
                            {
                                $IsPlottable = $true
                            }
                        else
                            {
                                $IsPlottable = $false
                            }

                    }
                else
                    {
                        $IsPlottable = $true
                        $HasPlotInProgress = $false
                        $PlotInProgressName = "No plot in progress"
                        $AmountOfPlotsToTempMax = [math]::Floor(($FreeSpace / 290))

                    }
            }
        else
            {
                if ($TempPlotFiles)
                    {

                        $PlotInProgressName = ((($TempPlotFiles)[0].Name).Split("."))[0]
                        $HasPlotInProgress = $true
                        $IsPlottable = $false
                        $AmountOfPlotsToTempMax = 0
                        
                    }
                else
                    {
                        $PlotInProgressName = "No plot in progress"
                        $HasPlotInProgress = $false
                        $IsPlottable = $false
                        $AmountOfPlotsToTempMax = 0
                    }
           
            }

        $driveToPass = [PSCustomObject]@{
        DriveLetter     =  $tmpDrive.DeviceID
        ChiaDriveType = "Temp"
        VolumeName = $tmpDrive.VolumeName
        FreeSpace = $FreeSpace
        TotalSpace = $DiskSize
        IsPlottable    = $IsPlottable
        AmountOfPlotsToTempMax = $AmountOfPlotsToTempMax
        HasPlotInProgress = $HasPlotInProgress
        AmountOfPlotsInProgress =  $AmountOfPlotsInProgress
        PlotInProgressName = $collectionWithJobs
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
	    [parameter(Mandatory=$true)]
	    $WaitTimeBetweenPlotOnSameDisk,
        $EnableBitfield,
        $ParallelAmount
		)

$PlottableTempDrives = Get-PlotoTempDrives -TempDriveDenom $TempDriveDenom | ? {$_.IsPlottable -eq $true}   
$PlottableOutDrives = Get-PlotoOutDrives -OutDriveDenom $OutDriveDenom | ? {$_.IsPlottable -eq $true}

$collectionWithPlotJobs= New-Object System.Collections.ArrayList


if ($PlottableTempDrives)
    {
         foreach ($PlottableTempDrive in $PlottableTempDrives)
            {

                $max = ($PlottableOutDrives | measure-object -Property FreeSpace -maximum).maximum
                $OutDrive = $PlottableOutDrives | ? { $_.FreeSpace -eq $max}
                $OutDriveLetter = $OutDrive.DriveLetter

                $PlotoSpawnerJobId = ([guid]::NewGuid()).Guid
                $ChiaBasePath = "$env:LOCALAPPDATA\chia-blockchain"
                $ChiaVersion = ((Get-ChildItem $ChiaBasePath | ? {$_.Name -like "*app*"}).Name.Split("-"))[1]
                $PathToChia = $ChiaBasePath+"\app-"+$ChiaVersion+"\resources\app.asar.unpacked\daemon\chia.exe" 
                $PlotterBaseLogPath = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\plotter\"
                $LogNameBasePath = "PlotoSpawnerLog_"+((Get-Date).Day.ToString())+"_"+(Get-Date).Month.ToString()+"_"+(Get-Date).Hour.ToString()+"_"+(Get-Date).Minute.ToString()+"_"+$PlotoSpawnerJobId+"_Tmp-"+(($PlottableTempDrive).DriveLetter.Split(":"))[0]+"_Out-"+($OutDriveLetter.Split(":"))[0]+".txt"
                $LogPath= $PlotterBaseLogPath+$LogNameBasePath

                $logstatName = "PlotoSpawnerLog_"+((Get-Date).Day.ToString())+"_"+(Get-Date).Month.ToString()+"_"+(Get-Date).Hour.ToString()+"_"+(Get-Date).Minute.ToString()+"_"+$PlotoSpawnerJobId+"_Tmp-"+(($PlottableTempDrive).DriveLetter.Split(":"))[0]+"_Out-"+($OutDriveLetter.Split(":"))[0]+"@Stat.txt"

                $logPath1 = (New-Item -Path $PlotterBaseLogPath -Name $logstatName).FullName
                Add-Content -Path $LogPath1 -Value "PlotoSpawnerJobId: $PlotoSpawnerJobId"
                Add-Content -Path $LogPath1 -Value "OutDrive: $OutDrive"
                Add-Content -Path $LogPath1 -Value "TempDrive: $PlottableTempDrive"

                if ($EnableBitfield -eq $true -or $EnableBitfield -eq "yes")
                    {
                        $ArgumentList = "plots create -k 32 -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\"
                    }

                else
                    {
                        $ArgumentList = "plots create -k 32 -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -e"
                    }


                if ($ParallelAmount -eq "max" -and $PlottableTempDrive.AmountOfPlotsToTemp -gt 1)
                    {
                        $count = 0
                        do
                            {
                                $max = ($PlottableOutDrives | measure-object -Property FreeSpace -maximum).maximum
                                $OutDrive = $PlottableOutDrives | ? { $_.FreeSpace -eq $max}
                                $OutDriveLetter = $OutDrive.DriveLetter

                                if ($EnableBitfield -eq $true -or $EnableBitfield -eq "yes")
                                    {
                                        $ArgumentList = "plots create -k 32 -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\"
                                    }

                                else
                                    {
                                        $ArgumentList = "plots create -k 32 -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -e"
                                    }

                                try 
                                    {
                                        $chiaexe = Start-Process $PathToChia -ArgumentList $ArgumentList -RedirectStandardOutput $logPath -PassThru
                                        $pid = $chiaexe.Id
                                        Add-Content -Path $LogPath1 -Value "PID: $pid" -Force
                                    }
                                catch
                                    {
                                        Write-Host "PlotoMover @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
                                        Write-Host "PlotoSpawner @"(Get-Date)": ERROR! Could not launch chia.exe. Chia Version tried to launch: $ChiaVersion. Check chiapath and arguments (make sure there is only latest installed chia version folder, eg app-1.1.2). Arguments used:"$ArgumentList -ForegroundColor Red
                                    }

                                $count++
                                Start-Sleep ($WaitTimeBetweenPlotOnSameDisk*60)
                            }

                        until ($count -eq $PlottableTempDrive.AmountOfPlotsToTemp)
                        
                    }

                try 
                    {
                        $chiaexe = Start-Process $PathToChia -ArgumentList $ArgumentList -RedirectStandardOutput $LogPath -PassThru
                        $pid = $chiaexe.Id
                        Add-Content -Path $LogPath1 -Value "PID: $pid" -Force
                    }

                catch
                    {
                        Write-Host "PlotoSpawner @"(Get-Date)": ERROR! Could not launch chia.exe. Check chiapath and arguments (make sure version is set correctly!). Arguments used: "$ArgumentList -ForegroundColor Red
                        Write-Host "PlotoSpawner @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
                    }


                #Deduct 106GB from OutDrive Capacity in Var
                $DeductionOutDrive = ($OutDrive.FreeSpace - 106)
                $OutDrive.FreeSpace="$DeductionOutDrive"

                #Getting Plot Object Ready
                $PlotJob = [PSCustomObject]@{
                PlotoSpawnerJobId = $PlotoSpawnerJobId
                ProcessID = $chiaexe.Id
                OutDrive     =  $OutDriveLetter
                TempDrive = $PlottableTempDrive.DriveLetter
                ArgumentsList = $ArgumentList
                ChiaVersionUsed = $ChiaVersion
                LogPath = $LogPath
                StartTime = (Get-Date)
                }

                $collectionWithPlotJobs.Add($PlotJob) | Out-Null

                Write-Host "PlotoSpawner @"(Get-Date)": Spawned the following plot Job:" -ForegroundColor Green
                $PlotJob | Out-Host

                Start-Sleep ($WaitTimeBetweenPlotOnSeparateDisks*60)
            }
    }

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
	[parameter(Mandatory=$true)]
	$WaitTimeBetweenPlotOnSameDisk,
	[parameter(Mandatory=$true)]
	$TempDriveDenom,
    $EnableBitfield,
    $ParallelAmount
    )

    $SpawnedCount = 0

    Do
    {
        $SpawnedPlots = Invoke-PlotoJob -OutDriveDenom $OutDriveDenom -TempDriveDenom $TempDriveDenom -EnableBitfield $EnableBitfield -ParallelAmount $ParallelAmount -WaitTimeBetweenPlotOnSeparateDisks $WaitTimeBetweenPlotOnSeparateDisks -WaitTimeBetweenPlotOnSameDisk $WaitTimeBetweenPlotOnSameDisk
        

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

function Get-PlotoJobs
{
$PlotterBaseLogPath = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\plotter\"
$logs = Get-ChildItem $PlotterBaseLogPath | ? {$_.Name -notlike "*@Stat*"}
$pattern = @("OutDrive", "TempDrive", "Starting plotting progress into temporary dirs:", "ID", "F1 complete, time","Starting phase 1/4", "Computing table 1","Computing table 2", "Computing table 3","Computing table 4","Computing table 5","Computing table 6","Computing table 7", "Starting phase 2/4", "Time for phase 1","Backpropagating on table 7", "Backpropagating on table 6", "Backpropagating on table 5", "Backpropagating on table 4", "Backpropagating on table 3", "Backpropagating on table 2", "Starting phase 3/4", "Compressing tables 1 and 2", "Compressing tables 2 and 3", "Compressing tables 3 and 4", "Compressing tables 4 and 5", "Compressing tables 5 and 6", "Compressing tables 6 and 7")

$collectionWithPlotJobsOut = New-Object System.Collections.ArrayList

foreach ($log in $logs)
    {        
        $status = get-content ($PlotterBaseLogPath+"\"+$log.name) | Select-String -Pattern $pattern
        $CurrentStatus = $status[($status.count-1)]
        $ErrorActionPreference = "SilentlyContinue"

        $PlotId = ($status -match "ID:").line.split(" ")[1]

        switch -Wildcard ($CurrentStatus)
            {
                "Starting plotting progress into temporary dirs:*" {$StatusReturn = "Initializing"}
                "Starting phase 1/4*" {$StatusReturn = "1:0"}
                "F1 complete, time*" {$StatusReturn = "1:1"}
                "Computing table 1" {$StatusReturn = "1:1"}
                "Computing table 2" {$StatusReturn = "1:1"}
                "Computing table 3" {$StatusReturn = "1:2"}
                "Computing table 4" {$StatusReturn = "1:3"}
                "Computing table 5" {$StatusReturn = "1:4"}
                "Computing table 6" {$StatusReturn = "1:5"}
                "Computing table 7" {$StatusReturn = "1:6"}
                "Starting phase 2/4*" {$StatusReturn = "2:0"}
                "Backpropagating on table 7" {$StatusReturn = "2:1"}
                "Backpropagating on table 6" {$StatusReturn = "2:2"}
                "Backpropagating on table 5" {$StatusReturn = "2:3"}
                "Backpropagating on table 4" {$StatusReturn = "2:4"}
                "Backpropagating on table 3" {$StatusReturn = "2:5"}
                "Backpropagating on table 2" {$StatusReturn = "2:6"}
                "Starting phase 3/4*" {$StatusReturn = "3:0"}
                "Compressing tables 1 and 2" {$StatusReturn = "3:1"}
                "Compressing tables 2 and 3" {$StatusReturn = "3:2"}
                "Compressing tables 3 and 4" {$StatusReturn = "3:3"}
                "Compressing tables 4 and 5" {$StatusReturn = "3:4"}
                "Compressing tables 5 and 6" {$StatusReturn = "3:5"}
                "Compressing tables 6 and 7" {$StatusReturn = "3:6"}
                default {$StatusReturn = "Could not fetch Status"}
            }


            $Logstatfiles = Get-ChildItem $PlotterBaseLogPath | ? {$_.Name -like "*@Stat*"}

            foreach ($logger in $Logstatfiles)
                {
                    $SearchStat = ($logger.name).split("@")[0]
                    $SearchChia = ($log.name).split(".")[0]

                    if ($SearchStat -eq $SearchChia)
                        {
                           $pattern2 = @("OutDrive", "TempDrive", "PID","PlotoSpawnerJobId")
                           $loggerRead = Get-Content ($PlotterBaseLogPath+"\"+$logger.Name) | Select-String -Pattern $pattern2
                           $OutDrive = ($loggerRead -match "OutDrive").line.Split("=").split(";")[1]
                           $tempDrive = ($loggerRead -match "TempDrive").line.Split("=").split(";")[1]
                           $Pid = ($loggerRead -match "PID").line.Split(" ")[1]
                           $PlotoSpawnerJobId = ($loggerRead -match "PlotoSpawnerJobId").line.Split(" ")[1]
                        }
                }
                
            #Getting Plot Object Ready
            $PlotJobOut = [PSCustomObject]@{
            PlotoSpawnerJobId = $PlotoSpawnerJobId
            PlotId = $plotId
            PID = $Pid
            PlotJobStatus = $StatusReturn
            TempDrive = $tempDrive
            OutDrive = $OutDrive
            LogPath = $log.name
            }

        $collectionWithPlotJobsOut.Add($PlotJobOut) | Out-Null
        $plotId = $null
        $StatusReturn = $null
        $tempDrive = $null
        $OutDrive = $null
    }

$ErrorActionPreference = "Continue"

return $collectionWithPlotJobsOut

}

function Stop-PlotoJob
{
	Param(
		[parameter(Mandatory=$true)]
		$PlotoSpawnerJobId
		)

        $Job = Get-PlotoJobs | ? {$_.PlotoSpawnerJobId -eq $PlotoSpawnerJobId}

        try 
            {
                Stop-Process -id $job.PID
            }

        catch
            {
                Write-Host "PlotoStopJob @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red        
            }   

        $PlotoIdToScramble = $job.PlotId
        #Scramble temp dir for .tmp files

        $FileArrToDel = Get-ChildItem $job.TempDrive | ? {$_.Name -like "*$PlotoIdToScramble*" -and $_.Extension -eq ".tmp"} 

        if ($FileArrToDel)
            {
                try 
                    {
                         $FileArrToDel | Remove-Item -Force
                    }

                catch
                    {
                        Write-Host "PlotoStopJob @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red   
                    }               
            }        
}
