property userId : Integer
property conversations : Collection
property selectedConversation : Object
property selectedConversationPosition : Integer
property conversationContext : Object
property restoringConversationSelection : Boolean

Class constructor($userId : Integer)
	This.userId:=$userId
	This.restoringConversationSelection:=False
	This.conversationContext:=New object("userId"; $userId; "conversationId"; 0; "messageBody"; ""; "lastNotificationId"; 0)
	This.load()


Function load()
	var $response : Object
	var $conversation : Object
	var $activeConversationId; $position : Integer
	
	$activeConversationId:=This.conversationContext.conversationId
	
	$response:=Messaging_Server_Conversations(This.userId)
	If ($response.success)
		This.conversations:=$response.conversations
		This.selectedConversation:=Null
		This.selectedConversationPosition:=0
		If ($activeConversationId>0)
			$position:=0
			For each ($conversation; This.conversations)
				$position:=$position+1
				If ($conversation.ID=$activeConversationId)
					This.selectedConversation:=$conversation
					This.selectedConversationPosition:=$position
				End if 
			End for each 
		End if 
	Else 
		This.conversations:=New collection
		This.selectedConversation:=Null
		This.selectedConversationPosition:=0
	End if 


Function refreshConversations()
	var $selection : Collection
	
	This.restoringConversationSelection:=True
	This.load()
	$selection:=New collection
	If (This.selectedConversation#Null)
		$selection.push(This.selectedConversation)
	End if 
	LISTBOX SELECT ROWS(*; "lbConversations"; $selection; lk replace selection)
	This.restoringConversationSelection:=False


Function updateConversationUnread($conversationId : Integer; $isRead : Boolean)->$found : Boolean
	var $conversation : Object
	
	$found:=False
	For each ($conversation; This.conversations) while (Not($found))
		If ($conversation.ID=$conversationId)
			If ($isRead)
				$conversation.unreadCount:=0
			Else 
				$conversation.unreadCount:=$conversation.unreadCount+1
			End if 
			$found:=True
		End if 
	End for each 
	If ($found)
		// Refresh row expressions without replacing the collection or its selected object.
		This.conversations:=This.conversations
	End if 


Function conversationTitle($conversation : Object)->$title : Text
	If ($conversation#Null)
		$title:=$conversation.title
	Else 
		$title:=""
	End if 


Function conversationStyle($conversation : Object)->$style : Integer
	$style:=Plain
	If (($conversation#Null) && ($conversation.unreadCount>0))
		$style:=Bold
	End if 


Function conversationColor($conversation : Object)->$color : Integer
	$color:=Foreground color
	If (($conversation#Null) && ($conversation.unreadCount=0))
		$color:=0x00555555
	End if 


Function setWindowTitle()
	var $user : cs.UtilisateurEntity
	var $userLabel : Text

	$userLabel:="Utilisateur #"+String(This.userId)
	$user:=ds.Utilisateur.get(This.userId)
	If ($user#Null)
		$userLabel:=$user.Nom
	End if 
	SET WINDOW TITLE("Messagerie — "+$userLabel; Current form window)


Function handleEvents()
	Case of 
		: (FORM Event.code=On Load)
			This.setWindowTitle()
			Messaging_Client_Set_window(Current form window; True)
			This.loadConversationPanel()

		: (FORM Event.code=On Unload)
			Messaging_Client_Set_window(Current form window; False)
			
		: (FORM Event.code=On Selection Change) && (FORM Event.objectName="lbConversations")
			If (Not(This.restoringConversationSelection))
				This.selectConversation()
			End if 

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnNewConversation")
			This.addConversation()
	End case 


Function selectConversation()
	var $conversation : Object
	
	$conversation:=Null
	If ((This.selectedConversationPosition>0) && (This.selectedConversationPosition<=This.conversations.length))
		$conversation:=This.conversations[This.selectedConversationPosition-1]
	Else 
		$conversation:=This.selectedConversation
	End if 
	
	If ($conversation#Null)
		This.conversationContext:=New object(\
		"userId"; This.userId; \
		"conversationId"; $conversation.ID; \
		"messageBody"; ""; \
		"lastNotificationId"; 0)
		Messaging_Server_Mark_latest(This.userId; $conversation.ID; "read")
		This.updateConversationUnread($conversation.ID; True)
		Launcher_Client_Refresh
	Else 
		This.conversationContext:=New object(\
		"userId"; This.userId; \
		"conversationId"; 0; \
		"messageBody"; ""; \
		"lastNotificationId"; 0)
	End if 
	
	This.loadConversationPanel()


Function loadConversationPanel()
	var $panelForm : Object
	var $left; $top; $right; $bottom; $panelHeight; $panelWidth; $conversationId : Integer
	
	$conversationId:=This.conversationContext.conversationId
	OBJECT SET VISIBLE(*; "subformConversation"; $conversationId>0)
	If ($conversationId>0)
		OBJECT GET COORDINATES(*; "subformConversation"; $left; $top; $right; $bottom)
		$panelHeight:=$bottom-$top
		$panelWidth:=$right-$left
		$panelForm:=Build_conversation_panel_form(This.userId; $conversationId; $panelHeight; $panelWidth)
		OBJECT SET SUBFORM(*; "subformConversation"; $panelForm)
	End if 


Function processNotification($kind : Text; $conversationId : Integer)
	var $activeConversationId : Integer
	
	$activeConversationId:=This.conversationContext.conversationId
	If ($kind="message")
		If ($conversationId=$activeConversationId)
			Messaging_Server_Mark_latest(This.userId; $activeConversationId; "read")
			This.updateConversationUnread($conversationId; True)
		Else 
			If (Not(This.updateConversationUnread($conversationId; False)))
				This.refreshConversations()
			End if 
		End if 
	End if 
	If ($conversationId=$activeConversationId)
		This.loadConversationPanel()
	End if 


Function addConversation()
	var $window : Integer
	var $formData; $response; $recipient : Object
	var $recipientIds : Collection
	
	$formData:={handler: cs.FormConversationCreator.new(This.userId)}
	$window:=Open form window("ConversationCreator"; Movable form dialog box)
	DIALOG("ConversationCreator"; $formData)
	If ((OK=1) && ($formData.handler.selectedRecipients#Null))
		$recipientIds:=New collection
		For each ($recipient; $formData.handler.selectedRecipients)
			$recipientIds.push($recipient.ID)
		End for each 
		$response:=Messaging_Server_Create(This.userId; $recipientIds; $formData.handler.groupTitle)
		If ($response.success)
			This.conversationContext:=New object(\
			"userId"; This.userId; \
			"conversationId"; $response.conversationId; \
			"messageBody"; ""; \
			"lastNotificationId"; 0)
			This.refreshConversations()
			This.loadConversationPanel()
		Else 
			ALERT($response.error)
		End if 
	End if 
	CLOSE WINDOW($window)
