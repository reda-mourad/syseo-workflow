//%attributes = {"invisible":true,"shared":true}
#DECLARE($userId : Integer; $messageId : Integer)

var $message : cs.MessageEntity
var $membership : cs.ConversationMemberEntity

$message:=ds.Message.get($messageId)
If ($message#Null)
	$membership:=ds.ConversationMember.query("ID_Conversation = :1 AND ID_Utilisateur = :2 AND left_at = null"; $message.ID_Conversation; $userId).first()
	If ($membership#Null)
		CALL FORM(Current form window; "Task_Client_Form_from_message"; $message.body)
	Else 
		ALERT("Vous ne pouvez pas convertir un message d'une conversation dont vous n'êtes pas membre.")
	End if 
Else 
	ALERT("Le message est introuvable.")
End if 
