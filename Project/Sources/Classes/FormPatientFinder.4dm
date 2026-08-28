property searchText : Text
property patients : cs.PatientSelection
property currentPatient : cs.PatientEntity

Class constructor()
	This.searchText:=""
	This.load()


Function load()
	var $searchPattern : Text

	If (Length(This.searchText)>0)
		$searchPattern:="@"+This.searchText+"@"
		This.patients:=ds.Patient.query("Nom = :1 OR Prénom = :1"; $searchPattern).orderBy("Nom asc, Prénom asc")
	Else 
		This.patients:=ds.Patient.all().orderBy("Nom asc, Prénom asc")
	End if 


Function handleEvents()
	Case of 
		: (FORM Event.code=On Load)
			OBJECT SET ENABLED(*; "btnSelect"; False)

		: (FORM Event.code=On Data Change) && (FORM Event.objectName="inputSearch")
			This.currentPatient:=Null
			This.load()
			OBJECT SET ENABLED(*; "btnSelect"; False)

		: (FORM Event.code=On Selection Change) && (FORM Event.objectName="lbPatients")
			OBJECT SET ENABLED(*; "btnSelect"; This.currentPatient#Null)

		: (FORM Event.code=On Double Clicked) && (FORM Event.objectName="lbPatients") && (FORM Event.row>0) && (This.currentPatient#Null)
			ACCEPT
	End case 
