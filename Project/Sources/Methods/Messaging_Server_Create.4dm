//%attributes = {"invisible":true,"executedOnServer":true,"shared":true}
#DECLARE($creatorId : Integer; $recipientIds : Collection; $title : Text)->$result : Object

var $creator; $recipient : cs.UtilisateurEntity
var $conversation; $candidateConversation; $existingConversation : cs.ConversationEntity
var $member : cs.ConversationMemberEntity
var $creatorMemberships; $activeMembers : cs.ConversationMemberSelection
var $dmConversations : cs.ConversationSelection
var $saveStatus : Object
var $recipients; $uniqueIds : Collection
var $recipientId : Integer
var $timestamp; $error : Text

$result:=New object("success"; False; "conversationId"; 0; "error"; "")
$creator:=ds.Utilisateur.get($creatorId)
$recipients:=New collection
$uniqueIds:=New collection
$error:=""

If ($creator=Null)
	$error:="The conversation creator does not exist."
Else 
	For each ($recipientId; $recipientIds)
		If (($recipientId>0) && ($recipientId#$creatorId) && ($uniqueIds.indexOf($recipientId)<0))
			$recipient:=ds.Utilisateur.get($recipientId)
			If ($recipient#Null)
				$uniqueIds.push($recipientId)
				$recipients.push($recipient)
			End if 
		End if 
	End for each 
	If ($recipients.length=0)
		$error:="At least one recipient is required."
	Else 
		If (($recipients.length>1) && (Length($title)=0))
			$error:="A group title is required."
		End if 
	End if 
End if 

If ($error="")
	If ($recipients.length=1)
		$creatorMemberships:=ds.ConversationMember.query("ID_Utilisateur = :1 AND left_at = null"; $creatorId)
		$dmConversations:=$creatorMemberships.conversation.query("kind = :1 AND deleted_at = null"; "dm").orderBy("updated_at desc, ID desc")
		For each ($candidateConversation; $dmConversations) while ($existingConversation=Null)
			$activeMembers:=$candidateConversation.members.query("left_at = null")
			If (($activeMembers.length=2) && ($activeMembers.query("ID_Utilisateur = :1"; $uniqueIds[0]).length=1))
				$existingConversation:=$candidateConversation
			End if 
		End for each 
	End if 
	
	If ($existingConversation#Null)
		$result.success:=True
		$result.conversationId:=$existingConversation.ID
	Else 
		$timestamp:=String(Current date; ISO date; Current time)
		ds.startTransaction()
		$conversation:=ds.Conversation.new()
		If ($recipients.length=1)
			$conversation.kind:="dm"
		Else 
			$conversation.kind:="group"
			$conversation.name:=$title
		End if 
		$conversation.creator:=$creator
		$conversation.created_at:=$timestamp
		$conversation.updated_at:=$timestamp
		$saveStatus:=$conversation.save()
		If (Not($saveStatus.success))
			$error:=$saveStatus.statusText
		End if 

		If ($error="")
			$member:=ds.ConversationMember.new()
			$member.conversation:=$conversation
			$member.utilisateur:=$creator
			$member.joined_at:=$timestamp
			$member.notifications_enabled:=True
			$saveStatus:=$member.save()
			If (Not($saveStatus.success))
				$error:=$saveStatus.statusText
			End if 
		End if 

		For each ($recipient; $recipients) while ($error="")
			$member:=ds.ConversationMember.new()
			$member.conversation:=$conversation
			$member.utilisateur:=$recipient
			$member.joined_at:=$timestamp
			$member.notifications_enabled:=True
			$saveStatus:=$member.save()
			If (Not($saveStatus.success))
				$error:=$saveStatus.statusText
			End if 
		End for each 

		If ($error="")
			ds.validateTransaction()
			$result.success:=True
			$result.conversationId:=$conversation.ID
		Else 
			ds.cancelTransaction()
			$result.error:=$error
		End if 
	End if 
Else 
	$result.error:=$error
End if 
