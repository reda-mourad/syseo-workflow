//%attributes = {"invisible":true,"executedOnServer":true}
#DECLARE($userId : Integer; $conversationId : Integer; $limit : Integer)->$result : Object

var $membership : cs.ConversationMemberEntity
var $otherMembers : cs.ConversationMemberSelection
var $messages : cs.MessageSelection
var $message : cs.MessageEntity
var $items : Collection
var $item : Object
var $effectiveLimit; $participantCount; $receivedCount; $readCount : Integer
var $status : Text

$items:=New collection
$result:=New object("success"; False; "messages"; $items; "error"; "")
$membership:=ds.ConversationMember.query("ID_Conversation = :1 AND ID_Utilisateur = :2 AND left_at = null"; $conversationId; $userId).first()
If ($membership=Null)
	$result.error:="The user is not an active member of this conversation."
Else 
	$effectiveLimit:=$limit
	If ($effectiveLimit<=0)
		$effectiveLimit:=50
	End if 
	If ($effectiveLimit>200)
		$effectiveLimit:=200
	End if 
	
	$messages:=ds.Message.query("ID_Conversation = :1 AND deleted_at = null"; $conversationId).orderBy("created_at desc, ID desc")
	$messages:=$messages.slice(0; $effectiveLimit).orderBy("created_at asc, ID asc")
	$otherMembers:=ds.ConversationMember.query("ID_Conversation = :1 AND ID_Utilisateur # :2 AND left_at = null"; $conversationId; $userId)
	$participantCount:=$otherMembers.length
	For each ($message; $messages)
		$status:="sent"
		If ($message.ID_sender=$userId)
			If ($participantCount>0)
				$receivedCount:=$otherMembers.query("ID_last_received_message >= :1"; $message.ID).length
				$readCount:=$otherMembers.query("ID_last_read_message >= :1"; $message.ID).length
				If ($readCount=$participantCount)
					$status:="read"
				Else 
					If ($receivedCount=$participantCount)
						$status:="received"
					End if 
				End if 
			End if 
		Else 
			If (($membership.ID_last_read_message#Null) && ($membership.ID_last_read_message>=$message.ID))
				$status:="read"
			Else 
				If (($membership.ID_last_received_message#Null) && ($membership.ID_last_received_message>=$message.ID))
					$status:="received"
				End if 
			End if 
		End if 
		
		$item:=New object(\
		"ID"; $message.ID; \
		"conversationId"; $conversationId; \
		"senderId"; $message.ID_sender; \
		"senderName"; $message.sender.Nom; \
		"senderInitials"; $message.sender.Initiales; \
		"body"; $message.body; \
		"createdAt"; $message.created_at; \
		"editedAt"; $message.edited_at; \
		"status"; $status)
		$items.push($item)
	End for each 
	$result.success:=True
End if 
