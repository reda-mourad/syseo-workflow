property userId : Integer
property showAll : Integer
property onlyMine : Integer
property onlyDelegated : Integer
property onlyToday : Integer
property showClosed : Integer
property searchText : Text
property taskCounter : Text
property tasks : cs.TaskSelection

Class constructor($userId : Integer)
	This.userId:=$userId
	This.showAll:=0
	This.onlyMine:=1
	This.onlyDelegated:=0
	This.showClosed:=0
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
	
	If (Not(Bool(This.showClosed)))
		$criteria.push("status # :completed AND status # :cancelled AND status # :closed")
		$settings.parameters.completed:="completed"
		$settings.parameters.cancelled:="cancelled"
		$settings.parameters.closed:="closed"
	End if 
	
	If (Length(This.searchText)>0)
		$searchPattern:="@"+This.searchText+"@"
		$criteria.push("(description = :searchPattern OR description = :searchPattern OR patient.Nom = :searchPattern OR creator.Nom = :searchPattern OR assignees.utilisateur.Nom = :searchPattern OR taskTags.tag.label = :searchPattern)")
		$settings.parameters.searchPattern:=$searchPattern
	End if 
	
	This.tasks:=ds.Task.query($criteria.join(" AND "); $settings).orderBy("due_at asc")
	$remainingTaskCount:=This.tasks.query("status # :1 AND status # :2 AND status # :3"; "completed"; "cancelled"; "closed").length
	If ($remainingTaskCount=1)
		This.taskCounter:="1 tâche restante"
	Else 
		This.taskCounter:=String($remainingTaskCount)+" tâches restantes"
	End if 
	
	
Function handleEvents()
	Case of 
		: (FORM Event.code=On Clicked) && ((FORM Event.objectName="chk@") || (FORM Event.objectName="radio@"))
			This.load()
			
		: (FORM Event.code=On Data Change) && (FORM Event.objectName="searchInput")
			This.load()
			
	End case 
