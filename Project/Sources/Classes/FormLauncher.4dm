property userId : Integer
property combinedBadge : Text
property workspaceProcess : Integer

Class constructor($userId : Integer)
	This.userId:=$userId
	This.combinedBadge:="0"
	This.workspaceProcess:=0

Function refreshBadges()
	var $response : Object
	$response:=Launcher_Server_Counts(This.userId)
	If ($response.success)
		This.combinedBadge:=String($response.unreadConversations+$response.unfinishedTasks)
	End if
	OBJECT SET VISIBLE(*; "bgWorkspaceBadge"; Num(This.combinedBadge)>0)
	OBJECT SET VISIBLE(*; "inputWorkspaceBadge"; Num(This.combinedBadge)>0)

Function openWorkspace()
	// The unique process name reuses an open workspace and allows reopening after close.
	This.workspaceProcess:=New process("Workspace_Client_Open"; 0; "WorkflowWorkspace."+String(This.userId); This.userId; *)
	If (This.workspaceProcess>0)
		SHOW PROCESS(This.workspaceProcess)
		BRING TO FRONT(This.workspaceProcess)
	End if

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
