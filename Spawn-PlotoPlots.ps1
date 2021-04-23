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
