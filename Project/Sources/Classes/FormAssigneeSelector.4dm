property searchText : Text
property assignees : Collection
property selectedAssignees : cs.UtilisateurSelection
property initialAssignees : cs.UtilisateurSelection
property selectedAssigneeIds : Collection

Class constructor($initialAssignees : cs.UtilisateurSelection)
	var $assignee : cs.UtilisateurEntity

	This.searchText:=""
	This.initialAssignees:=$initialAssignees
	This.selectedAssigneeIds:=New collection
	This.selectedAssignees:=ds.Utilisateur.newSelection()
	If (This.initialAssignees#Null)
		For each ($assignee; This.initialAssignees)
			This.selectedAssigneeIds.push($assignee.xNumUser)
			This.selectedAssignees.add($assignee)
		End for each 
	End if 
	This.load()


Function load()
	var $searchPattern : Text
	var $selection : cs.UtilisateurSelection
	var $assignee : cs.UtilisateurEntity

	If (Length(This.searchText)>0)
		$searchPattern:="@"+This.searchText+"@"
		$selection:=ds.Utilisateur.query("Nom = :1 OR Initiales = :1"; $searchPattern).orderBy("Nom asc")
	Else 
		$selection:=ds.Utilisateur.all().orderBy("Nom asc")
	End if 
	This.assignees:=New collection
	For each ($assignee; $selection)
		This.assignees.push(New object(\
		"ID"; $assignee.xNumUser; \
		"initials"; $assignee.Initiales; \
		"profile"; Workflow_User_Profile($assignee.Privilèges); \
		"name"; $assignee.Nom; \
		"selected"; This.selectedAssigneeIds.indexOf($assignee.xNumUser)>=0))
	End for each 


Function hasSelection()->$hasSelection : Boolean
	$hasSelection:=(This.selectedAssigneeIds.length>0)


Function toggleAssignee($row : Integer)
	var $assignee : Object

	If (($row>0) && ($row<=This.assignees.length))
		$assignee:=This.assignees[$row-1]
		$assignee.selected:=Not($assignee.selected)
		This.refreshSelectedAssignees()
	End if 


Function refreshSelectedAssignees()
	var $assignee : Object
	var $user : cs.UtilisateurEntity
	var $assigneeId; $position : Integer

	For each ($assignee; This.assignees)
		$assigneeId:=$assignee.ID
		$position:=This.selectedAssigneeIds.indexOf($assigneeId)
		If ($assignee.selected)
			If ($position<0)
				This.selectedAssigneeIds.push($assigneeId)
			End if 
		Else 
			If ($position>=0)
				This.selectedAssigneeIds.remove($position)
			End if 
		End if 
	End for each 

	This.selectedAssignees:=ds.Utilisateur.newSelection()
	For each ($assigneeId; This.selectedAssigneeIds)
		$user:=ds.Utilisateur.get($assigneeId)
		If ($user#Null)
			This.selectedAssignees.add($user)
		End if 
	End for each 
	This.assignees:=This.assignees
	OBJECT SET ENABLED(*; "btnSelect"; This.hasSelection())


Function handleEvents()
	Case of 
		: (FORM Event.code=On Load)
			OBJECT SET ENABLED(*; "btnSelect"; This.hasSelection())

		: (FORM Event.code=On Data Change) && (FORM Event.objectName="inputSearch")
			This.load()
			OBJECT SET ENABLED(*; "btnSelect"; This.hasSelection())

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="lbAssignees") && (FORM Event.row>0)
			If (FORM Event.columnName#"columnAssigneeSelected")
				This.toggleAssignee(FORM Event.row)
			End if 

		: (FORM Event.code=On Data Change) && (FORM Event.objectName="columnAssigneeSelected")
			This.refreshSelectedAssignees()
	End case 
