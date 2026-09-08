//%attributes = {"invisible":true,"executedOnServer":true,"shared":true}
#DECLARE($senderId : Integer; $conversationId : Integer; $body : Text)->$result : Object

var $membership : cs.ConversationMemberEntity
var $members : cs.ConversationMemberSelection
var $member : cs.ConversationMemberEntity
var $conversation : cs.ConversationEntity
var $message : cs.MessageEntity
var $saveStatus : Object
var $recipientIds : Collection
var $timestamp; $messageBody; $error : Text

$recipientIds:=New collection
$result:=New object("success"; False; "messageId"; 0; "error"; "")
$messageBody:=$body
$membership:=ds.ConversationMember.query("ID_Conversation = :1 AND ID_Utilisateur = :2 AND left_at = null"; $conversationId; $senderId).first()
$conversation:=ds.Conversation.get($conversationId)

If ($messageBody="")
	$result.error:="The message body cannot be empty."
Else 
	If (($membership=Null) || ($conversation=Null) || ($conversation.deleted_at#Null))
		$result.error:="The sender is not an active member of this conversation."
	Else 
		$timestamp:=String(Current date; ISO date; Current time)
		$error:=""
		ds.startTransaction()
		
		$message:=ds.Message.new()
		$message.conversation:=$conversation
		$message.sender:=$membership.utilisateur
		$message.body:=$messageBody
		$message.created_at:=$timestamp
		$saveStatus:=$message.save()
		If (Not($saveStatus.success))
			$error:=$saveStatus.statusText
		End if 
		
		If ($error="")
			$members:=$conversation.members.query("ID_Utilisateur # :1 AND left_at = null"; $senderId)
			For each ($member; $members)
				$recipientIds.push($member.ID_Utilisateur)
			End for each 
		End if 
		
		If ($error="")
			$conversation.updated_at:=$timestamp
			$saveStatus:=$conversation.save()
			If (Not($saveStatus.success))
				$error:=$saveStatus.statusText
			End if 
		End if 
		
		If ($error="")
			ds.validateTransaction()
			$result.success:=True
			$result.messageId:=$message.ID
			Messaging_Server_Notify_clients($recipientIds; $conversationId; $message.ID; $senderId)
		Else 
			ds.cancelTransaction()
			$result.error:=$error
		End if 
	End if 
End if 
