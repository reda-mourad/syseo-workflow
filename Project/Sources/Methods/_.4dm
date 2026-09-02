//%attributes = {}
var $registration : Object
var $userId : Integer

$userId:=Num(Request("") || 17)
$registration:=Messaging_Client_Register($userId)
If ($registration.success)
	Launcher_Client_Open
End if 
