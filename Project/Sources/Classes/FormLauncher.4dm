property userId : Integer
property unreadConversationCount : Integer
property urgentTaskCount : Integer
property messageBadge : Text
property taskBadge : Text

Class constructor($userId : Integer)
	This.userId:=$userId
	This.unreadConversationCount:=0
	This.urgentTaskCount:=0
	This.messageBadge:="0"
	This.taskBadge:="0"
	This.refreshBadges()


Function refreshBadges()
	var $response : Object
	
	$response:=Launcher_Server_Counts(This.userId)
	If ($response.success)
		This.unreadConversationCount:=$response.unreadConversations
		This.urgentTaskCount:=$response.urgentTasks
		This.messageBadge:=String(This.unreadConversationCount)
		This.taskBadge:=String(This.urgentTaskCount)
	End if 


Function openMessages()
	var $window : Integer
	
	$window:=Open form window("ConversationList"; Movable form dialog box)
	DIALOG("ConversationList"; {handler: cs.FormConversationList.new(This.userId)})
	CLOSE WINDOW($window)
	This.refreshBadges()


Function openTasks()
	var $window : Integer
	
	$window:=Open form window("TaskManager"; Movable form dialog box)
	DIALOG("TaskManager"; {handler: cs.FormTaskManager.new(This.userId)})
	CLOSE WINDOW($window)
	This.refreshBadges()


Function handleEvents()
	Case of 
		: (FORM Event.code=On Load)
			Launcher_Client_Set_window(Current form window; True)
			This.refreshBadges()

		: (FORM Event.code=On Unload)
			Launcher_Client_Set_window(Current form window; False)

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnMessages")
			This.openMessages()

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnTasks")
			This.openTasks()
	End case 
