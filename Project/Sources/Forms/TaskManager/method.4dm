UI_Button_hover(New object("btnAddTask"; "bgAddTaskButton"; "btnSave"; "bgSave"; "btnDelete"; "bgDelete"; "btnBack"; "bgBack"; "btnComplete"; "bgComplete"; "btnUrgent"; "bgUrgent"; "btnSelectAssignees"; "bgAssignees"; "btnSelectCategories"; "bgCategories"; "btnFindPatient"; "bgPatient"; "btnRemovePatient"; "bgRemovePatient"))

var $handler : cs.FormTaskManager

$handler:=Form.handler
$handler.handleEvents()
