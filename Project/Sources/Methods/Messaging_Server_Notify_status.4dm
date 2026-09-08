//%attributes = {"invisible":true,"executedOnServer":true,"shared":true}
#DECLARE($participantId : Integer; $conversationId : Integer; $messageId : Integer; $state : Text)->$queuedCount : Integer

var $members : cs.ConversationMemberSelection
var $member : cs.ConversationMemberEntity
var $clientName : Text

$queuedCount:=0
$members:=ds.ConversationMember.query("ID_Conversation = :1 AND ID_Utilisateur # :2 AND left_at = null"; $conversationId; $participantId)
For each ($member; $members)
	$clientName:="Messaging.User."+String($member.ID_Utilisateur)
	EXECUTE ON CLIENT($clientName; "Messaging_Client_Status"; $participantId; $conversationId; $messageId; $state)
	If (OK=1)
		$queuedCount:=$queuedCount+1
	End if 
End for each 
