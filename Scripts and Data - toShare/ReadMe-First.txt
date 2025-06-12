To run this solution you must load the input data this way:
1. Open the file ComparativeChannelsList.txt and add the URLs of the channel you want to compare or get insights from.  I would recommend add yours too.  You will find some sample data already in the file. I left it for you to check how should be written. Feel free to delete it.
2. Obtain an API key to connect to YouTube via web.  It's easy, you just need to watch this video: https://www.youtube.com/@EVBeyond1 
3. Open the file ChannelDataCollection.ps1 and edit line #93
   it says:    $ApiKey = "<enter your API key here>"
(use the key obtained in step#2.  If your key is: 43890534oirjweff0349434034032 then
   should say: $ApiKey = "43890534oirjweff0349434034032"
4. Run the ChannelDataCollection.ps1 script
   In your computer click Windows+r and type:
    powershell.exe "<path>\ChannelDataCollection.ps1"
5. The script produces two kind of reports:
	Individual files for each channel you added in the ComparativeChannelsList.txt
	A file called _Combinedfile.csv grouping all channels above

What you can do with that data?
- Analyse it yourself using BI tools (I use PowerBI and added a sample report in the folder)
Get ChatGPT (or your AI of choice) to suggest you:
- titles and/or descriptions based on your comparative channels best performing videos
- publishing times
- wording
- manage your view/like expectation