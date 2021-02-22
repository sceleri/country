param (
	# Playlist URL
	[Parameter(Mandatory=$true,
	Position=0)]
	[Alias("c", "pl", "playlist", "list")]
	[String[]]
	$Country,

	# Country download path
	[Parameter(Mandatory=$false)]
	[Alias("p", "path", "output", "o")]
	[String[]]
	$Countryroad="country",

	# Path to extracted playlist and other files that the script uses
	[Parameter(Mandatory=$false)]
	[Alias("m", "meta")]
	[String[]]
	$Metafiles=".\script_files",

	# Skip playing after download
	[Parameter(Mandatory=$false)]
	[Alias("n","np", "no")]
	[Switch]
	$noplay,

	# Skip fetching playlist
	# Really only useful for development
	[Parameter(Mandatory=$false)]
	[Alias("sl","nolist", "slist")]
	[Switch]
	$skiplist,

	[Parameter(Mandatory=$false)]
	[Alias("s", "mute", "shutup", "shut", "fuckoff")]
	[Switch]
	$silent,
	
	# Use --flat-playlist (speeds up YouTube playlist processing)
	# Does not work for Soundcloud :/
	# Does not work at all rn
	# TODO: Make-URL (youtu.be/$song.Id) when using -yt
	[Parameter(Mandatory=$false)]
	[Alias("f", "yt")]
	[Switch]
	$flat

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
	Write-Host "Playing #Country" -ForegroundColor Green
	& 'C:\Program Files (x86)\foobar2000\foobar2000.exe' $Countryroad '/runcmd=Playback/Order/Random'
}

function Make-List {
	Write-Host "Fetching playlist" -ForegroundColor Blue
	$output = "[%(id)s] %(uploader)s - %(title)s"
	if($flat.IsPresent) {
		youtube-dl -i --flat-playlist --get-title --get-id --get-filename -o $output --get-url $Country | Out-File "$($Metafiles)\list.txt" -Encoding oem
	} else {
		youtube-dl -i --get-title --get-id --get-filename -o $output --get-url $Country | Out-File "$($Metafiles)\list.txt" -Encoding oem
	}
}
function Get-List-Array {
	$array = Get-Content "$($Metafiles)\list.txt" -Raw
	$array = $array -split "`r?`n" 
	return $array
}

function Song-Downloaded($song) {
	$songpath = "$($Countryroad)" + '\*' + '``[' + "$($song.Id)" + '``]' + '*.*'
	Log-Message("We do a little trolling: ?$($song.Id)?")
	return Test-Path $songpath
}

function Download-Song($song) {
	Log-Message("Downloading $($song.Title)")
	$output = "$($Countryroad)\$($song.Filename).%(ext)s"
	$format = "bestaudio"
	$quiet = "--quiet"
	if(-Not $silent.IsPresent) {
		$quiet = ""
	}
	# Call youtube-dl
	youtube-dl `
		-o $output `
		--download-archive "$($Metafiles)\downloaded.txt" `
		--extract-audio `
		--ignore-config `
		--ignore-errors `
		$quiet `
		$song.Url
}

function Log-Message($message) {

	if(-Not $silent.IsPresent) {
		Write-Host $message 
	}
}

function Country {
	
	# Make script_files directory and downloaded.txt if missing
	if(!(Test-Path $Metafiles)) {
		New-Item -Path . -Name "$($Metafiles)\" -ItemType "directory"
	}

	if(!(Test-Path "$($Metafiles)\downloaded.txt")) {
		New-Item -Path "$($Metafiles)\" -Name "downloaded.txt" -ItemType "file"
	}

	# Skip making list if the -skiplist switch is present
	if(-Not $skiplist.IsPresent) {
		Make-List
	}
	
	# Get the list from file
	$array = Get-List-Array

	# Check if youtube-dl extracted one or two urls
	if ($array[3].SubString(0,4) -ne "http") {
		Write-Host "Extracting from audio only source" -ForegroundColor Blue
		$increment = 4
	} else {
		Write-Host "Extracting from video + audio source" -ForegroundColor Blue
		$increment = 5
	}

	# Process all songs in the list array
	# $array.Length - 1 because Get-Content -Raw gets the last newline 
	for ($i = 0; $i -lt ($array.Length - 1); ($i = $i + $increment)) {
		$song = [Song]::new()
		$song.Title = $array[$i]
		$song.Id = $array[$i + 1]
		$song.Url = $array[$i + $increment - 2]

		# Remove brackets from song names smh
		$foilname = $array[$i + $increment - 1]
		$foilname = $foilname -replace '[\(|\)|\%]'
		$song.Filename = $foilname

		Write-Host "Processing: [$($song.Id)]" -ForegroundColor Magenta
		
		if(Song-Downloaded($song)) {
			Write-Host "$($song.Title) is downloaded" -ForegroundColor DarkGreen
		} else {
			Write-Host "$($song.Title) is not downloaded" -ForegroundColor Red
			Download-Song($song)
		}
	}

	# Finish
	Write-Host "All songs downloaded" -ForegroundColor Green
	
	# Play if -np is not present
	if(-Not $noplay.IsPresent) {
		Play-List
	}
}

Country