//%attributes = {"invisible":true,"shared":true}
#DECLARE($recipientId : Integer; $taskId : Integer; $actorId : Integer; $kind : Text)

var $window : Integer
var $windows : Collection

$windows:=New collection
If (Value type(Storage.taskWindows)=Is collection)
	Use (Storage.taskWindows)
		$windows:=Storage.taskWindows.slice(0)
	End use 
End if 

For each ($window; $windows)
	CALL FORM($window; "Task_Client_Form_refresh"; $taskId)
End for each 

Launcher_Client_Refresh
If ($kind="urgent")
	Task_Client_On_urgent($taskId)
End if 
