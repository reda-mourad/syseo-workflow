property searchText : Text
property categories : Collection
property selectedCategories : cs.TagSelection
property initialCategories : cs.TagSelection
property selectedCategoryIds : Collection

Class constructor($initialCategories : cs.TagSelection)
	var $category : cs.TagEntity

	This.searchText:=""
	This.initialCategories:=$initialCategories
	This.selectedCategoryIds:=New collection
	This.selectedCategories:=ds.Tag.newSelection()
	If (This.initialCategories#Null)
		For each ($category; This.initialCategories)
			This.selectedCategoryIds.push($category.ID)
			This.selectedCategories.add($category)
		End for each 
	End if 
	This.load()


Function load()
	var $searchPattern : Text
	var $selection : cs.TagSelection
	var $category : cs.TagEntity

	If (Length(This.searchText)>0)
		$searchPattern:="@"+This.searchText+"@"
		$selection:=ds.Tag.query("label = :1"; $searchPattern).orderBy("label asc")
	Else 
		$selection:=ds.Tag.all().orderBy("label asc")
	End if 
	This.categories:=New collection
	For each ($category; $selection)
		This.categories.push(New object(\
		"ID"; $category.ID; \
		"label"; $category.label; \
		"color"; $category.color; \
		"selected"; This.selectedCategoryIds.indexOf($category.ID)>=0))
	End for each 


Function hasSelection()->$hasSelection : Boolean
	$hasSelection:=(This.selectedCategoryIds.length>0)


Function categoryMeta($category : Object)->$meta : Object
	var $stroke : Text

	$stroke:="automatic"
	If (($category#Null) && ($category.color#Null) && (Length($category.color)>0))
		$stroke:=$category.color
	End if 
	$meta:=New object("cell"; New object("columnCategoryName"; New object("stroke"; $stroke)))


Function toggleCategory($row : Integer)
	var $category : Object

	If (($row>0) && ($row<=This.categories.length))
		$category:=This.categories[$row-1]
		$category.selected:=Not($category.selected)
		This.refreshSelectedCategories()
	End if 


Function refreshSelectedCategories()
	var $category : Object
	var $tag : cs.TagEntity
	var $categoryId; $position : Integer

	For each ($category; This.categories)
		$categoryId:=$category.ID
		$position:=This.selectedCategoryIds.indexOf($categoryId)
		If ($category.selected)
			If ($position<0)
				This.selectedCategoryIds.push($categoryId)
			End if 
		Else 
			If ($position>=0)
				This.selectedCategoryIds.remove($position)
			End if 
		End if 
	End for each 

	This.selectedCategories:=ds.Tag.newSelection()
	For each ($categoryId; This.selectedCategoryIds)
		$tag:=ds.Tag.get($categoryId)
		If ($tag#Null)
			This.selectedCategories.add($tag)
		End if 
	End for each 
	This.categories:=This.categories
	OBJECT SET ENABLED(*; "btnSelect"; This.hasSelection())


Function handleEvents()
	Case of 
		: (FORM Event.code=On Load)
			OBJECT SET ENABLED(*; "btnSelect"; This.hasSelection())

		: (FORM Event.code=On Data Change) && (FORM Event.objectName="inputSearch")
			This.load()
			OBJECT SET ENABLED(*; "btnSelect"; This.hasSelection())

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="lbCategories") && (FORM Event.row>0)
			If (FORM Event.columnName#"columnCategorySelected")
				This.toggleCategory(FORM Event.row)
			End if 

		: (FORM Event.code=On Data Change) && (FORM Event.objectName="columnCategorySelected")
			This.refreshSelectedCategories()
	End case 
