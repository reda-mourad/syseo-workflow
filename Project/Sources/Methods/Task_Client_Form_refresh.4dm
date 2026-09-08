//%attributes = {"invisible":true,"shared":true}
#DECLARE($taskId : Integer)

var $handler : Object

$handler:=Form.handler
If ($handler#Null)
	$handler.processTaskNotification($taskId)
End if 
