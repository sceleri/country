param (
	# Playlist URL
	[Parameter(Mandatory=$false,
	ParameterSetName="Country")]
	[String[]]
	$Country="https://www.youtube.com/playlist?list=PL5hpscggGRw1K32H0OLA1j65Xb-TLPgD_",

	# Switch to not play after download
	[Parameter(Mandatory=$false)]
	[Switch]
	$noplay

)

$list = "script_files\list.txt"
$countryroad = ".\country\"

class Song {
	[string]$Id
	[string]$Title
		
	[string]ToString(){
        return ("{0} | {1}" -f $this.Id, $this.Title)
    }

}
function Play-List {
	Write-Host "All songs downloaded" -ForegroundColor Green
	Write-Host "#Country" -ForegroundColor White
	& 'C:\Program Files (x86)\foobar2000\foobar2000.exe' 'A:\Music\country\' '/runcmd=Playback/Order/Random'
}

function Make-List {
	Write-Host "Fetching playlist" -ForegroundColor Green
	youtube-dl -i --flat-playlist --get-title --get-id --restrict-filenames $country > $list
}
function Get-List-Array {
	$array = Get-Content $list
	$array = $array -split "`r?`n" 
	return $array
}

function Song-Downloaded($song) {
	$path = $countryroad + "*" + '``[' + $song.Id + '``]' + "*.*"
	return Test-Path -Path -- $path
}

function Download-Song($song) {
	Write-Host "Downloading $($song.Title)" -ForegroundColor Yellow
	youtube-dl --config-location "script_files\config.txt" "https://youtu.be/$($song.Id)"
}

function Remove-Removed-Songs {
	Write-Host "Remove removed songs not implemented" -ForegroundColor Red
}

function Country {
	
	Make-List
	
	$array = Get-List-Array

	for ($i = 0; $i -lt ($array.Length); ($i = $i + 2)) {
		$s = [Song]::new()
		$s.Title = $array[$i]
		$s.Id = $Array[$i + 1]
		
		if(Song-Downloaded($s)) {
			Write-Host "$s is downloaded" -ForegroundColor DarkGreen
		} else {
			Write-Host "$s is not downloaded" -ForegroundColor Red
			Download-Song($s)
		}
	}

	Remove-Removed-Songs
	
	if(-Not $noplay.IsPresent) {
		Play-List
	}
}

Country