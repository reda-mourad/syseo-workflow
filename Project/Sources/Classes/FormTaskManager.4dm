property userId : Integer
property pageTitle : Text
property embedded : Boolean
property showAll : Integer
property onlyMine : Integer
property onlyDelegated : Integer
property onlyToday : Integer
property showCompleted : Integer
property searchText : Text
property taskCounter : Text
property taskUnreadCounts : Object
property tasks : cs.TaskSelection
property selectedTask : cs.TaskEntity
property currentTask : cs.TaskEntity
property selectedAssignees : cs.UtilisateurSelection
property selectedCategories : cs.TagSelection
property discussionContext : Object
property originalUrgency : Boolean
property initialDraft : Object

Class constructor($userId : Integer)
	This.userId:=$userId
	This.pageTitle:="Liste des tâches"
	This.embedded:=False
	This.showAll:=0
	This.onlyMine:=1
	This.onlyDelegated:=0
	This.showCompleted:=0
	This.searchText:=""
	This.taskCounter:=""
	This.taskUnreadCounts:=New object
	This.originalUrgency:=False
	This.initialDraft:=Null
	This.discussionContext:=New object("userId"; $userId; "conversationId"; 0; "messageBody"; ""; "lastNotificationId"; 0)
	This.load()
	
	
Function load()
	var $settings : Object
	var $criteria : Collection
	var $searchPattern; $todayStart; $tomorrowStart : Text
	var $remainingTaskCount : Integer
	
	$settings:={parameters: {}}
	$criteria:=[]
	$criteria.push("ID # null")
	
	If (Bool(This.onlyMine))
		$criteria.push("assignees.ID_Utilisateur = :ID_Utilisateur")
		$settings.parameters.ID_Utilisateur:=This.userId
	Else 
		If (Bool(This.onlyDelegated))
			$criteria.push("ID_creator = :ID_creator")
			$settings.parameters.ID_creator:=This.userId
		End if 
	End if 
	
	If (Bool(This.onlyToday))
		$todayStart:=String(Current date; ISO date)
		$tomorrowStart:=String(Current date+1; ISO date)
		$criteria.push("due_at >= :todayStart AND due_at < :tomorrowStart")
		$settings.parameters.todayStart:=$todayStart
		$settings.parameters.tomorrowStart:=$tomorrowStart
	End if 
	
	If (Not(Bool(This.showCompleted)))
		$criteria.push("completed_at = null")
	End if 
	
	If (Length(This.searchText)>0)
		$searchPattern:="@"+This.searchText+"@"
		$criteria.push("(description = :searchPattern OR description = :searchPattern OR patient.Nom = :searchPattern OR creator.Nom = :searchPattern OR assignees.utilisateur.Nom = :searchPattern OR taskTags.tag.label = :searchPattern)")
		$settings.parameters.searchPattern:=$searchPattern
	End if 
	
	This.tasks:=ds.Task.query($criteria.join(" AND "); $settings).orderBy("completed_at asc, is_urgent desc, due_at asc")
	This.loadUnreadMessageCounts()
	$remainingTaskCount:=This.tasks.query("completed_at = null").length
	If ($remainingTaskCount=1)
		This.taskCounter:="1 tâche restante"
	Else 
		This.taskCounter:=String($remainingTaskCount)+" tâches restantes"
	End if 


Function setWindowTitle()
	var $user : cs.UtilisateurEntity
	var $userLabel : Text

	$userLabel:="Utilisateur #"+String(This.userId)
	$user:=ds.Utilisateur.get(This.userId)
	If ($user#Null)
		$userLabel:=$user.Nom
	End if 
	SET WINDOW TITLE("Gestion des tâches — "+$userLabel; Current form window)


Function loadUnreadMessageCounts()
	var $task : cs.TaskEntity
	var $membership : cs.ConversationMemberEntity
	var $messageCount : Integer

	This.taskUnreadCounts:=New object
	For each ($task; This.tasks)
		$messageCount:=0
		If ($task.ID_Conversation#Null)
			$membership:=ds.ConversationMember.query("ID_Conversation = :1 AND ID_Utilisateur = :2 AND left_at = null"; $task.ID_Conversation; This.userId).first()
			If ($membership#Null)
				If ($membership.ID_last_read_message#Null)
					$messageCount:=ds.Message.query("ID_Conversation = :1 AND ID_sender # :2 AND ID > :3 AND deleted_at = null"; $task.ID_Conversation; This.userId; $membership.ID_last_read_message).length
				Else 
					$messageCount:=ds.Message.query("ID_Conversation = :1 AND ID_sender # :2 AND deleted_at = null"; $task.ID_Conversation; This.userId).length
				End if 
			End if 
		End if 
		This.taskUnreadCounts["task"+String($task.ID)]:=$messageCount
	End for each 


Function taskUnreadMessageCount($taskId : Integer)->$count : Integer
	$count:=This.taskUnreadCounts["task"+String($taskId)]
	
	
Function completionEmoji($isCompleted : Boolean; $isUrgent : Boolean)->$emoji : Text
	If ($isCompleted)
		$emoji:="✅"
	Else 
		If ($isUrgent)
			$emoji:="🚨"
		Else 
			$emoji:="⏳"
		End if 
	End if 
	
	
Function taskFontColor($isCompleted : Boolean; $isUrgent : Boolean)->$color : Integer
	If ($isUrgent && Not($isCompleted))
		$color:=0x00FF0000
	Else 
		$color:=lk inherited
	End if 
	
	
Function taskFontStyle($isCompleted : Boolean; $isUrgent : Boolean)->$style : Integer
	If ($isUrgent && Not($isCompleted))
		$style:=Bold
	Else 
		$style:=lk inherited
	End if 
	
	
Function patientFullName()->$fullName : Text
	var $patient : cs.PatientEntity
	var $birthDate; $today : Date
	var $age : Integer
	var $ageDisplay : Text

	$fullName:=""
	If ((This.currentTask#Null) && (This.currentTask.ID_Patient#Null))
		$patient:=This.currentTask.patient
		If ($patient#Null)
			$birthDate:=$patient["Date Naissance"]
			$today:=Current date
			$ageDisplay:="Âge non renseigné"
			If (($birthDate#!00-00-00!) && ($birthDate<=$today))
				$age:=Year of($today)-Year of($birthDate)
				If ((Month of($today)<Month of($birthDate)) || ((Month of($today)=Month of($birthDate)) && (Day of($today)<Day of($birthDate))))
					$age:=$age-1
				End if
				If ($age=1)
					$ageDisplay:="1 an"
				Else
					$ageDisplay:=String($age)+" ans"
				End if
			End if
			$fullName:=$patient.Nom+" "+$patient.Prénom+" - "+Patient_Gender($patient)+" - "+$ageDisplay
		End if
	End if 
	
	
Function taskPatientFullName($patient : cs.PatientEntity)->$fullName : Text
	If ($patient#Null)
		$fullName:=$patient.Nom+" "+$patient.Prénom
	Else 
		$fullName:=""
	End if 
	
	
Function taskDueDate($dueAt : Text)->$display : Text
	var $dueDate : Date
	var $remainingDays : Integer
	
	$display:=""
	If (Length($dueAt)>0)
		$dueDate:=Date($dueAt)
		If ($dueDate#!00-00-00!)
			$remainingDays:=$dueDate-Current date
			$display:=String($dueDate; System date short)+" ("+String($remainingDays)+")"
		End if 
	End if 
	
	
Function assigneeNames()->$names : Text
	If (This.currentTask=Null)
		$names:=""
	Else 
		If (This.selectedAssignees#Null)
			$names:=This.selectedAssignees.Nom.join(" + ")
		Else 
			$names:=This.currentTask.assignees.utilisateur.Nom.join(" + ")
		End if 
	End if 
	
	
Function categoryLabels()->$labels : Text
	If (This.currentTask=Null)
		$labels:=""
	Else 
		If (This.selectedCategories#Null)
			$labels:=This.selectedCategories.orderBy("label asc, ID asc").label.join(" + ")
		Else 
			$labels:=This.currentTask.taskTags.tag.orderBy("label asc, ID asc").label.join(" + ")
		End if 
	End if 
	
	
Function canEditTask()->$canEdit : Boolean
	$canEdit:=(This.currentTask#Null) && (This.currentTask.completed_at=Null) && (This.currentTask.ID_creator=This.userId)
	
	
Function canCloseTask()->$canClose : Boolean
	var $assignments : cs.TaskAssigneeSelection
	
	$canClose:=This.canEditTask() && Not(This.currentTask.isNew())
	If ((This.currentTask#Null) && (This.currentTask.completed_at=Null) && Not($canClose))
		If (Not(This.currentTask.isNew()))
			$assignments:=ds.TaskAssignee.query("ID_Task = :1 AND ID_Utilisateur = :2"; This.currentTask.ID; This.userId)
			$canClose:=($assignments.length>0)
		End if 
	End if 
	
	
Function canDeleteTask()->$canDelete : Boolean
	$canDelete:=(This.currentTask#Null) && Not(This.currentTask.isNew()) && (This.currentTask.ID_creator=This.userId)


Function updateTaskEditState()
	var $canEdit; $canClose; $canDelete : Boolean
	var $backgroundColor : Text
	
	$canEdit:=This.canEditTask()
	$canClose:=This.canCloseTask()
	$canDelete:=This.canDeleteTask()
	OBJECT SET ENABLED(*; "btnUrgent"; $canEdit)
	OBJECT SET ENABLED(*; "btnSelectAssignees"; $canEdit)
	OBJECT SET ENABLED(*; "btnSelectCategories"; $canEdit)
	OBJECT SET ENABLED(*; "btnFindPatient"; $canEdit)
	OBJECT SET ENABLED(*; "btnSave"; $canEdit)
	OBJECT SET ENABLED(*; "btnComplete"; $canClose)
	OBJECT SET VISIBLE(*; "bgDelete"; $canDelete)
	OBJECT SET VISIBLE(*; "btnDelete"; $canDelete)
	
	If ($canEdit)
		OBJECT SET ENTERABLE(*; "inputDueDate"; obk enterable)
		OBJECT SET ENTERABLE(*; "inputDescription"; obk enterable)
		$backgroundColor:="#FFFFFF"
		OBJECT SET RGB COLORS(*; "bgSave"; ""; "#C1F3A0")
	Else 
		OBJECT SET ENTERABLE(*; "inputDueDate"; obk not enterable not focusable)
		OBJECT SET ENTERABLE(*; "inputDescription"; obk not enterable not focusable)
		$backgroundColor:="transparent"
		OBJECT SET RGB COLORS(*; "bgSave"; ""; "transparent")
	End if 
	If ($canClose)
		OBJECT SET RGB COLORS(*; "bgComplete"; ""; "#F3DEF3")
	Else 
		OBJECT SET RGB COLORS(*; "bgComplete"; ""; "transparent")
	End if 
	
	OBJECT SET RGB COLORS(*; "bgAssignees"; ""; $backgroundColor)
	OBJECT SET RGB COLORS(*; "bgCategories"; ""; $backgroundColor)
	OBJECT SET RGB COLORS(*; "bgDueDate"; ""; $backgroundColor)
	OBJECT SET RGB COLORS(*; "bgPatient"; ""; $backgroundColor)
	OBJECT SET RGB COLORS(*; "bgDescription"; ""; $backgroundColor)
	This.updateUrgentButton()
	
	
Function findPatient()
	var $window : Integer
	var $formData : Object
	
	If (This.canEditTask())
		$formData:={handler: cs.FormPatientFinder.new()}
		$window:=Open form window("PatientFinder"; Movable form dialog box)
		DIALOG("PatientFinder"; $formData)
		If ((OK=1) && ($formData.handler.currentPatient#Null))
			This.currentTask.ID_Patient:=$formData.handler.currentPatient.NoDossier
		End if 
		CLOSE WINDOW($window)
	End if 
	
	
Function selectAssignees()
	var $window : Integer
	var $formData : Object
	var $initialAssignees : cs.UtilisateurSelection
	
	If (This.canEditTask())
		If (This.selectedAssignees#Null)
			$initialAssignees:=This.selectedAssignees
		Else 
			$initialAssignees:=This.currentTask.assignees.utilisateur
		End if 
		$formData:={handler: cs.FormAssigneeSelector.new($initialAssignees)}
		$window:=Open form window("AssigneeSelector"; Movable form dialog box)
		DIALOG("AssigneeSelector"; $formData)
		If ((OK=1) && ($formData.handler.selectedAssignees#Null) && ($formData.handler.selectedAssignees.length>0))
			This.selectedAssignees:=$formData.handler.selectedAssignees
		End if 
		CLOSE WINDOW($window)
	End if 
	
	
Function selectCategories()
	var $window : Integer
	var $formData : Object
	var $initialCategories : cs.TagSelection
	
	If (This.canEditTask())
		If (This.selectedCategories#Null)
			$initialCategories:=This.selectedCategories
		Else 
			$initialCategories:=This.currentTask.taskTags.tag
		End if 
		$formData:={handler: cs.FormCategorySelector.new($initialCategories)}
		$window:=Open form window("CategorySelector"; Movable form dialog box)
		DIALOG("CategorySelector"; $formData)
		If ((OK=1) && ($formData.handler.selectedCategories#Null) && ($formData.handler.selectedCategories.length>0))
			This.selectedCategories:=$formData.handler.selectedCategories
		End if 
		CLOSE WINDOW($window)
	End if 
	
	
Function saveAssignees()->$success : Boolean
	var $existingAssignees : cs.TaskAssigneeSelection
	var $notDropped : cs.TaskAssigneeSelection
	var $assignee : cs.TaskAssigneeEntity
	var $selectedAssignee : cs.UtilisateurEntity
	var $result : Object
	var $assignedAt : Text
	
	$success:=True
	If (This.selectedAssignees#Null)
		$existingAssignees:=ds.TaskAssignee.query("ID_Task = :1"; This.currentTask.ID)
		$notDropped:=$existingAssignees.drop(dk stop dropping on first error)
		$success:=($notDropped.length=0)
		$assignedAt:=String(Current date; ISO date; Current time)
		For each ($selectedAssignee; This.selectedAssignees)
			If ($success)
				$assignee:=ds.TaskAssignee.new()
				$assignee.ID_Task:=This.currentTask.ID
				$assignee.ID_Utilisateur:=$selectedAssignee.xNumUser
				$assignee.assigned_at:=$assignedAt
				$result:=$assignee.save()
				$success:=$result.success
			End if 
		End for each 
	End if 
	
	
Function saveCategories()->$success : Boolean
	var $notDropped : cs.TaskTagSelection
	var $taskTag : cs.TaskTagEntity
	var $selectedCategory : cs.TagEntity
	var $result : Object
	
	$success:=True
	If (This.selectedCategories#Null)
		$notDropped:=This.currentTask.taskTags.drop(dk stop dropping on first error)
		$success:=($notDropped.length=0)
		For each ($selectedCategory; This.selectedCategories)
			If ($success)
				$taskTag:=ds.TaskTag.new()
				$taskTag.task:=This.currentTask
				$taskTag.tag:=$selectedCategory
				$result:=$taskTag.save()
				$success:=$result.success
			End if 
		End for each 
	End if 
	
	
Function syncTaskConversation()->$success : Boolean
	var $conversation : cs.ConversationEntity
	var $members : cs.ConversationMemberSelection
	var $member : cs.ConversationMemberEntity
	var $assignee : cs.UtilisateurEntity
	var $user : cs.UtilisateurEntity
	var $saveStatus : Object
	var $participantIds : Collection
	var $participantId : Integer
	var $timestamp; $title : Text
	var $isParticipant : Boolean

	$success:=True
	$timestamp:=String(Current date; ISO date; Current time)
	$conversation:=This.currentTask.conversation
	If ($conversation=Null)
		$conversation:=ds.Conversation.new()
		$conversation.kind:="task"
		$conversation.ID_creator:=This.currentTask.ID_creator
		$conversation.created_at:=$timestamp
		$conversation.updated_at:=$timestamp
	End if 

	$title:="Tâche #"+String(This.currentTask.ID)
	If (Length(This.currentTask.description)>0)
		$title:=$title+" — "+This.currentTask.description
	End if 
	$conversation.name:=Substring($title; 1; 255)
	$saveStatus:=$conversation.save()
	$success:=$saveStatus.success

	If ($success && (This.currentTask.ID_Conversation=Null))
		This.currentTask.ID_Conversation:=$conversation.ID
		$saveStatus:=This.currentTask.save()
		$success:=$saveStatus.success
	End if 

	$participantIds:=New collection
	If ($success && (This.currentTask.ID_creator#Null))
		$participantIds.push(This.currentTask.ID_creator)
	End if 
	If ($success)
		If (This.selectedAssignees#Null)
			For each ($assignee; This.selectedAssignees)
				If ($participantIds.indexOf($assignee.xNumUser)<0)
					$participantIds.push($assignee.xNumUser)
				End if 
			End for each 
		Else 
			For each ($assignee; This.currentTask.assignees.utilisateur)
				If ($participantIds.indexOf($assignee.xNumUser)<0)
					$participantIds.push($assignee.xNumUser)
				End if 
			End for each 
		End if 
	End if 

	If ($success)
		$members:=ds.ConversationMember.query("ID_Conversation = :1"; $conversation.ID)
		For each ($member; $members) while ($success)
			$isParticipant:=($participantIds.indexOf($member.ID_Utilisateur)>=0)
			If ($isParticipant)
				$member.left_at:=Null
				$member.notifications_enabled:=True
			Else 
				$member.left_at:=$timestamp
			End if 
			$saveStatus:=$member.save()
			$success:=$saveStatus.success
		End for each 
	End if 

	For each ($participantId; $participantIds) while ($success)
		If ($members.query("ID_Utilisateur = :1"; $participantId).length=0)
			$user:=ds.Utilisateur.get($participantId)
			If ($user=Null)
				$success:=False
			Else 
				$member:=ds.ConversationMember.new()
				$member.conversation:=$conversation
				$member.utilisateur:=$user
				$member.joined_at:=$timestamp
				$member.notifications_enabled:=True
				$saveStatus:=$member.save()
				$success:=$saveStatus.success
			End if 
		End if 
	End for each 


Function saveTask()->$success : Boolean
	var $result : Object
	var $previousAssignments; $currentAssignments : cs.TaskAssigneeSelection
	var $assignment : cs.TaskAssigneeEntity
	var $previousIds; $currentIds; $affectedIds; $urgentIds; $refreshIds : Collection
	var $assigneeId; $taskId : Integer
	var $wasUrgent : Boolean
	
	$success:=False
	If (This.canEditTask())
		$previousIds:=New collection
		$currentIds:=New collection
		$affectedIds:=New collection
		$urgentIds:=New collection
		$refreshIds:=New collection
		$wasUrgent:=This.originalUrgency
		If (Not(This.currentTask.isNew()))
			$previousAssignments:=ds.TaskAssignee.query("ID_Task = :1"; This.currentTask.ID)
			For each ($assignment; $previousAssignments)
				$previousIds.push($assignment.ID_Utilisateur)
			End for each 
		End if 
		
		ds.startTransaction()
		This.currentTask.updated_at:=String(Current date; ISO date; Current time)
		$result:=This.currentTask.save()
		$success:=$result.success
		If ($success)
			$success:=This.saveAssignees()
		End if 
		If ($success)
			$success:=This.saveCategories()
		End if 
		If ($success)
			$success:=This.syncTaskConversation()
		End if 
		
		If ($success)
			ds.validateTransaction()
			$taskId:=This.currentTask.ID
			$currentAssignments:=ds.TaskAssignee.query("ID_Task = :1"; $taskId)
			For each ($assignment; $currentAssignments)
				$currentIds.push($assignment.ID_Utilisateur)
			End for each 
			For each ($assigneeId; $previousIds)
				If ($affectedIds.indexOf($assigneeId)<0)
					$affectedIds.push($assigneeId)
				End if 
			End for each 
			For each ($assigneeId; $currentIds)
				If ($affectedIds.indexOf($assigneeId)<0)
					$affectedIds.push($assigneeId)
				End if 
				If (This.currentTask.is_urgent && (Not($wasUrgent) || ($previousIds.indexOf($assigneeId)<0)))
					$urgentIds.push($assigneeId)
				End if 
			End for each 
			For each ($assigneeId; $affectedIds)
				If ($urgentIds.indexOf($assigneeId)<0)
					$refreshIds.push($assigneeId)
				End if 
			End for each 
			Task_Server_Notify_clients($refreshIds; $taskId; This.userId; "changed")
			Task_Server_Notify_clients($urgentIds; $taskId; This.userId; "urgent")
			This.originalUrgency:=This.currentTask.is_urgent
			This.selectedAssignees:=Null
			This.selectedCategories:=Null
			This.load()
			Launcher_Client_Refresh
			This.goToPage(1)
		Else 
			ds.cancelTransaction()
			ALERT("La tâche n'a pas pu être enregistrée. Veuillez réessayer.")
		End if 
	End if 
	
	
Function closeTask()->$success : Boolean
	var $result : Object
	var $assignment : cs.TaskAssigneeEntity
	var $assignments : cs.TaskAssigneeSelection
	var $recipientIds : Collection
	var $recipientId; $taskId : Integer
	var $completedAt : Text
	
	$success:=False
	If (This.canCloseTask())
		$taskId:=This.currentTask.ID
		$recipientIds:=New collection
		$assignments:=ds.TaskAssignee.query("ID_Task = :1"; $taskId)
		For each ($assignment; $assignments)
			If ($recipientIds.indexOf($assignment.ID_Utilisateur)<0)
				$recipientIds.push($assignment.ID_Utilisateur)
			End if 
		End for each 
		$recipientId:=This.currentTask.ID_creator
		If (($recipientId>0) && ($recipientIds.indexOf($recipientId)<0))
			$recipientIds.push($recipientId)
		End if 
		$completedAt:=String(Current date; ISO date; Current time)
		This.currentTask.completed_at:=$completedAt
		This.currentTask.updated_at:=$completedAt
		$result:=This.currentTask.save()
		$success:=$result.success
		If ($success)
			Task_Server_Notify_clients($recipientIds; $taskId; This.userId; "completed")
			This.load()
			Launcher_Client_Refresh
			This.goToPage(1)
		Else 
			This.currentTask.reload()
			ALERT("La tâche n'a pas pu être clôturée. Veuillez réessayer.")
		End if 
	End if 
	
	
Function deleteTask()->$success : Boolean
	var $assignments : cs.TaskAssigneeSelection
	var $assignment : cs.TaskAssigneeEntity
	var $notDroppedAssignments : cs.TaskAssigneeSelection
	var $notDroppedTags : cs.TaskTagSelection
	var $notDroppedMembers : cs.ConversationMemberSelection
	var $notDroppedMessages : cs.MessageSelection
	var $conversation : cs.ConversationEntity
	var $result : Object
	var $recipientIds : Collection
	var $recipientId; $taskId; $conversationId : Integer

	$success:=False
	If (This.canDeleteTask())
		CONFIRM("Supprimer définitivement cette tâche ?")
		If (OK=1)
			$taskId:=This.currentTask.ID
			$conversationId:=0
			If (This.currentTask.ID_Conversation#Null)
				$conversationId:=This.currentTask.ID_Conversation
			End if 
			$recipientIds:=New collection
			$assignments:=ds.TaskAssignee.query("ID_Task = :1"; $taskId)
			For each ($assignment; $assignments)
				$recipientId:=$assignment.ID_Utilisateur
				If ($recipientIds.indexOf($recipientId)<0)
					$recipientIds.push($recipientId)
				End if 
			End for each 

			ds.startTransaction()
			$notDroppedTags:=ds.TaskTag.query("ID_Task = :1"; $taskId).drop(dk stop dropping on first error)
			$success:=($notDroppedTags.length=0)
			If ($success)
				$notDroppedAssignments:=$assignments.drop(dk stop dropping on first error)
				$success:=($notDroppedAssignments.length=0)
			End if 
			If ($success)
				$result:=This.currentTask.drop()
				$success:=$result.success
			End if 

			If ($success && ($conversationId>0) && (ds.Task.query("ID_Conversation = :1"; $conversationId).length=0))
				$notDroppedMembers:=ds.ConversationMember.query("ID_Conversation = :1"; $conversationId).drop(dk stop dropping on first error)
				$success:=($notDroppedMembers.length=0)
				If ($success)
					$notDroppedMessages:=ds.Message.query("ID_Conversation = :1"; $conversationId).drop(dk stop dropping on first error)
					$success:=($notDroppedMessages.length=0)
				End if 
				If ($success)
					$conversation:=ds.Conversation.get($conversationId)
					If ($conversation#Null)
						$result:=$conversation.drop()
						$success:=$result.success
					End if 
				End if 
			End if 

			If ($success)
				ds.validateTransaction()
				Task_Server_Notify_clients($recipientIds; $taskId; This.userId; "deleted")
				This.currentTask:=Null
				This.selectedAssignees:=Null
				This.selectedCategories:=Null
				This.load()
				Launcher_Client_Refresh
				This.goToPage(1)
			Else 
				ds.cancelTransaction()
				ALERT("La tâche n'a pas pu être supprimée. Veuillez réessayer.")
			End if 
		End if 
	End if 


Function updateUrgentButton()
	If (Not(This.canEditTask()))
		OBJECT SET RGB COLORS(*; "bgUrgent"; "#c0c0c0"; "transparent")
		OBJECT SET RGB COLORS(*; "btnUrgent"; "#000000")
	Else 
		If (This.currentTask.is_urgent)
			OBJECT SET RGB COLORS(*; "bgUrgent"; "#c0c0c0"; "#FF0000")
			OBJECT SET RGB COLORS(*; "btnUrgent"; "#FFFFFF")
		Else 
			OBJECT SET RGB COLORS(*; "bgUrgent"; "#c0c0c0"; "#FFFFFF")
			OBJECT SET RGB COLORS(*; "btnUrgent"; "#000000")
		End if 
	End if 
	
	
Function toggleUrgent()
	If (This.canEditTask())
		This.currentTask.is_urgent:=Not(This.currentTask.is_urgent)
		This.updateUrgentButton()
	End if 
	
	
Function prepareNewTask($description : Text)
	var $creator : cs.UtilisateurEntity
	var $createdAt : Text
	
	$creator:=ds.Utilisateur.get(This.userId)
	If ($creator=Null)
		ALERT("La tâche ne peut pas être créée car l'utilisateur courant est introuvable.")
	Else 
		$createdAt:=String(Current date; ISO date; Current time)
		This.currentTask:=ds.Task.new()
		This.currentTask.creator:=$creator
		This.currentTask.description:=$description
		This.currentTask.due_at:=String(Current date; ISO date)
		This.currentTask.created_at:=$createdAt
		This.currentTask.updated_at:=$createdAt
		This.currentTask.is_urgent:=False
		This.originalUrgency:=False
		This.selectedAssignees:=ds.Utilisateur.query("xNumUser = :1"; This.userId)
		This.selectedCategories:=Null
		This.goToPage(2)
	End if 


Function addTask()
	This.prepareNewTask("")


Function addTaskFromMessage()
	var $description : Text

	$description:=""
	If (This.initialDraft#Null)
		$description:=This.initialDraft.description
	End if 
	This.initialDraft:=Null
	This.prepareNewTask($description)

Function openTaskFromMessage($description : Text)
	// Return to the list first so entering the new draft triggers On Page Change.
	This.goToPage(1)
	This.prepareNewTask($description)
	
	
Function resetTaskChanges()->$success : Boolean
	var $result : Object
	
	$success:=True
	If (This.currentTask#Null)
		If (Not(This.currentTask.isNew()))
			$result:=This.currentTask.reload()
			$success:=$result.success
		End if 
	End if 
	
	If ($success)
		This.selectedAssignees:=Null
		This.selectedCategories:=Null
		This.load()
		This.currentTask:=Null
		This.goToPage(1)
	Else 
		ALERT("Les modifications n'ont pas pu être annulées. Veuillez réessayer.")
	End if 
	
	
Function loadDiscussionPanel()
	var $panelForm : Object
	var $left; $top; $right; $bottom; $panelHeight; $panelWidth; $conversationId : Integer

	$conversationId:=0
	If ((This.currentTask#Null) && (This.currentTask.ID_Conversation#Null))
		$conversationId:=This.currentTask.ID_Conversation
	End if 
	This.discussionContext:=New object("userId"; This.userId; "conversationId"; $conversationId; "messageBody"; ""; "lastNotificationId"; 0)
	OBJECT SET VISIBLE(*; "subformDiscussion"; $conversationId>0)
	If ($conversationId>0)
		Messaging_Server_Mark_latest(This.userId; $conversationId; "read")
		OBJECT GET COORDINATES(*; "subformDiscussion"; $left; $top; $right; $bottom)
		$panelHeight:=$bottom-$top
		$panelWidth:=$right-$left
		$panelForm:=Build_conversation_panel_form(This.userId; $conversationId; $panelHeight; $panelWidth)
		OBJECT SET SUBFORM(*; "subformDiscussion"; $panelForm)
	End if 


Function processNotification($kind : Text; $conversationId : Integer)
	If ((This.currentTask#Null) && (This.currentTask.ID_Conversation#Null) && (This.currentTask.ID_Conversation=$conversationId))
		If ($kind="message")
			Messaging_Server_Mark_latest(This.userId; $conversationId; "read")
		End if 
		This.loadDiscussionPanel()
	End if 


Function processTaskNotification($taskId : Integer)
	var $activeTaskId : Integer

	$activeTaskId:=0
	If ((This.currentTask#Null) && Not(This.currentTask.isNew()))
		$activeTaskId:=This.currentTask.ID
	End if 
	This.load()
	If (($activeTaskId>0) && ($activeTaskId=$taskId))
		This.currentTask:=ds.Task.get($taskId)
		If (This.currentTask#Null)
			This.originalUrgency:=This.currentTask.is_urgent
			If (This.currentPage()=2)
				This.updateTaskEditState()
				This.loadDiscussionPanel()
			End if 
		Else 
			This.goToPage(1)
		End if 
	End if 


Function goToPage($page : Integer)
	This.updatePageTitle($page)
	If (This.embedded)
		FORM GOTO PAGE($page; *)
	Else
		FORM GOTO PAGE($page)
	End if

Function updatePageTitle($page : Integer)
	This.pageTitle:="Liste des tâches"
	If (($page=2) && (This.currentTask#Null))
		If (This.currentTask.isNew())
			This.pageTitle:="Nouvelle tâche"
		Else
			This.pageTitle:="Modifier la tâche"
		End if
	End if

Function currentPage()->$page : Integer
	If (This.embedded)
		$page:=FORM Get current page(*)
	Else
		$page:=FORM Get current page()
	End if

Function handleEvents()
	If (FORM Event.code=On Page Change)
		This.updatePageTitle(This.currentPage())
	End if
	Case of 
		: (FORM Event.code=On Load)
			If (Not(This.embedded))
				This.setWindowTitle()
				Messaging_Client_Set_window(Current form window; True)
				Task_Client_Set_window(Current form window; True)
			End if
			Launcher_Client_Refresh
			If (This.initialDraft#Null)
				This.addTaskFromMessage()
			End if 

		: (FORM Event.code=On Unload)
			If (Not(This.embedded))
				Messaging_Client_Set_window(Current form window; False)
				Task_Client_Set_window(Current form window; False)
			End if

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnAddTask")
			This.addTask()
			
		: (FORM Event.code=On Clicked) && ((FORM Event.objectName="chk@") || (FORM Event.objectName="rdb@"))
			This.load()
			
		: (FORM Event.code=On Data Change) && (FORM Event.objectName="inputSearch")
			This.load()
			
			
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="lbTasks") && (FORM Event.row>0)
			If (This.selectedTask#Null)
				This.currentTask:=This.selectedTask
				This.originalUrgency:=This.currentTask.is_urgent
				This.selectedAssignees:=Null
				This.selectedCategories:=Null
				This.goToPage(2)
			End if 
			
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnFindPatient")
			This.findPatient()
			
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnSelectAssignees")
			This.selectAssignees()
			
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnSelectCategories")
			This.selectCategories()
			
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnSave")
			This.saveTask()
			
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnComplete")
			This.closeTask()

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnDelete")
			This.deleteTask()
			
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnUrgent")
			This.toggleUrgent()
			
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnBack")
			This.resetTaskChanges()
			
			
		: (FORM Event.code=On Page Change) && (This.currentPage()=2)
			This.updateTaskEditState()
			This.loadDiscussionPanel()
			If (Form.users=Null)
				Form.users:=ds.Utilisateur.all().toCollection("xNumUser, Nom").orderBy("Nom")
			End if 
			
	End case 
	
	
	
	
