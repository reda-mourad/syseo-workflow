//%attributes = {"invisible":true,"shared":true}
#DECLARE($window : Integer; $registered : Boolean)

var $position : Integer

Use (Storage)
	If (Value type(Storage.taskWindows)#Is collection)
		Storage.taskWindows:=New shared collection
	End if 
End use 

Use (Storage.taskWindows)
	$position:=Storage.taskWindows.indexOf($window)
	If ($registered)
		If ($position<0)
			Storage.taskWindows.push($window)
		End if 
	Else 
		If ($position>=0)
			Storage.taskWindows.remove($position)
		End if 
	End if 
End use 
