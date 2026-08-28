var $handler : cs.FormCategorySelector

If (FORM Event.code=On Load)
	If (Form.handler=Null)
		Form.handler:=cs.FormCategorySelector.new()
	End if 
End if 

If (Form.handler#Null)
	$handler:=Form.handler
	$handler.handleEvents()
End if 
