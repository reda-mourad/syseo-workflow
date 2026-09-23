//%attributes = {"invisible":true,"executedOnServer":true,"shared":true}
#DECLARE($recipientIds : Collection; $taskId : Integer; $actorId : Integer; $kind : Text)->$queuedCount : Integer

var $recipientId : Integer
var $clientName : Text

$queuedCount:=0
For each ($recipientId; $recipientIds)
	If (($recipientId>0) && ($recipientId#$actorId))
		$clientName:="Messaging.User."+String($recipientId)
		EXECUTE ON CLIENT($clientName; "Task_Client_Changed"; $recipientId; $taskId; $actorId; $kind)
		If (OK=1)
			$queuedCount:=$queuedCount+1
		End if 
	End if 
End for each 
