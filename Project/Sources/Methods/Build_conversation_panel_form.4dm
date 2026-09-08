//%attributes = {"shared":true}
#DECLARE($currentUserId : Integer; $conversationId : Integer; $panelHeight : Integer; $panelWidth : Integer)->$form : Object

var $pageObjects; $messagesForm : Object
var $effectiveHeight; $effectiveWidth; $composerHeight; $composerTop; $messagesBottom; $messagesWidth; $inputHeight : Integer

$effectiveHeight:=$panelHeight
If ($effectiveHeight<1)
	$effectiveHeight:=1
End if 
$effectiveWidth:=$panelWidth
If ($effectiveWidth<20)
	$effectiveWidth:=20
End if 

$composerHeight:=60
$composerTop:=$effectiveHeight-$composerHeight
If ($composerTop<0)
	$composerTop:=0
End if 
$messagesBottom:=$composerTop-20
If ($messagesBottom<0)
	$messagesBottom:=0
End if 
$messagesWidth:=$effectiveWidth-20
If ($messagesWidth<1)
	$messagesWidth:=1
End if 
$inputHeight:=$effectiveHeight-$composerTop-20
If ($inputHeight<1)
	$inputHeight:=1
End if 

$messagesForm:=Build_conversation_form($currentUserId; $conversationId; 50; $messagesBottom; $messagesWidth)

$pageObjects:=New object
$pageObjects.bgMessageComposer:=New object(\
"type"; "rectangle"; \
"left"; 0; \
"top"; $composerTop; \
"width"; $effectiveWidth; \
"height"; $effectiveHeight-$composerTop; \
"stroke"; "#C0C0C0"; \
"sizingX"; "grow"; \
"sizingY"; "move")

$pageObjects.inputMessage:=New object(\
"type"; "input"; \
"left"; 10; \
"top"; $composerTop+10; \
"width"; $effectiveWidth-20; \
"height"; $inputHeight; \
"dataSource"; "Form:C1466.messageBody"; \
"events"; New collection("onBeforeKeystroke"); \
"multiline"; True; \
"fill"; "transparent"; \
"borderStyle"; "none"; \
"placeholder"; "Votre message"; \
"sizingX"; "grow"; \
"sizingY"; "move")

$pageObjects.subformMessages:=New object(\
"type"; "subform"; \
"left"; 0; \
"top"; 0; \
"width"; $messagesWidth; \
"height"; $messagesBottom; \
"detailForm"; $messagesForm; \
"sizingX"; "grow"; \
"sizingY"; "grow"; \
"scrollbarVertical"; "visible")

$form:=New object
$form["$4d"]:=New object("version"; "1"; "kind"; "form")
$form.width:=$effectiveWidth
$form.height:=$effectiveHeight
$form.rightMargin:=0
$form.bottomMargin:=0
$form.events:=New collection("onLoad"; "onBoundVariableChange"; "onBeforeKeystroke"; "onResize")
$form.method:="Conversation_panel_events"
$form.pages:=New collection(\
New object("objects"; New object); \
New object("objects"; $pageObjects))
