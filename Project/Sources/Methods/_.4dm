//%attributes = {"shared":true}
var $registration : Object
var $userId : Integer

$userId:=Num(Request("Identifiant utilisateur"))
If ($userId>0)
	$registration:=Messaging_Client_Register($userId)
	If ($registration.success)
		Launcher_Client_Open
	End if 
End if 
