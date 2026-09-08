//%attributes = {"invisible":true,"executedOnServer":true,"shared":true}
#DECLARE($recipientIds : Collection; $conversationId : Integer; $messageId : Integer; $senderId : Integer)->$queuedCount : Integer

var $recipientId : Integer
var $clientName : Text

$queuedCount:=0
For each ($recipientId; $recipientIds)
	$clientName:="Messaging.User."+String($recipientId)
	EXECUTE ON CLIENT($clientName; "Messaging_Client_New_message"; $recipientId; $conversationId; $messageId; $senderId)
	If (OK=1)
		$queuedCount:=$queuedCount+1
	End if 
End for each 
