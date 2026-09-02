var $context; $sendResult : Object
var $panelHeight; $panelWidth; $composerHeight; $composerTop; $messagesBottom; $currentUserId; $conversationId : Integer
var $messageBody : Text

If (FORM Event.code=On Resize)
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
		$currentUserId:=$context.userId
		$conversationId:=$context.conversationId
	End if 
	
	Refresh_conversation_panel($currentUserId; $conversationId)
End if 

If ((FORM Event.code=On Before Keystroke) && (FORM Event.objectName="inputMessage") && (Keystroke=Char(Carriage return)) && (Not(Shift down)))
	$messageBody:=Get edited text
	FILTER KEYSTROKE("")
	$currentUserId:=Form.userId
	$conversationId:=Form.conversationId
	If (($conversationId>0) && (Length($messageBody)>0))
		$sendResult:=Messaging_Server_Send_message($currentUserId; $conversationId; $messageBody)
		If ($sendResult.success)
			Form.messageBody:=""
			OBJECT SET VALUE("inputMessage"; "")
			Refresh_conversation_panel($currentUserId; $conversationId)
		End if 
	End if 
End if 
