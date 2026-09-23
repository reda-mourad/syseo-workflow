//%attributes = {"invisible":true,"shared":true}
#DECLARE()

var $window : Integer

$window:=Open form window("Launcher"; Movable form dialog box)
DIALOG("Launcher"; {handler: cs.FormLauncher.new(Messaging_Client_User_id)})
CLOSE WINDOW($window)
