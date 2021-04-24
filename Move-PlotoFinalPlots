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


function Get-FinalPlotFile
{

#Scan for final Plot Files to Move
$OutDrivesToScan = Get-PlotoOutDrives

$collectionWithFinalPlots= New-Object System.Collections.ArrayList
foreach ($OutDriveToScan in $OutDrivesToScan)
    {
        Write-Host "-------------------------------------"
        Write-Host "Iterating trough Drive:"
        Write-Host $OutDriveToScan

        $ItemsInDrive = Get-ChildItem $OutDriveToScan.DriveLetter
        Write-Host "Checking if any item in that drive contains .PLOT as file ending..."

        foreach ($item in $ItemsInDrive)
        {
            If ($item.Extension -eq ".PLOT")
                {
                    Write-Host "Found a Final plot!"
                    
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
                    Write-Host "This is no plot."
                }
        }
    }
    
    Write-Host "---------------------------------------------------"
    Write-Host "Found the following Plots that are moveable:"

    return $collectionWithFinalPlots
}
