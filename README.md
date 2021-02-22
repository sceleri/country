# country
#Country

# Usage

    .\country.ps1 [switches] [|-c|-Country] https://country.co/country

# Switches
```
  -Country <url>        Playlist to download.

  -Countryroad <path>   Output path.
                        Default: ".\country"

  -Metafiles <path>     Path for files used by the script. 
                        Default: ".\script_files"

  -skiplist             Skips playlist fetching, uses local list.
  -noplay               Skips opening -Countryroad in foobar2k.
  -quiet                Supresses some of the logging.
```