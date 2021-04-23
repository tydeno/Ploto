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
