//%attributes = {}
var $userId : Integer

$userId:=Num(Request("Identifiant utilisateur"))
Init_Task_Chat($userId)