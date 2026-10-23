property userId : Integer
property combinedBadge : Text
property workspaceProcess : Integer
property pointerTracking : Object

Class constructor($userId : Integer)
	This.userId:=$userId
	This.combinedBadge:="0"
	This.workspaceProcess:=0
	This.pointerTracking:=Null
	
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
	
Function beginWorkspacePointer()
	var $window; $left; $top; $right; $bottom : Integer
	var $mouseX; $mouseY : Real
	var $mouseButton : Integer
	
	If (This.pointerTracking#Null)
		return
	End if
	MOUSE POSITION($mouseX; $mouseY; $mouseButton; *)
	If ($mouseButton=0)
		// Keyboard activation has no mouse gesture to track.
		This.openWorkspace()
		return
	End if
	If ($mouseButton#1)
		return
	End if
	$window:=Current form window
	GET WINDOW RECT($left; $top; $right; $bottom; $window)
	This.pointerTracking:={window: $window; mouseX: $mouseX; mouseY: $mouseY; left: $left; top: $top; right: $right; bottom: $bottom; dragging: False}
	SET TIMER(1)
	
Function trackWorkspacePointer()
	var $mouseX; $mouseY : Real
	var $mouseButton; $deltaX; $deltaY : Integer
	var $tracking : Object
	var $openWorkspace : Boolean
	
	$tracking:=This.pointerTracking
	If ($tracking=Null)
		return
	End if
	MOUSE POSITION($mouseX; $mouseY; $mouseButton; *)
	$deltaX:=$mouseX-$tracking.mouseX
	$deltaY:=$mouseY-$tracking.mouseY
	// Once a drag starts, it stays a drag even when moved back to its origin.
	If ((Abs($deltaX)>=5) || (Abs($deltaY)>=5))
		$tracking.dragging:=True
	End if
	If ($tracking.dragging)
		SET WINDOW RECT($tracking.left+$deltaX; $tracking.top+$deltaY; $tracking.right+$deltaX; $tracking.bottom+$deltaY; $tracking.window; *)
	End if
	If ($mouseButton#1)
		$openWorkspace:=($mouseButton=0) && (Not($tracking.dragging))
		This.pointerTracking:=Null
		SET TIMER(0)
		If ($openWorkspace)
			This.openWorkspace()
		End if
	End if
	
Function handleEvents()
	
	Case of 
		: (FORM Event.code=On Close Box)
			// Keep the permanent launcher open instead of cancelling the dialog.
			return
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnIgnoreEscape")
			// Consume Escape without closing the launcher.
			return
		: (FORM Event.code=On Load)
			Launcher_Client_Set_window(Current form window; True)
			This.refreshBadges()
		: (FORM Event.code=On Unload)
			SET TIMER(0)
			This.pointerTracking:=Null
			Launcher_Client_Set_window(Current form window; False)
		: (FORM Event.code=On Timer)
			This.trackWorkspacePointer()
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnWorkspace")
			This.beginWorkspacePointer()
	End case 
	
