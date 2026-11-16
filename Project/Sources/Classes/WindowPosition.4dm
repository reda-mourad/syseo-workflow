// Local UI preferences belong to the host's Resources folder, including on 4D Remote.
property formName : Text

Class constructor($formName : Text)
	This.formName:=$formName

Function positionFile() : 4D.File
	return Folder(Get 4D folder(Current resources folder; *); fk platform path).file("syseo-workflow."+This.formName+".position.json")

Function restore($window : Integer)
	var $file : 4D.File
	var $position : Object
	var $left; $top; $right; $bottom : Integer

	Try
		$file:=This.positionFile()
		If ($file.exists)
			$position:=JSON Parse($file.getText(); Is object)
			If ($position#Null)
				If ((Value type($position.left)=Is real) && (Value type($position.top)=Is real))
					GET WINDOW RECT($left; $top; $right; $bottom; $window)
					// Older files contain only coordinates; keep the default size in that case.
					If ((Value type($position.width)=Is real) && (Value type($position.height)=Is real))
						If (($position.width>0) && ($position.height>0))
							// Respect form size limits and object resizing properties.
							RESIZE FORM WINDOW($position.width-($right-$left); $position.height-($bottom-$top))
							GET WINDOW RECT($left; $top; $right; $bottom; $window)
						End if
					End if
					SET WINDOW RECT($position.left; $position.top; $position.left+$right-$left; $position.top+$bottom-$top; $window; *)
				End if
			End if
		End if
	Catch
		// Missing, unreadable, or malformed preferences leave the default position intact.
	End try

Function save($window : Integer)
	var $file : 4D.File
	var $left; $top; $right; $bottom : Integer

	If ($window<=0)
		return
	End if
	GET WINDOW RECT($left; $top; $right; $bottom; $window)
	If (($right<=$left) || ($bottom<=$top))
		return
	End if
	Try
		$file:=This.positionFile()
		$file.setText(JSON Stringify({left: $left; top: $top; width: $right-$left; height: $bottom-$top}); "utf-8")
	Catch
		// A read-only Resources folder must not prevent closing or moving a window.
		LOG EVENT(Into system standard outputs; "Unable to save window position for "+This.formName; Warning message)
	End try
