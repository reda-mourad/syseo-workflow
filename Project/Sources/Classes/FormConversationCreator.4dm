property userId : Integer
property recipients : Collection
property selectedRecipients : Collection
property groupTitle : Text

Class constructor($userId : Integer)
	var $response : Object
	
	This.userId:=$userId
	This.groupTitle:=""
	This.selectedRecipients:=New collection
	$response:=Messaging_Server_Recipients($userId)
	If ($response.success)
		This.recipients:=$response.recipients
	Else 
		This.recipients:=New collection
	End if 


Function canCreate()->$canCreate : Boolean
	var $recipientCount : Integer
	
	$recipientCount:=0
	If (This.selectedRecipients#Null)
		$recipientCount:=This.selectedRecipients.length
	End if 
	$canCreate:=($recipientCount=1) || (($recipientCount>1) && (Length(This.groupTitle)>0))


Function updateState()
	var $isGroup : Boolean
	var $recipientCount : Integer
	
	$recipientCount:=0
	If (This.selectedRecipients#Null)
		$recipientCount:=This.selectedRecipients.length
	End if 
	$isGroup:=($recipientCount>1)
	OBJECT SET ENABLED(*; "inputGroupTitle"; $isGroup)
	OBJECT SET ENABLED(*; "btnCreateConversation"; This.canCreate())


Function toggleRecipient($row : Integer)
	var $recipient : Object
	
	If (($row>0) && ($row<=This.recipients.length))
		$recipient:=This.recipients[$row-1]
		$recipient.selected:=Not($recipient.selected)
		This.refreshSelectedRecipients()
	End if 


Function refreshSelectedRecipients()
	var $candidate : Object
	
	This.selectedRecipients:=New collection
	For each ($candidate; This.recipients)
		If ($candidate.selected)
			This.selectedRecipients.push($candidate)
		End if 
	End for each 
	// Notify the collection list box that an element property changed.
	This.recipients:=This.recipients
	This.updateState()


Function handleEvents()
	Case of 
		: (FORM Event.code=On Load)
			This.updateState()

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="lbRecipients") && (FORM Event.row>0)
			If (FORM Event.columnName#"columnRecipientSelected")
				This.toggleRecipient(FORM Event.row)
			End if 

		: (FORM Event.code=On Data Change) && (FORM Event.objectName="columnRecipientSelected")
			This.refreshSelectedRecipients()

		: (FORM Event.code=On Data Change) && (FORM Event.objectName="inputGroupTitle")
			This.updateState()
	End case 
