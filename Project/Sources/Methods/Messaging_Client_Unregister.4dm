//%attributes = {"invisible":true,"shared":true}
#DECLARE()->$result : Object

$result:=New object("success"; False)
UNREGISTER CLIENT
$result.success:=(OK=1)

Use (Storage)
	If (Value type(Storage.messagingClient)=Is object)
		OB REMOVE(Storage; "messagingClient")
	End if 
End use 
