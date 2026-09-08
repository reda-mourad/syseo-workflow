//%attributes = {"invisible":true,"shared":true}
#DECLARE()

If ((Form.handler#Null) && (Value type(Form.handler.activeFeature)=Is text))
	If (Form.handler.activeFeature="messages")
		EXECUTE METHOD IN SUBFORM("subformMessages"; "Messaging_Client_Form_scroll"; *)
	Else
		EXECUTE METHOD IN SUBFORM("subformTasks"; "Messaging_Client_Form_scroll"; *)
	End if
Else
	EXECUTE METHOD IN SUBFORM("subformConversation"; "Conversation_panel_scroll"; *)
	If (OK=0)
		EXECUTE METHOD IN SUBFORM("subformDiscussion"; "Conversation_panel_scroll"; *)
		If (OK=0)
			Conversation_panel_scroll
		End if
	End if
End if
