//%attributes = {"invisible":true}
#DECLARE($participantId : Integer; $conversationId : Integer; $messageId : Integer; $state : Text)

var $window : Integer
var $windows : Collection

$windows:=New collection
If ((Value type(Storage.messagingClient)=Is object) && (Value type(Storage.messagingClient.windows)=Is collection))
	Use (Storage.messagingClient.windows)
		$windows:=Storage.messagingClient.windows.slice(0)
	End use 
End if 
For each ($window; $windows)
	CALL FORM($window; "Messaging_Client_Form_notify"; "status"; $conversationId; $messageId; $participantId; $state)
End for each 
