$dirSeparator = ""
if ($IsLinux -or $IsMacOS) {
    $dirSeparator = "/"
    $actualDir = "/mnt/usb"
} elseif ($IsWindows) {
    $actualDir = "G:\"
    $dirSeparator = "\"
}

$preset = $PSScriptRoot + $dirSeparator + "preset.json"


function Get-Files { 
    Get-ChildItem -Path $actualDir -Include *.mkv, *.avi, *.mp4 -Exclude "*- h265.mkv" -Recurse | Where-Object { 
        $vid = ffprobe -v error -show_entries stream=codec_name -i $_.FullName
        if ($vid -inotcontains "codec_name=hevc") {
            return $_.FullName
        }
    }
}
function Get-NumFiles {
    return Write-Output ( Get-Files  | Measure-Object ).Count
}

 while (Get-NumFiles -clt 0) {
    Get-NumFiles
    $FullPath = Get-Files | Sort-Object -Property Length | Select-Object BaseName, DirectoryName, FullName, Length -First 1
    $h264Path = $FullPath.FullName
    #$h265Path =  $FullPath.DirectoryName + $dirSeparator + $FullPath.BaseName.Substring(0, ($FullPath.BaseName).LastIndexOf(" - ")) + " - h265.mkv"
    $h265Path =  $FullPath.DirectoryName + $dirSeparator + $FullPath.BaseName + " - h265.mkv"
    HandBrakeCLI --preset-import-file $preset -i $h264Path -Z "H265v6" -o $h265Path
    #handbrakecli -i $h264Path -o $h265Path --crop 0:0:0:0 --encoder x265_10bit --quality 22.0 --format av_mkv --markers --all-audio --audio-fallback ac3

    Remove-Item -Path $h264Path
 }
