//%attributes = {"invisible":true,"shared":true}
#DECLARE()->$userId : Integer

$userId:=0
If (Value type(Storage.messagingClient)=Is object)
	$userId:=Storage.messagingClient.userId
End if 
