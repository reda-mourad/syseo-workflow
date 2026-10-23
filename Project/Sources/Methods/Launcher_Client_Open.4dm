//%attributes = {"invisible":true,"shared":true}
#DECLARE()

var $window; $width; $height; $left; $top : Integer

FORM GET PROPERTIES("Launcher"; $width; $height)
$left:=(Screen width-$width)/2
$top:=Screen height-$height-8
If ($left<0)
	$left:=0
End if 
If ($top<0)
	$top:=0
End if 
// The negative type creates a floating, non-modal window with no close box or title bar.
$window:=Open window($left; $top; $left+$width; $top+$height; -Plain dialog box)
DIALOG("Launcher"; {handler: cs.FormLauncher.new(Messaging_Client_User_id)})
CLOSE WINDOW($window)

