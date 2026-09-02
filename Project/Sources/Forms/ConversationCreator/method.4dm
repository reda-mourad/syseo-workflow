var $handler : cs.FormConversationCreator

If (Form.handler#Null)
	$handler:=Form.handler
	$handler.handleEvents()
End if 
