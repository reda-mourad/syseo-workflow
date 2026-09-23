UI_Button_hover(New object("btnCancelConversation"; "bgCancelConversation"; "btnCreateConversation"; "bgCreateConversation"))

var $handler : cs.FormConversationCreator

If (Form.handler#Null)
	$handler:=Form.handler
	$handler.handleEvents()
End if 
