<#
.SYNOPSIS
Name: Ploto
Version: 1.0
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

                $ChiaBasePath = "$env:LOCALAPPDATA\chia-blockchain"
                $ChiaVersion = ((Get-ChildItem $ChiaBasePath | ? {$_.Name -like "*app*"}).Name.Split("-"))[1]
                $PathToChia = $ChiaBasePath+"\app-"+$ChiaVersion+"\resources\app.asar.unpacked\daemon\chia.exe" 
                $PlotterBaseLogPath = $env:HOMEDRIVE+$env:HOMEPath+"\.chia\mainnet\plotter\"
                $LogNameBasePath = "PlotoSpawnerLog_"+((Get-Date).Day.ToString())+"_"+(Get-Date).Month.ToString()+"_"+(Get-Date).Hour.ToString()+"_"+(Get-Date).Minute.ToString()+"_Tmp-"+(($PlottableTempDrive).DriveLetter.Split(":"))[0]+"_Out-"+($OutDriveLetter.Split(":"))[0]+".txt"
                $LogPath = $PlotterBaseLogPath+$LogNameBasePath
       

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
                                        $chiaexe = Start-Process $PathToChia -ArgumentList $ArgumentList -RedirectStandardOutput $LogPath -PassThru
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
    Param(
        [parameter(Mandatory=$true)]
	    $LogPath
        )


$LogJob = Start-Job -ScriptBlock {
        Get-Content $input -Tail 1 -Wait 
    } -InputObject $LogPath -Name PlotoLogGrabber

$LogStat = Receive-Job -Job $LogJob
}
