B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@

Sub Class_Globals
	Dim App As AWTRIX
	
	'Declare your variables here
	Private displaylist As List
	Private repositories As List
	Private icon As Int = 514
	Private oldStarList As List
End Sub

' ignore
public Sub GetNiceName() As String
	Return App.Name
End Sub

' ignore
public Sub Run(Tag As String, Params As Map) As Object
	Return App.interface(Tag,Params)
End Sub

' Config your App
Public Sub Initialize() As String
	
	App.Initialize(Me,"App")
	
	'App name (must be unique, avoid spaces)
	App.Name="GithubStars"
	
	'Version of the App
	App.Version="1.0"
	
	'Description of the App. You can use HTML to format it
	App.Description=$"Shows your Github repository stars"$
	
	App.Author="cxfksword"
		
	App.CoverIcon=icon
	
	'SetupInstructions. You can use HTML to format it
	App.setupDescription= $"
	<b>Repositories:</b> Github Repository list in format: username/repo1,username/repo2.<br/>
	<b>DisplayWhenGotNewStar:</b> Only display when got new star.<br/>
	"$
	
	'How many downloadhandlers should be generated
	App.Downloads=0
	
	'IconIDs from AWTRIXER. You can add multiple if you want to display them at the same time
	App.Icons=Array As Int(icon)
	
	'Tickinterval in ms (should be 65 by default, for smooth scrolling))
	App.Tick=65
		
	'needed Settings for this App (Wich can be configurate from user via webinterface)
	App.settings=CreateMap("Repositories":"", _
						   "DisplayWhenGotNewStar":False)
	App.MakeSettings
	
	'Init downloads
	ParseSettings
	Return "AWTRIX20"
End Sub

'If the user change any Settings in the webinterface, this sub will be called
Sub App_settingsChanged
	ParseSettings
End Sub

Sub ParseSettings
	'pairs
	Dim down As Int
	repositories.Initialize
	oldStarList.Initialize
	
	If ValidateSettings Then
		Dim RepositorySplit() As String = Regex.Split(",", App.get("Repositories"))
		down = RepositorySplit.Length
		For Each pair As String In RepositorySplit
			Dim temp(3) As String
			Dim DisplaySplit() As String =  Regex.Split("@", pair)
			'repo
			temp(0) = DisplaySplit(0).Trim
			'display name
			If DisplaySplit.Length == 1 Then
				temp(1) = DisplaySplit(0).Trim
				Dim repoNameSplit() As String =  Regex.Split("/", DisplaySplit(0))
				If repoNameSplit.Length == 2 Then
					temp(1) = repoNameSplit(1).Trim
				End If
			Else
				temp(1) = DisplaySplit(1).Trim
			End If
			'save result
			temp(2) = ""
			repositories.add(temp)
			oldStarList.add("")
		Next
	Else
		down = 0
	End If
	App.downloads = down
End Sub

Sub ValidateSettings As Boolean
	If App.get("Repositories") == "" Then
		Return False
	Else
		Return True
	End If
End Sub

'this sub is called right before AWTRIX will display your App
Sub App_Started
	Dim pair(3) As String
	Dim oldStar As String
	displaylist.Initialize
	
	
	If repositories.Size <> 0 Then
		For i = 0 To repositories.Size - 1
			pair = repositories.Get(i)
			If App.get("DisplayWhenGotNewStar") Then
				oldStar = oldStarList.Get(i)
				If pair(2) <> oldStar Then
					Dim frame As FrameObject
					frame.Initialize
					frame.text = pair(1) & " " & pair(2)
					frame.TextLength = App.calcTextLength(frame.text)
					frame.color = Null
					frame.Icon = icon
					displaylist.Add(frame)
				End If
			Else
				Dim frame As FrameObject
				frame.Initialize
				frame.text = pair(1) & " " & pair(2)
				frame.TextLength = App.calcTextLength(frame.text)
				frame.color = Null
				frame.Icon = icon
				displaylist.Add(frame)
			End If
		Next
	End If


	If displaylist.Size == 0 Then
		App.ShouldShow=False
	Else
		App.ShouldShow=True
	End If
	
	
End Sub

'Called with every update from Awtrix
'return one URL for each downloadhandler
Sub App_startDownload(jobNr As Int)
	Dim cur() As String = repositories.get(jobNr - 1)
	App.Download("https://github.com/" & cur(0))
End Sub

'process the response from each download handler
'if youre working with JSONs you can use this online parser
'to generate the code automaticly
'https://json.blueforcer.de/ 
Sub App_evalJobResponse(Resp As JobResponse)
	Try
		If Resp.success Then
			Dim pair(3) As String = repositories.get(Resp.jobNr - 1)
			oldStarList.Set(Resp.jobNr - 1, pair(2))

			Dim matcher As Matcher
			matcher = Regex.Matcher("<span.*?repo-stars-counter-star.*?>(\d+?)</span>", Resp.ResponseString)
			If matcher.Find And matcher.GroupCount == 1 Then
				pair(2) = matcher.Group(1)
			End If
			repositories.Set(Resp.jobNr - 1, pair)
		End If
	Catch
		Log("Error in: "& App.Name & CRLF & LastException)
		Log("API response: " & CRLF & Resp.ResponseString)
	End Try
End Sub

'With this sub you build your frame.
Sub App_genFrame
	App.FallingText(displaylist, True)
End Sub