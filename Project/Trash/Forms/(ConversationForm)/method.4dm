var $conversation : cs.ConversationEntity
var $context : Object
var $panelHeight; $panelWidth; $composerHeight; $composerTop; $messagesBottom; $currentUserId; $conversationId : Integer

If ((FORM Event.code=On Load) || (FORM Event.code=On Resize))
	OBJECT GET SUBFORM CONTAINER SIZE($panelWidth; $panelHeight)
	$composerHeight:=60
	$composerTop:=$panelHeight-$composerHeight
	If ($composerTop<0)
		$composerTop:=0
	End if 
	$messagesBottom:=$composerTop-20
	If ($messagesBottom<0)
		$messagesBottom:=0
	End if 
	
	OBJECT SET COORDINATES(*; "bgMessageComposer"; 0; $composerTop; $panelWidth; $panelHeight)
	OBJECT SET COORDINATES(*; "inputMessage"; 10; $composerTop+10; $panelWidth-10; $panelHeight-10)
	OBJECT SET COORDINATES(*; "subformMessages"; 0; 0; $panelWidth-20; $messagesBottom)
End if 

If ((FORM Event.code=On Load) || (FORM Event.code=On Bound Variable Change) || (FORM Event.code=On Resize))
	$currentUserId:=0
	$conversationId:=0
	$context:=OBJECT Get subform container value
	If (Value type($context)=Is object)
		$conversation:=$context.conversation
		If ($conversation#Null)
			$currentUserId:=$context.userId
			$conversationId:=$conversation.ID
		End if 
	End if 
	
	Refresh_conversation_panel($currentUserId; $conversationId)
End if 
