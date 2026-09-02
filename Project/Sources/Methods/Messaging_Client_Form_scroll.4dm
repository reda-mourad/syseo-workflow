//%attributes = {"invisible":true}
#DECLARE()

EXECUTE METHOD IN SUBFORM("subformConversation"; "Conversation_panel_scroll"; *)
If (OK=0)
	Conversation_panel_scroll
End if 
