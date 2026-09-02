#DECLARE($currentUserId : Integer; $conversationId : Integer)

var $dynamicForm : Object
var $left; $top; $right; $bottom; $subformHeight; $subformWidth : Integer

OBJECT GET COORDINATES(*; "subformMessages"; $left; $top; $right; $bottom)
$subformHeight:=$bottom-$top
$subformWidth:=$right-$left

$dynamicForm:=Build_conversation_form($currentUserId; $conversationId; 50; $subformHeight; $subformWidth)
OBJECT SET SUBFORM(*; "subformMessages"; $dynamicForm)

// Queue scrolling until 4D has installed and displayed the dynamic form.
CALL FORM(Current form window; "Messaging_Client_Form_scroll")
