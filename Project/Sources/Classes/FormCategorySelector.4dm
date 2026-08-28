property searchText : Text
property categories : cs.TagSelection
property selectedCategories : cs.TagSelection
property initialCategories : cs.TagSelection

Class constructor($initialCategories : cs.TagSelection)
	This.searchText:=""
	This.initialCategories:=$initialCategories
	This.load()


Function load()
	var $searchPattern : Text

	If (Length(This.searchText)>0)
		$searchPattern:="@"+This.searchText+"@"
		This.categories:=ds.Tag.query("label = :1"; $searchPattern).orderBy("label asc")
	Else 
		This.categories:=ds.Tag.all().orderBy("label asc")
	End if 


Function hasSelection()->$hasSelection : Boolean
	$hasSelection:=(This.selectedCategories#Null) && (This.selectedCategories.length>0)


Function handleEvents()
	Case of 
		: (FORM Event.code=On Load)
			If (This.initialCategories#Null)
				LISTBOX SELECT ROWS(*; "lbCategories"; This.initialCategories; lk replace selection)
			End if 
			OBJECT SET ENABLED(*; "btnSelect"; This.hasSelection())

		: (FORM Event.code=On Data Change) && (FORM Event.objectName="inputSearch")
			This.selectedCategories:=Null
			This.load()
			OBJECT SET ENABLED(*; "btnSelect"; False)

		: (FORM Event.code=On Selection Change) && (FORM Event.objectName="lbCategories")
			OBJECT SET ENABLED(*; "btnSelect"; This.hasSelection())
	End case 
