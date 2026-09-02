//%attributes = {"invisible":true}
#DECLARE()

var $window : Integer
var $windows : Collection

$windows:=New collection
If (Value type(Storage.launcherWindows)=Is collection)
	Use (Storage.launcherWindows)
		$windows:=Storage.launcherWindows.slice(0)
	End use 
End if 

For each ($window; $windows)
	CALL FORM($window; "Launcher_Client_Form_refresh")
End for each 
