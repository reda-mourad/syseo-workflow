//%attributes = {"invisible":true,"shared":true}
#DECLARE($backgrounds : Object)

var $event : Integer
var $button; $background : Text
var $state : Object
var $foreground; $fill; $hoverFill; $red; $green; $blue : Integer

$event:=FORM Event.code
If (($event=On Mouse Enter) || ($event=On Mouse Leave) || ($event=On Clicked) || ($event=On Page Change) || ($event=On Unload))
	$state:=Form.buttonHover
	If ($state#Null)
		// Restore before the form handler applies any new selection colors.
		$fill:=$state.fill
		OBJECT SET RGB COLORS(*; $state.background; ""; $fill)
		Form.buttonHover:=Null
	End if
	If ($event=On Mouse Enter)
		$button:=FORM Event.objectName
		$background:=""
		If (Value type($backgrounds[$button])=Is text)
			$background:=$backgrounds[$button]
		End if
		If (Length($background)>0)
			If (OBJECT Get enabled(*; $button))
				OBJECT GET RGB COLORS(*; $background; $foreground; $fill)
				$hoverFill:=$fill
				If ($fill>=0)
					// Subtly darken the current background by 4%.
					$red:=Round((($fill\65536)%256)*0.96; 0)
					$green:=Round((($fill\256)%256)*0.96; 0)
					$blue:=Round(($fill%256)*0.96; 0)
					// 4D evaluates left to right: group each channel before adding.
					$hoverFill:=($red*65536)+($green*256)+$blue
				End if
				Form.buttonHover:=New object("background"; $background; "fill"; $fill)
				OBJECT SET RGB COLORS(*; $background; ""; $hoverFill)
			End if
		End if
	End if
End if
