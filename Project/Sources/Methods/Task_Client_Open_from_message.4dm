//%attributes = {"invisible":true}
#DECLARE($userId : Integer; $messageId : Integer)

var $window : Integer
var $message : cs.MessageEntity
var $membership : cs.ConversationMemberEntity
var $handler : cs.FormTaskManager

$message:=ds.Message.get($messageId)
If ($message#Null)
	$membership:=ds.ConversationMember.query("ID_Conversation = :1 AND ID_Utilisateur = :2 AND left_at = null"; $message.ID_Conversation; $userId).first()
	If ($membership#Null)
		$handler:=cs.FormTaskManager.new($userId)
		$handler.initialDraft:=New object("description"; $message.body; "messageId"; $message.ID)
		$window:=Open form window("TaskManager"; Movable form dialog box)
		DIALOG("TaskManager"; {handler: $handler})
		CLOSE WINDOW($window)
	Else 
		ALERT("Vous ne pouvez pas convertir un message d'une conversation dont vous n'êtes pas membre.")
	End if 
Else 
	ALERT("Le message est introuvable.")
End if 
