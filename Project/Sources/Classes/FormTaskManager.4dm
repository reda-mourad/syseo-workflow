property userId : Integer
property showAll : Integer
property onlyMine : Integer
property onlyDelegated : Integer
property onlyToday : Integer
property showCompleted : Integer
property searchText : Text
property taskCounter : Text
property tasks : cs.TaskSelection
property currentTask : cs.TaskEntity
property selectedAssignees : cs.UtilisateurSelection
property selectedCategories : cs.TagSelection

Class constructor($userId : Integer)
	This.userId:=$userId
	This.showAll:=0
	This.onlyMine:=1
	This.onlyDelegated:=0
	This.showCompleted:=0
	This.searchText:=""
	This.taskCounter:=""
	This.load()
	
	
Function load()
	var $settings : Object
	var $criteria : Collection
	var $searchPattern : Text
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
		$criteria.push("due_at = :today")
		$settings.parameters.today:=String(Current date; ISO date)+"@"
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
	$remainingTaskCount:=This.tasks.query("completed_at = null").length
	If ($remainingTaskCount=1)
		This.taskCounter:="1 tâche restante"
	Else 
		This.taskCounter:=String($remainingTaskCount)+" tâches restantes"
	End if 
	
	
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
	If ((This.currentTask#Null) && (This.currentTask.ID_Patient#Null))
		$fullName:=This.currentTask.patient.Nom+" "+This.currentTask.patient.Prénom
	Else 
		$fullName:=""
	End if 


Function assigneeNames()->$names : Text
	If (This.currentTask=Null)
		$names:=""
	Else 
		If (This.selectedAssignees#Null)
			$names:=This.selectedAssignees.Nom.join(", ")
		Else 
			$names:=This.currentTask.assignees.utilisateur.Nom.join(", ")
		End if 
	End if 


Function categoryLabels()->$labels : Text
	If (This.currentTask=Null)
		$labels:=""
	Else 
		If (This.selectedCategories#Null)
			$labels:=This.selectedCategories.label.join(", ")
		Else 
			$labels:=This.currentTask.taskTags.tag.label.join(", ")
		End if 
	End if 


Function findPatient()
	var $window : Integer
	var $formData : Object

	If (This.currentTask#Null)
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

	If (This.currentTask#Null)
		$formData:={handler: cs.FormAssigneeSelector.new()}
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

	If (This.currentTask#Null)
		$formData:={handler: cs.FormCategorySelector.new()}
		$window:=Open form window("CategorySelector"; Movable form dialog box)
		DIALOG("CategorySelector"; $formData)
		If ((OK=1) && ($formData.handler.selectedCategories#Null) && ($formData.handler.selectedCategories.length>0))
			This.selectedCategories:=$formData.handler.selectedCategories
		End if 
		CLOSE WINDOW($window)
	End if 


Function handleEvents()
	Case of 
		: (FORM Event.code=On Clicked) && ((FORM Event.objectName="chk@") || (FORM Event.objectName="rdb@"))
			This.load()
			
		: (FORM Event.code=On Data Change) && (FORM Event.objectName="inputSearch")
			This.load()
			
			
		: (FORM Event.code=On Clicked) && (FORM Event.objectName="lbTasks") && (FORM Event.row>0)
			This.selectedAssignees:=Null
			This.selectedCategories:=Null
			FORM GOTO PAGE(2)

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnFindPatient")
			This.findPatient()

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnSelectAssignees")
			This.selectAssignees()

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="btnSelectCategories")
			This.selectCategories()
			
			
		: (FORM Event.code=On Page Change) && (FORM Get current page()=2)
			If (Form.users=Null)
				Form.users:=ds.Utilisateur.all().toCollection("xNumUser, Nom").orderBy("Nom")
			End if 
			
	End case 
	
	
