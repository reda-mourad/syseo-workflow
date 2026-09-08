//%attributes = {"invisible":true,"shared":true}
#DECLARE()

var $handler : cs.FormLauncher

$handler:=Form.handler
If ($handler#Null)
	$handler.refreshBadges()
End if 
