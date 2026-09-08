//%attributes = {"invisible":true,"shared":true}
#DECLARE()

var $window : Integer

$window:=Open form window("ConversationList"; Movable form dialog box)
DIALOG("ConversationList"; {handler: cs.FormConversationList.new(Messaging_Client_User_id)})
CLOSE WINDOW($window)
