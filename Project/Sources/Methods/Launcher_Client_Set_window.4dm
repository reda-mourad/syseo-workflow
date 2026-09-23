//%attributes = {"invisible":true,"shared":true}
#DECLARE($window : Integer; $registered : Boolean)

var $position : Integer

Use (Storage)
	If (Value type(Storage.launcherWindows)#Is collection)
		Storage.launcherWindows:=New shared collection
	End if 
End use 

Use (Storage.launcherWindows)
	$position:=Storage.launcherWindows.indexOf($window)
	If ($registered)
		If ($position<0)
			Storage.launcherWindows.push($window)
		End if 
	Else 
		If ($position>=0)
			Storage.launcherWindows.remove($position)
		End if 
	End if 
End use 
