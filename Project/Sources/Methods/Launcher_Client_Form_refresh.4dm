//%attributes = {"invisible":true,"shared":true}
#DECLARE()

var $handler : Object

$handler:=Form.handler
If ($handler#Null)
	$handler.refreshBadges()
End if 
