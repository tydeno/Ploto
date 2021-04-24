function Get-PlotoFinalPlotFile
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
