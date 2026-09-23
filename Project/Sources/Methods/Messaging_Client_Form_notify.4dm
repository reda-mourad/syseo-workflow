//%attributes = {"invisible":true,"shared":true}
#DECLARE($kind : Text; $conversationId : Integer; $messageId : Integer; $actorId : Integer; $state : Text)

var $handler : Object

$handler:=Form.handler
If ($handler#Null)
	$handler.processNotification($kind; $conversationId)
End if 
