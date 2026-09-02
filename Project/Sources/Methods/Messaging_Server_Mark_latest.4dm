//%attributes = {"invisible":true,"executedOnServer":true}
#DECLARE($userId : Integer; $conversationId : Integer; $state : Text)->$result : Object

var $membership : cs.ConversationMemberEntity
var $latestMessage : cs.MessageEntity
var $saveStatus : Object
var $normalizedState; $timestamp : Text
var $changed : Boolean

$result:=New object("success"; False; "messageId"; 0; "state"; ""; "error"; "")
$normalizedState:=Lowercase($state)
If (($normalizedState#"received") && ($normalizedState#"read"))
	$result.error:="State must be 'received' or 'read'."
Else 
	$membership:=ds.ConversationMember.query("ID_Conversation = :1 AND ID_Utilisateur = :2 AND left_at = null"; $conversationId; $userId).first()
	If ($membership=Null)
		$result.error:="The user is not an active member of this conversation."
	Else 
		$latestMessage:=ds.Message.query("ID_Conversation = :1 AND ID_sender # :2 AND deleted_at = null"; $conversationId; $userId).orderBy("created_at desc, ID desc").first()
		If ($latestMessage=Null)
			$result.error:="No received message is available to mark."
		Else 
			$changed:=False
			$timestamp:=String(Current date; ISO date; Current time)
			If ($normalizedState="read")
				If (($membership.ID_last_received_message=Null) || ($membership.ID_last_received_message<$latestMessage.ID))
					$membership.lastReceivedMessage:=$latestMessage
					$membership.last_received_at:=$timestamp
					$changed:=True
				End if 
				If (($membership.ID_last_read_message=Null) || ($membership.ID_last_read_message<$latestMessage.ID))
					$membership.lastReadMessage:=$latestMessage
					$membership.last_read_at:=$timestamp
					$changed:=True
				End if 
			Else 
				If (($membership.ID_last_received_message=Null) || ($membership.ID_last_received_message<$latestMessage.ID))
					$membership.lastReceivedMessage:=$latestMessage
					$membership.last_received_at:=$timestamp
					$changed:=True
				End if 
			End if 
			If ($changed)
				$saveStatus:=$membership.save()
			Else 
				$saveStatus:=New object("success"; True)
			End if 
			If ($saveStatus.success)
				$result.success:=True
				$result.messageId:=$latestMessage.ID
				$result.state:=$normalizedState
				If ($changed)
					Messaging_Server_Notify_status($userId; $conversationId; $latestMessage.ID; $normalizedState)
				End if 
			Else 
				$result.error:=$saveStatus.statusText
			End if 
		End if 
	End if 
End if 
