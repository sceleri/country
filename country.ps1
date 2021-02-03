param (
	# Playlist URL
	[Parameter(Mandatory=$true,
	ParameterSetName="Country")]
	[String[]]
	$Country,

	# Country download path
	[Parameter(Mandatory=$false)]
	[String[]]
	$Countryroad="country",

	# Path to extracted playlist
	[Parameter(Mandatory=$false)]
	[String[]]
	$List="script_files\list.txt",

	# Path to list of downloaded songs
	[Parameter(Mandatory=$false)]
	[String[]]
	$Downloaded="script_files\downloaded.txt",

	# Switch to not play after download
	[Parameter(Mandatory=$false)]
	[Switch]
	$noplay,

	# Skip fetching playlist
	[Parameter(Mandatory=$false)]
	[Switch]
	$skiplist

)

class Song {
	[string]$Id
	[string]$Title
	[string]$Url
	[string]$Filename
	
	[string]ToString(){
        return ("{0} | {1}" -f $this.Id, $this.Title)
    }

}

function Play-List {
	Write-Host "All songs downloaded" -ForegroundColor Green
	Write-Host "Playing #Country" -ForegroundColor White
	& 'C:\Program Files (x86)\foobar2000\foobar2000.exe' $Countryroad '/runcmd=Playback/Order/Random'
}

function Make-List {
	Write-Host "Fetching playlist" -ForegroundColor Blue
	$output = "[%(id)s] %(uploader)s - %(title)s"
	youtube-dl -i --get-title --get-id --get-filename -o $output --get-url $Country > $list
}
function Get-List-Array {
	$array = Get-Content $list
	$array = $array -split "`r?`n" 
	return $array
}

function Song-Downloaded($song) {
	$songpath = "$($Countryroad)" + '\*' + '``[' + "$($song.Id)" + '``]' + '*.*'
	Write-Host "We do a little trolling $($songpath)" -ForegroundColor Cyan
	return Test-Path $songpath
}

function Download-Song($song) {
	Write-Host "Downloading $($song.Title)" -ForegroundColor Yellow
	$output = "$($Countryroad)\$($song.Filename).%(ext)s"
	youtube-dl -o $output --download-archive $Downloaded `
		--extract-audio --ignore-config --ignore-errors `
		$song.Url
}

function Remove-Removed-Songs {
	Write-Host "Remove removed songs not implemented" -ForegroundColor Red
}

function Country {
	
	if(-Not $skiplist.IsPresent) {
		Make-List
	}
	
	$array = Get-List-Array

	# Check if youtube-dl extracted one or two urls
	if ($array[3].SubString(0,4) -ne "http") {
		Write-Host "Extracting from audio only source" -ForegroundColor Blue
		$increment = 4
	} else {
		Write-Host "Extracting from video + audio source" -ForegroundColor Blue
		$increment = 5
	}

	for ($i = 0; $i -lt ($array.Length); ($i = $i + $increment)) {
		$song = [Song]::new()
		$song.Title = $array[$i]
		$song.Id = $array[$i + 1]
		$song.Url = $array[$i + $increment - 2]
		$song.Filename = $array[$i + $increment - 1]

		Write-Host "Processing: $($song.Filename)" -ForegroundColor Magenta
		
		if(Song-Downloaded($song)) {
			Write-Host "$song is downloaded" -ForegroundColor DarkGreen
		} else {
			Write-Host "$song is not downloaded" -ForegroundColor Red
			Download-Song($song)
		}
	}

	Remove-Removed-Songs
	
	if(-Not $noplay.IsPresent) {
		Play-List
	}
}

Country