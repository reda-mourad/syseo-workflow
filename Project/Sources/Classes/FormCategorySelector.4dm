property newCategoryLabel : Text
property categories : Collection
property selectedCategories : cs.TagSelection
property initialCategories : cs.TagSelection
property selectedCategoryIds : Collection

Class constructor($initialCategories : cs.TagSelection)
	var $category : cs.TagEntity

	This.newCategoryLabel:=""
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
	var $selection : cs.TagSelection
	var $category : cs.TagEntity

	$selection:=ds.Tag.all().orderBy("label asc, ID asc")
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


Function addCategory($label : Text)
	var $category : cs.TagEntity
	var $result : Object

	// Ignore whitespace-only names and keep the stored label tidy.
	While ((Length($label)>0) && (Character code(Substring($label; 1; 1))<=32))
		$label:=Substring($label; 2)
	End while
	While ((Length($label)>0) && (Character code(Substring($label; Length($label); 1))<=32))
		$label:=Substring($label; 1; Length($label)-1)
	End while
	If (Length($label)=0)
		return
	End if
	If (Length($label)>255)
		ALERT("Le nom de la catégorie ne doit pas dépasser 255 caractères.")
		return
	End if
	$category:=ds.Tag.new()
	$category.label:=$label
	$category.is_active:=True
	$result:=$category.save()
	If ($result.success)
		This.selectedCategoryIds.push($category.ID)
		This.load()
		This.refreshSelectedCategories()
		This.newCategoryLabel:=""
		OBJECT SET VALUE("inputNewCategory"; "")
	Else
		ALERT("Impossible de créer la catégorie. Veuillez réessayer.")
	End if


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

		: (FORM Event.code=On Clicked) && (FORM Event.objectName="lbCategories") && (FORM Event.row>0)
			If (FORM Event.columnName#"columnCategorySelected")
				This.toggleCategory(FORM Event.row)
			End if 

		: (FORM Event.code=On Data Change) && (FORM Event.objectName="columnCategorySelected")
			This.refreshSelectedCategories()
	End case 
