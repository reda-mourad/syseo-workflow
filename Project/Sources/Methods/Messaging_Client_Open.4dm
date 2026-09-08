//%attributes = {"invisible":true,"shared":true}
#DECLARE()

var $window : Integer
var $handler : cs.FormWorkflowWorkspace

$handler:=cs.FormWorkflowWorkspace.new(Messaging_Client_User_id)
$handler.initialFeature:="messages"
$window:=Open form window("WorkflowWorkspace"; Movable form dialog box)
DIALOG("WorkflowWorkspace"; {handler: $handler})
CLOSE WINDOW($window)
