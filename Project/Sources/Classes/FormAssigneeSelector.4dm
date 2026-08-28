property searchText : Text
property assignees : cs.UtilisateurSelection
property selectedAssignees : cs.UtilisateurSelection
property initialAssignees : cs.UtilisateurSelection

Class constructor($initialAssignees : cs.UtilisateurSelection)
	This.searchText:=""
	This.initialAssignees:=$initialAssignees
	This.load()


Function load()
	var $searchPattern : Text

	If (Length(This.searchText)>0)
		$searchPattern:="@"+This.searchText+"@"
		This.assignees:=ds.Utilisateur.query("Nom = :1 OR Initiales = :1"; $searchPattern).orderBy("Nom asc")
	Else 
		This.assignees:=ds.Utilisateur.all().orderBy("Nom asc")
	End if 


Function hasSelection()->$hasSelection : Boolean
	$hasSelection:=(This.selectedAssignees#Null) && (This.selectedAssignees.length>0)


Function handleEvents()
	Case of 
		: (FORM Event.code=On Load)
			If (This.initialAssignees#Null)
				LISTBOX SELECT ROWS(*; "lbAssignees"; This.initialAssignees; lk replace selection)
			End if 
			OBJECT SET ENABLED(*; "btnSelect"; This.hasSelection())

		: (FORM Event.code=On Data Change) && (FORM Event.objectName="inputSearch")
			This.selectedAssignees:=Null
			This.load()
			OBJECT SET ENABLED(*; "btnSelect"; False)

		: (FORM Event.code=On Selection Change) && (FORM Event.objectName="lbAssignees")
			OBJECT SET ENABLED(*; "btnSelect"; This.hasSelection())
	End case 
