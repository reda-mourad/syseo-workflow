//%attributes = {"invisible":true,"shared":true}
#DECLARE()

var $window : Integer

$window:=Open form window("Launcher"; -Plain form window no title; On the right; At the bottom)
DIALOG("Launcher"; {handler: cs.FormLauncher.new(Messaging_Client_User_id)})
CLOSE WINDOW($window)
