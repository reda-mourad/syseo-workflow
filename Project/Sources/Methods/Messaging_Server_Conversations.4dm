//%attributes = {"invisible":true,"executedOnServer":true,"shared":true}
#DECLARE($userId : Integer)->$result : Object

var $memberships; $otherMembers : cs.ConversationMemberSelection
var $conversations : cs.ConversationSelection
var $conversation : cs.ConversationEntity
var $membership : cs.ConversationMemberEntity
var $lastMessage : cs.MessageEntity
var $items : Collection
var $item; $lastMessageInfo : Object
var $title; $lastMessageAt : Text
var $unreadCount : Integer

$items:=New collection
$result:=New object("success"; False; "conversations"; $items; "error"; "")
If ($userId<=0)
	$result.error:="A valid user ID is required."
Else 
	$memberships:=ds.ConversationMember.query("ID_Utilisateur = :1 AND left_at = null"; $userId)
	$conversations:=$memberships.conversation.query("deleted_at = null AND kind # :1"; "task")
	
	For each ($conversation; $conversations)
		$membership:=$conversation.members.query("ID_Utilisateur = :1 AND left_at = null"; $userId).first()
		$title:=""
		If ($conversation.name#Null)
			$title:=$conversation.name
		End if 
		$otherMembers:=$conversation.members.query("ID_Utilisateur # :1 AND left_at = null"; $userId)
		If (($conversation.kind="dm") || (Length($title)=0))
			$title:=$otherMembers.utilisateur.Nom.join(", ")
		End if 
		If (Length($title)=0)
			$title:="Conversation "+String($conversation.ID)
		End if 
		
		$lastMessage:=$conversation.messages.query("deleted_at = null").orderBy("created_at desc, ID desc").first()
		$lastMessageInfo:=Null
		$lastMessageAt:=""
		If ($lastMessage#Null)
			$lastMessageAt:=$lastMessage.created_at
			$lastMessageInfo:=New object(\
			"ID"; $lastMessage.ID; \
			"senderId"; $lastMessage.ID_sender; \
			"body"; $lastMessage.body; \
			"createdAt"; $lastMessage.created_at)
		End if 
		$unreadCount:=0
		If ($membership.ID_last_read_message#Null)
			$unreadCount:=ds.Message.query("ID_Conversation = :1 AND ID_sender # :2 AND ID > :3 AND deleted_at = null"; $conversation.ID; $userId; $membership.ID_last_read_message).length
		Else 
			$unreadCount:=ds.Message.query("ID_Conversation = :1 AND ID_sender # :2 AND deleted_at = null"; $conversation.ID; $userId).length
		End if 
		$item:=New object(\
		"ID"; $conversation.ID; \
		"kind"; $conversation.kind; \
		"name"; $conversation.name; \
		"title"; $title; \
		"updatedAt"; $conversation.updated_at; \
		"lastMessageAt"; $lastMessageAt; \
		"unreadCount"; $unreadCount; \
		"lastMessage"; $lastMessageInfo)
		$items.push($item)
	End for each 
	$items:=$items.orderBy(New collection(\
	New object("propertyPath"; "lastMessageAt"; "descending"; True); \
	New object("propertyPath"; "ID"; "descending"; True)))
	$result.conversations:=$items
	
	$result.success:=True
End if 
