function Manage-PlotoMove
{
	Param(
		[parameter(Mandatory=$true)]
		$DestinationDrive,
		[parameter(Mandatory=$true)]
		$OutDriveDenom
		)

    Do
        {
            Move-PlotoPlots -DestinationDrive "J:" -OutDriveDenom "out"
            Start-Sleep 900
        }

    Until ($count -eq $endlessCount)
}
