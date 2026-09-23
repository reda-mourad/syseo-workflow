//%attributes = {"invisible":true,"shared":true}
#DECLARE($userId : Integer)->$result : Object

var $clientName : Text

$result:=New object("success"; False; "clientName"; ""; "error"; "")
If ($userId<=0)
	$result.error:="A valid user ID is required."
Else 
	If (Application type#4D Remote Mode)
		$result.error:="Client registration is only available from a remote 4D Client."
	Else 
		$clientName:="Messaging.User."+String($userId)
		UNREGISTER CLIENT
		REGISTER CLIENT($clientName)
		If (OK=1)
			Use (Storage)
				Storage.messagingClient:=New shared object("userId"; $userId; "clientName"; $clientName; "windows"; New shared collection)
			End use 
			$result.success:=True
			$result.clientName:=$clientName
		Else 
			$result.error:="4D Client could not be registered."
		End if 
	End if 
End if 
