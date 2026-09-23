//%attributes = {"invisible":true,"shared":true}
#DECLARE($userId : Integer)

var $window : Integer

$window:=Open form window("WorkflowWorkspace"; Movable form dialog box)
DIALOG("WorkflowWorkspace"; {handler: cs.FormWorkflowWorkspace.new($userId)})
CLOSE WINDOW($window)
Launcher_Client_Refresh
