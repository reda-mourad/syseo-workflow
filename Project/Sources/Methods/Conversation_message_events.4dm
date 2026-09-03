//%attributes = {"invisible":true}

var $choice; $messageId; $userId : Integer
var $objectName : Text

If ((FORM Event.code=On Clicked) && Right click)
	$objectName:=FORM Event.objectName
	If ($objectName="btnMessage@")
		$messageId:=Num(Substring($objectName; Length("btnMessage")+1))
		$choice:=Pop up menu("Convertir ce message en tâche")
		If (($choice=1) && ($messageId>0))
			$userId:=Messaging_Client_User_id
			Task_Client_Open_from_message($userId; $messageId)
		End if 
	End if 
End if 
