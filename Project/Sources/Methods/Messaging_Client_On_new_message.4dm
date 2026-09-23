//%attributes = {"invisible":true,"shared":true}
#DECLARE($conversationId : Integer; $messageId : Integer; $senderId : Integer)

var $message : cs.MessageEntity
var $title; $content : Text

$message:=ds.Message.get($messageId)
If ($message#Null)
	$title:=$message.sender.Nom
	If (($message.conversation.kind="group") && ($message.conversation.name#Null) && (Length($message.conversation.name)>0))
		$title:=$message.conversation.name+" — "+$title
	End if 
	$content:=$message.body
	DISPLAY NOTIFICATION(Substring($title; 1; 255); Substring($content; 1; 255))
End if 
