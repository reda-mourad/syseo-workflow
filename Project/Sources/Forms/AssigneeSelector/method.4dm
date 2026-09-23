UI_Button_hover(New object("btnCancel"; "bgCancel"; "btnSelect"; "bgSelect"))

var $handler : cs.FormAssigneeSelector

If (FORM Event.code=On Load)
	If (Form.handler=Null)
		Form.handler:=cs.FormAssigneeSelector.new()
	End if 
End if 

If (Form.handler#Null)
	$handler:=Form.handler
	$handler.handleEvents()
End if 
