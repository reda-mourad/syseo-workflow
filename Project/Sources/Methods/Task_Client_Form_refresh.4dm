//%attributes = {"invisible":true}
#DECLARE($taskId : Integer)

var $handler : cs.FormTaskManager

$handler:=Form.handler
If ($handler#Null)
	$handler.processTaskNotification($taskId)
End if 
