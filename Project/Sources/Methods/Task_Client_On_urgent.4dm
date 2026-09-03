//%attributes = {"invisible":true}
#DECLARE($taskId : Integer)

var $task : cs.TaskEntity
var $content : Text

$task:=ds.Task.get($taskId)
If ($task#Null)
	$content:=$task.description
	DISPLAY NOTIFICATION("Nouvelle tâche urgente"; Substring($content; 1; 255))
End if 
