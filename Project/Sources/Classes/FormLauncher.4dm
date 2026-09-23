property userId : Integer
property combinedBadge : Text

Class constructor($userId : Integer)
	This.userId:=$userId
	This.combinedBadge:="0"

Function refreshBadges()
	var $response : Object
	$response:=Launcher_Server_Counts(This.userId)
	If ($response.success)
		This.combinedBadge:=String($response.unreadConversations+$response.unfinishedTasks)
	End if
	OBJECT SET VISIBLE(*; "bgWorkspaceBadge"; Num(This.combinedBadge)>0)
	OBJECT SET VISIBLE(*; "inputWorkspaceBadge"; Num(This.combinedBadge)>0)

Function openWorkspace()
	var $window : Integer
	$window:=Open form window("WorkflowWorkspace"; Movable form dialog box)
	DIALOG("WorkflowWorkspace"; {handler: cs.FormWorkflowWorkspace.new(This.userId)})
	CLOSE WINDOW($window)
	This.refreshBadges()

Function handleEvents()
	Case of
		: (FORM Event.code=On Load)
			Launcher_Client_Set_window(Current form window; True)
			This.refreshBadges()
		: (FORM Event.code=On Unload)
			Launcher_Client_Set_window(Current form window; False)
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnWorkspace")
			This.openWorkspace()
	End case
