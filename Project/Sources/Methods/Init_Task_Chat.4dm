//%attributes = {"shared":true}
#DECLARE($userId : Integer)

var $registration : Object

If ($userId>0)
	$registration:=Messaging_Client_Register($userId)
	If ($registration.success)
		Launcher_Client_Open
	End if 
End if 
