//%attributes = {"invisible":true,"executedOnServer":true,"shared":true}
#DECLARE($userId : Integer)->$result : Object

var $users : cs.UtilisateurSelection
var $user : cs.UtilisateurEntity
var $recipients : Collection
var $profile : Text

$recipients:=New collection
$result:=New object("success"; False; "recipients"; $recipients; "error"; "")
If (ds.Utilisateur.get($userId)=Null)
	$result.error:="The current user does not exist."
Else 
	$users:=ds.Utilisateur.query("xNumUser # :1"; $userId).orderBy("Nom asc")
	For each ($user; $users)
		$profile:=Workflow_User_Profile($user.Privilèges)
		$recipients.push(New object(\
		"ID"; $user.xNumUser; \
		"name"; $user.Nom; \
		"profile"; $profile; \
		"selected"; False))
	End for each 
	$result.success:=True
End if 
