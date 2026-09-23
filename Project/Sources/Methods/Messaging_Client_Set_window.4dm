//%attributes = {"invisible":true,"shared":true}
#DECLARE($window : Integer; $registered : Boolean)

var $position : Integer

If ((Value type(Storage.messagingClient)=Is object) && (Value type(Storage.messagingClient.windows)=Is collection))
	Use (Storage.messagingClient.windows)
		$position:=Storage.messagingClient.windows.indexOf($window)
		If ($registered)
			If ($position<0)
				Storage.messagingClient.windows.push($window)
			End if 
		Else 
			If ($position>=0)
				Storage.messagingClient.windows.remove($position)
			End if 
		End if 
	End use 
End if 
