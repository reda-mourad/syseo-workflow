//%attributes = {"invisible":true,"shared":true}
#DECLARE($recipientId : Integer; $conversationId : Integer; $messageId : Integer; $senderId : Integer)

var $window : Integer
var $windows : Collection

Messaging_Server_Mark_latest($recipientId; $conversationId; "received")
$windows:=New collection
If ((Value type(Storage.messagingClient)=Is object) && (Value type(Storage.messagingClient.windows)=Is collection))
	Use (Storage.messagingClient.windows)
		$windows:=Storage.messagingClient.windows.slice(0)
	End use 
End if 
For each ($window; $windows)
	CALL FORM($window; "Messaging_Client_Form_notify"; "message"; $conversationId; $messageId; $senderId; "received")
End for each 
Launcher_Client_Refresh
Messaging_Client_On_new_message($conversationId; $messageId; $senderId)
