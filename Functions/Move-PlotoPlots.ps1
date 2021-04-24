function Move-PlotoPlots
{
	Param(
		[parameter(Mandatory=$true)]
		$DestinationDrive,
		[parameter(Mandatory=$true)]
		$OutDriveDenom,
	    $SendSMSNotification,
        $AccountSid,
        $AuthToken,
        $from,
        $to
		)

$PlotsToMove = Get-PlotoFinalPlotFile -OutDriveDenom $OutDriveDenom

if ($PlotsToMove)
    {
        Write-Host "PlotoMover @"(Get-Date)": There are Plots found to be moved: "$PlotsToMove
         
        foreach ($plot in $PlotsToMove)
        {
            #Check if Destination drive has enough capacity for file to move
            $DestinationLogicalDisk = get-WmiObject win32_logicaldisk | ? {$_.DeviceID -eq $DestinationDrive}
            $DestinationDriveFreeSpace = [math]::Round($DestinationLogicalDisk.FreeSpace  / 1073741824, 2)

            if ($DestinationDriveFreeSpace -gt $plot.Size)
                {
                   Write-Host "PlotoMover @"(Get-Date)": Destination Drive has enough Space:"$DestinationLogicalDisk.DeviceID "available space on Disk: "$DestinationDriveFreeSpace -ForegroundColor Green

                   #Move Item using BITS
                   try
                        {
                            Write-Host "PlotoMover @"(Get-Date)": Moving plot: "$plot.FilePath "to" $DestinationDrive
                            $BITSOut = Start-BitsTransfer -Source $plot.FilePath -Destination $DestinationDrive -Description "Moving Plot" -DisplayName "Moving Plot"
                            $TwilioMessage = "A plot Has been moved and is ready for transfer: "+$plot 
                            $BadErrorNotification = Send-SMS -AccountSid $AccountSid -AuthToken $AuthToken -Message $TwilioMessage -from $from -to $to
                        }

                    catch
                        {
                            Write-Output "PlotoMover @"(Get-Date)": BITS Transfer failed!" -ForegroundColor Red
                        }

                } 
            else
                {
        
                   Write-Host "PlotoMover @"(Get-Date)": Not enough space on destination drive:"$DestinationLogicalDisk.DeviceID "available space on Disk: "$DestinationDriveFreeSpace -ForegroundColor Red
                   if ($SendSMSNotification -eq $true) 
                    {
                        $TwilioMessage = "A plot to move has been found, but Destination Disk has no space. Make free space on Disk:"+$DestinationDrive 
                        $BadErrorNotification = Send-SMS -AccountSid $AccountSid -AuthToken $AuthToken -Message $TwilioMessage -from $from -to $to
                    }
                }
        }
    }

else
    {
        Write-Host "PlotoMover @"(Get-Date)": No Final plots found." 
    }

}
