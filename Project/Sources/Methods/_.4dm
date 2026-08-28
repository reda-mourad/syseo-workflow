//%attributes = {}
var $window : Integer
$window:=Open form window("TaskManager"; Movable form dialog box)
DIALOG("TaskManager"; {handler: cs.FormTaskManager.new(17)})
CLOSE WINDOW($window)