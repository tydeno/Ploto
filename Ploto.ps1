function Get-PlotoOutDrives
{

$tmpDrives = get-WmiObject win32_logicaldisk | ? {$_.VolumeName -like "*plot*"}
$outDrives = get-WmiObject win32_logicaldisk | ? {$_.VolumeName -like "*out*"}

#Check Space for outDrives
$collectionWithDisks= New-Object System.Collections.ArrayList
foreach ($drive in $outDrives)
    {
  
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
        IsPlottable    = $PlotToDest
        AmountOfPlotsToHold = [math]::Floor(($FreeSpace / 100))
        }

        $collectionWithDisks.Add($outdriveToPass) | Out-Null

    }
    return $collectionWithDisks 
}


function Get-PlotoTempDrives
{

$tmpDrives = get-WmiObject win32_logicaldisk | ? {$_.VolumeName -like "*plot*"}

#Check Space for outDrives
$collectionWithDisks= New-Object System.Collections.ArrayList
foreach ($tmpDrive in $tmpDrives)
    {
  
        $FreeSpace = [math]::Round($tmpDrive.FreeSpace  / 1073741824, 2)
        If ($FreeSpace -gt 270)
            {
                $ChildItemsOfDrive = Get-ChildItem $tmpDrive.DeviceID

                if ($ChildItemsOfDrive)
                    {
                        $IsPlottable = $false
                        $HasPlotInProgress = $true
                    }
                else
                    {
                        $IsPlottable = $true
                        $HasPlotInProgress = $false
                    }
            }
        else
            {
                $IsPlottable = $false
                $HasPlotInProgress = "Likely"
            }

        $driveToPass = [PSCustomObject]@{
        DriveLetter     =  $tmpDrive.DeviceID
        ChiaDriveType = "Temp"
        VolumeName = $tmpDrive.VolumeName
        FreeSpace = $FreeSpace
        IsPlottable    = $IsPlottable
        AmountOfPlotsToTemp = [math]::Floor(($FreeSpace / 270))
        HasPlotInProgress = $HasPlotInProgress
        }

        $collectionWithDisks.Add($driveToPass) | Out-Null

    }
    return $collectionWithDisks 
}


function Spawn-PlotoPlots
{

Write-Host "Checking for available temp and out drives..."
Write-Host " "

$PlottableTempDrives = Get-PlotoTempDrives | ? {$_.IsPlottable -eq $true}   
$PlottableOutDrives = Get-PlotoOutDrives | ? {$_.IsPlottable -eq $true}

$collectionWithPlotJobs= New-Object System.Collections.ArrayList
foreach ($PlottableTempDrive in $PlottableTempDrives)
    {
        Write-Host "Found available temp drive:"
        Write-Host $PlottableTempDrive
        Write-Host " "

        #Choose most suitable OutDrive (assumed the one with most space)
        $max = ($PlottableOutDrives | measure-object -Property FreeSpace -maximum).maximum
        $OutDrive = $PlottableOutDrives | ? { $_.FreeSpace -eq $max}
        $OutDriveLetter = $OutDrive.DriveLetter

        Write-Host "Found most suitable Out Drive:"
        Write-Host $OutDrive
        Write-Host " "
        
        #stitch together ArgumentsList for chia.exe
        $ArgumentList = "plots create -k 32 -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -e"

        Write-Host "Using the following Arguments for Chia.exe:"
        Write-Host $ArgumentList
        Write-Host " "

        $PathToChia = "$env:LOCALAPPDATA\chia-blockchain\app-1.1.1\resources\app.asar.unpacked\daemon\"

        Write-Host "Using the following Path to chia.exe:"
        Write-Host $PathToChia
        Write-Host " "
       
        $LogPath = "$env:LOCALAPPDATA\chia-blockchain\log01.log"
        Write-Host "Starting plotting using chia.exe. Host is redirected to:"
        Write-Host $LogPath
        Write-Host " "
            
        #Fire off chia
        cd $PathToChia
        Start-Process .\chia.exe -ArgumentList $ArgumentList

        #Deduct 106GB from OutDrive Capacity in Var
        $DeductionOutDrive = ($OutDrive.FreeSpace - 106)
        $OutDrive.FreeSpace="$DeductionOutDrive"

        Write-Host "Deducted 106 GB from OutDrive for next Iteration. Sadly cant change AmountOfPlotsToHold.."
        Write-Host "_________________________________________________________________________________________"
        Start-Sleep 1800

        #Getting Host Object Ready
        $PlotJob = [PSCustomObject]@{
        OutDrive     =  $OutDriveLetter
        TempDrive = $PlottableTempDrive.DriveLetter
        StartTime = (Get-Date)
        }

        $collectionWithPlotJobs.Add($PlotJob) | Out-Null
    }

   Write-Host "Exiting spawn function."

   return $collectionWithPlotJobs
}

function Manage-PlotoSpawns
{
    $InputAmountToSpawn = 12
    $SpawnedCount = 0

    Do
    {
        Write-Host "Initiating Spawning..."
 
        $SpawnedPlots = Spawn-PlotoPlots
        $SpawnedCount + $SpawnedPlots.Count | Out-Null
        Write-Host "Amount of spawned Plots in this iteration: " $SpawnedPlots.Count
        Write-Host "Overall spawned Plots since start of script: "$SpawnedCount
        

        Write-Host "Entering Sleep for 3600, then checking again for available temp and out drives"
        Start-Sleep 3600
    }
    
    Until ($SpawnedCount -ne $InputAmountToSpawn)
}

Manage-PlotoSpawns
