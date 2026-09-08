//%attributes = {"invisible":true,"executedOnServer":true,"shared":true}
#DECLARE($userId : Integer)->$result : Object

var $conversationResponse; $conversation : Object
var $tasks : cs.TaskSelection
var $unreadConversationCount; $unfinishedTaskCount : Integer

$unreadConversationCount:=0
$unfinishedTaskCount:=0
$result:=New object("success"; False; "unreadConversations"; 0; "unfinishedTasks"; 0; "error"; "")

If (ds.Utilisateur.get($userId)=Null)
	$result.error:="The current user does not exist."
Else 
	$conversationResponse:=Messaging_Server_Conversations($userId)
	If ($conversationResponse.success)
		For each ($conversation; $conversationResponse.conversations)
			If ($conversation.unreadCount>0)
				$unreadConversationCount:=$unreadConversationCount+1
			End if 
		End for each 
		$tasks:=ds.Task.query("assignees.ID_Utilisateur = :1 AND completed_at = null"; $userId)
		$unfinishedTaskCount:=$tasks.length
		$result.success:=True
		$result.unreadConversations:=$unreadConversationCount
		$result.unfinishedTasks:=$unfinishedTaskCount
	Else 
		$result.error:=$conversationResponse.error
	End if 
End if 
