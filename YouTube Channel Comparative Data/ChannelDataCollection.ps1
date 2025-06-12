#### Data collection script from Channels

#region - Functions
function Get-ChannelHandleFromURL {
    param([string]$URL)
    return "@"+$url.Split("@")[1]
}

function Get-ChannelIdFromHandle {
    param (
        [string]$Handle
    )

    $searchUrl = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=channel&q=$Handle&key=$ApiKey"
    $response = Invoke-RestMethod -Uri $searchUrl
    return $response.items[0].snippet.channelId
}

function Get-UploadsPlaylistId {
    param (
        [string]$ChannelId
    )

    $url = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails&id=$ChannelId&key=$ApiKey"
    $response = Invoke-RestMethod -Uri $url
    return $response.items[0].contentDetails.relatedPlaylists.uploads
}

function Get-PlaylistVideos {
    param (
        [string]$PlaylistId
    )

    $videos = @()
    $nextPageToken = ""

    do {
        $url = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=$PlaylistId&maxResults=50&pageToken=$nextPageToken&key=$ApiKey"
        $response = Invoke-RestMethod -Uri $url

        foreach ($item in $response.items) {
            $videos += [PSCustomObject]@{
                VideoId      = $item.snippet.resourceId.videoId
                Title        = $item.snippet.title
                PublishedAt  = $item.snippet.publishedAt
                Description  = $item.snippet.description
            }
        }

        $nextPageToken = $response.nextPageToken
    } while ($nextPageToken)

    return $videos
}
function Get-SubscriberCount {
    param (
        [string]$ChannelId
    )
    $url = "https://www.googleapis.com/youtube/v3/channels?part=statistics&id=$ChannelId&key=$ApiKey"
    $response = Invoke-RestMethod -Uri $url
    return $response.items[0].statistics.subscriberCount
}

function Add-VideoStatistics {
    param (
        [array]$Videos
    )

    $Videos | Add-Member -NotePropertyName "ChannelSubscribers" -NotePropertyValue 0
    $Videos | Add-Member -NotePropertyName "Views" -NotePropertyValue 0
    $Videos | Add-Member -NotePropertyName "Likes" -NotePropertyValue 0
    $Videos | Add-Member -NotePropertyName "Comments" -NotePropertyValue 0
    

    foreach ($video in $Videos) {
        $statsUrl = "https://www.googleapis.com/youtube/v3/videos?part=statistics&id=$($video.VideoId)&key=$ApiKey"
        $response = Invoke-RestMethod -Uri $statsUrl

        $video.Views = $response.items[0].statistics.viewCount
        $video.Likes = $response.items[0].statistics.likeCount
        $video.Comments = $response.items[0].statistics.commentCount
        $video.ChannelSubscribers = $SubscribersCount
    }

    return $Videos
}

#endregion

#region Main Flow
$ChannelURLList = Get-Content .\ComparativeChannelsList.txt
foreach ($ChannelURL in $ChannelURLList) {
    $ApiKey = "<enter your API key here>"
    #Check this video to know how to: https://www.youtube.com/watch?v=EPeDTRNKAVo

    Write-Host "Getting channel handle for $ChannelURL..."
    $ChannelHandle = Get-ChannelHandleFromURL -URL $ChannelURL

    Write-Host "Getting channel ID for handle $ChannelHandle..."
    $channelId = Get-ChannelIdFromHandle -Handle $ChannelHandle

    Write-Host "Getting uploads playlist ID..."
    $playlistId = Get-UploadsPlaylistId -ChannelId $channelId

    Write-Host "Getting subscribers count..."
    $SubscribersCount= Get-SubscriberCount -ChannelId $channelId

    Write-Host "Getting video list..."
    $videos = Get-PlaylistVideos -PlaylistId $playlistId

    Write-Host "Fetching video statistics..."
    $videosWithStats = Add-VideoStatistics -Videos $videos 

    # Select & Export
    $FileName = $ChannelHandle.Replace("@","") + '.csv'
    $final = $videosWithStats | Select-Object ChannelSubscribers,Title, PublishedAt, Description, Views, Likes
    $final | Export-Csv -Path ".\ComparativeChannelData\$FileName" -NoTypeInformation -Encoding UTF8 -Force

    Write-Host "nice Done! File saved as $fileName"
}
#endregion

#region Binding all csvs collected
$inputFolder = ".\ComparativeChannelData\"
$outputFile = ".\ComparativeChannelData\_CombinedFile.csv"
Remove-Item ".\ComparativeChannelData\_CombinedFile.csv"


$allFiles = Get-ChildItem -Path $inputFolder -Filter *.csv
$combined = @()

foreach ($file in $allFiles) {
    $data = Import-Csv -Path $file.FullName | ForEach-Object {
        $_ | Add-Member -NotePropertyName "ChannelName" -NotePropertyValue $([System.IO.Path]::GetFileNameWithoutExtension($file.Name)) -PassThru -ErrorAction SilentlyContinue
    }
    $combined += $data
}

$combined | Export-Csv -Path $outputFile -NoTypeInformation
#endregion