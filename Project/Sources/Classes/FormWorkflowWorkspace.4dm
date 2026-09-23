property userId : Integer
property userName : Text
property activeFeature : Text
property initialFeature : Text
property messageBadge : Text
property taskBadge : Text
property taskContext : Object
property messageContext : Object
property tasksLoaded : Boolean
property messagesLoaded : Boolean

Class constructor($userId : Integer)
	var $user : cs.UtilisateurEntity

	This.userId:=$userId
	This.userName:="Utilisateur #"+String($userId)
	$user:=ds.Utilisateur.get($userId)
	If ($user#Null)
		This.userName:=$user.Nom
	End if
	This.activeFeature:=""
	This.initialFeature:="tasks"
	This.messageBadge:="0"
	This.taskBadge:="0"
	This.tasksLoaded:=False
	This.messagesLoaded:=False
	This.taskContext:={handler: cs.FormTaskManager.new($userId)}
	This.messageContext:={handler: cs.FormConversationList.new($userId)}
	This.taskContext.handler.embedded:=True
	This.messageContext.handler.embedded:=True

Function refreshBadges()
	var $response : Object
	$response:=Launcher_Server_Counts(This.userId)
	If ($response.success)
		This.messageBadge:=String($response.unreadConversations)
		This.taskBadge:=String($response.unfinishedTasks)
	End if
	OBJECT SET VISIBLE(*; "bgTasksBadge"; Num(This.taskBadge)>0)
	OBJECT SET VISIBLE(*; "inputTasksBadge"; Num(This.taskBadge)>0)
	OBJECT SET VISIBLE(*; "bgMessagesBadge"; Num(This.messageBadge)>0)
	OBJECT SET VISIBLE(*; "inputMessagesBadge"; Num(This.messageBadge)>0)

Function showFeature($feature : Text)
	If ($feature#This.activeFeature)
		If ((This.activeFeature="tasks") && This.taskContext.handler.draftTransaction)
			EXECUTE METHOD IN SUBFORM("subformTasks"; Formula(Form.handler.resetTaskChanges()))
		End if
		This.activeFeature:=$feature
		OBJECT SET VISIBLE(*; "subformTasks"; $feature="tasks")
		OBJECT SET VISIBLE(*; "subformMessages"; $feature="messages")
		If ($feature="tasks")
			If (Not(This.tasksLoaded))
				OBJECT SET SUBFORM(*; "subformTasks"; "TaskManager")
				This.tasksLoaded:=True
			Else
				EXECUTE METHOD IN SUBFORM("subformTasks"; Formula(Form.handler.load()))
				If (This.taskContext.handler.currentTask#Null)
					EXECUTE METHOD IN SUBFORM("subformTasks"; Formula(Form.handler.loadDiscussionPanel()))
				End if
			End if
		Else
			If (Not(This.messagesLoaded))
				OBJECT SET SUBFORM(*; "subformMessages"; "ConversationList")
				This.messagesLoaded:=True
			Else
				EXECUTE METHOD IN SUBFORM("subformMessages"; Formula(Form.handler.processNotification("message"; Form.handler.conversationContext.conversationId)))
			End if
		End if
	End if
	OBJECT SET RGB COLORS(*; "bgTasksButton"; "#C0C0C0"; "#FFFFFF")
	OBJECT SET RGB COLORS(*; "bgMessagesButton"; "#C0C0C0"; "#FFFFFF")
	If ($feature="tasks")
		OBJECT SET RGB COLORS(*; "bgTasksButton"; "#C0C0C0"; "#80DEEA")
	Else
		OBJECT SET RGB COLORS(*; "bgMessagesButton"; "#C0C0C0"; "#80DEEA")
	End if
	This.refreshBadges()
	Launcher_Client_Refresh

Function openTaskFromMessage($description : Text)
	This.showFeature("tasks")
	EXECUTE METHOD IN SUBFORM("subformTasks"; "Task_Client_Form_from_message"; *; $description)

Function processNotification($kind : Text; $conversationId : Integer)
	If (This.activeFeature="messages")
		EXECUTE METHOD IN SUBFORM("subformMessages"; "Messaging_Client_Form_notify"; *; $kind; $conversationId; 0; 0; "")
	Else
		EXECUTE METHOD IN SUBFORM("subformTasks"; "Messaging_Client_Form_notify"; *; $kind; $conversationId; 0; 0; "")
	End if
	This.refreshBadges()

Function processTaskNotification($taskId : Integer)
	If (This.tasksLoaded && (This.activeFeature="tasks"))
		EXECUTE METHOD IN SUBFORM("subformTasks"; "Task_Client_Form_refresh"; *; $taskId)
	End if
	This.refreshBadges()

Function handleEvents()
	Case of
		: (FORM Event.code=On Load)
			SET WINDOW TITLE("Tâches et messagerie — "+This.userName; Current form window)
			Launcher_Client_Set_window(Current form window; True)
			Messaging_Client_Set_window(Current form window; True)
			Task_Client_Set_window(Current form window; True)
			This.showFeature(This.initialFeature)
		: (FORM Event.code=On Unload)
			This.taskContext.handler.rollbackTaskDraft()
			Launcher_Client_Set_window(Current form window; False)
			Messaging_Client_Set_window(Current form window; False)
			Task_Client_Set_window(Current form window; False)
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnTasks")
			This.showFeature("tasks")
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnMessages")
			This.showFeature("messages")
	End case
