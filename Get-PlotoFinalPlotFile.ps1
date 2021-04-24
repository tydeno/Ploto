function Get-PlotoFinalPlotFile
{
	Param(
		[parameter(Mandatory=$true)]
		$OutDriveDenom
		)

#Scan for final Plot Files to Move
$OutDrivesToScan = Get-PlotoOutDrives -OutDriveDenom $OutDriveDenom

$collectionWithFinalPlots= New-Object System.Collections.ArrayList
foreach ($OutDriveToScan in $OutDrivesToScan)
    {
        Write-Host "-------------------------------------------------------------"
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
    
    Write-Host "--------------------------------------------------------------------------------------------------"

    return $collectionWithFinalPlots
}
