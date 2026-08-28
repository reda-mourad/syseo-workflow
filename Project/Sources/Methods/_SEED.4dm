//%attributes = {}
var $descriptions; $tagLabels; $availableIndexes : Collection
var $users : cs.UtilisateurSelection
var $tags : cs.TagSelection
var $task : cs.TaskEntity
var $tag : cs.TagEntity
var $taskTag : cs.TaskTagEntity
var $assignee : cs.TaskAssigneeEntity
var $creator; $assignedUser : cs.UtilisateurEntity
var $taskNumber; $tagNumber; $assigneeNumber; $randomPosition; $randomIndex; $tagCount; $assigneeCount; $maxAssigneeCount : Integer
var $dateRangeDays : Integer
var $description : Text
var $today; $oneMonthFromToday; $dueDate : Date

// Delete dependent entities first so that all relations remain valid during cleanup.
ds.TaskActivity.all().drop()
ds.TaskComment.all().drop()
ds.TaskTag.all().drop()
ds.TaskAssignee.all().drop()
ds.Task.all().drop()
ds.Tag.all().drop()
ds.MessageReceipt.all().drop()
ds.MessageRevision.all().drop()
ds.Message.all().drop()
ds.ConversationMember.all().drop()
ds.Conversation.all().drop()
//ds.Patient.all().drop()
//ds.Utilisateur.all().drop()

//$users:=ds.Utilisateur.fromCollection(JSON Parse(Folder(fk desktop folder).file("users.json").getText()))
//ds.Patient.fromCollection(JSON Parse(Folder(fk desktop folder).file("patients.json").getText()))
$users:=ds.Utilisateur.all()

$today:=Current date
$oneMonthFromToday:=Add to date($today; 0; 1; 0)
$dateRangeDays:=$oneMonthFromToday-$today

$descriptions:=New collection(\
"Examiner les derniers résultats de laboratoire du patient"; \
"Planifier une consultation de suivi avec le patient"; \
"Confirmer la liste actuelle des médicaments du patient"; \
"Préparer les documents de sortie du patient"; \
"Contacter le patient pour discuter de l'évolution du traitement"; \
"Demander le compte rendu d'imagerie médicale manquant"; \
"Mettre à jour le plan de soins du patient"; \
"Vérifier les informations d'assurance du patient"; \
"Coordonner l'orientation vers le spécialiste"; \
"Examiner et signer la note de consultation clinique"; \
"Organiser le transport pour le prochain rendez-vous"; \
"Envoyer au patient les consignes avant le rendez-vous"; \
"Vérifier si le traitement prescrit a été commencé"; \
"Documenter la dernière conversation téléphonique avec le patient"; \
"Relancer la demande d'autorisation en attente"; \
"Préparer le dossier pour la réunion multidisciplinaire"; \
"Confirmer la réception des dossiers médicaux externes"; \
"Examiner les symptômes signalés par le patient"; \
"Planifier l'examen diagnostique demandé"; \
"Informer l'équipe soignante de la mise à jour de l'état du patient")

$tagLabels:=New collection(\
"Urgent"; \
"Suivi"; \
"Administratif"; \
"Clinique"; \
"Médicaments"; \
"Laboratoire"; \
"Imagerie"; \
"Orientation"; \
"Contact patient"; \
"Documentation")

$tags:=ds.Tag.newSelection()
For ($tagNumber; 0; $tagLabels.length-1)
	$tag:=ds.Tag.new()
	$tag.label:=$tagLabels[$tagNumber]
	$tag.is_active:=True
	$tag.save()
	$tags.add($tag)
End for 

For ($taskNumber; 1; 500)
	$task:=ds.Task.new()
	$description:=$descriptions[Random%$descriptions.length]
	$task.description:=$description
	$task.status:="open"
	$dueDate:=$today+(Random%($dateRangeDays+1))
	$task.due_at:=String($dueDate; ISO date)
	$creator:=$users[Random%$users.length]
	$task.creator:=$creator
	$task.save()
	
	// Assign between one and five distinct random tags.
	$availableIndexes:=New collection(0; 1; 2; 3; 4; 5; 6; 7; 8; 9)
	$tagCount:=(Random%5)+1
	For ($tagNumber; 1; $tagCount)
		$randomPosition:=Random%$availableIndexes.length
		$randomIndex:=$availableIndexes[$randomPosition]
		$availableIndexes.remove($randomPosition)
		$taskTag:=ds.TaskTag.new()
		$taskTag.task:=$task
		$taskTag.tag:=$tags[$randomIndex]
		$taskTag.save()
	End for 
	
	// Assign between one and five distinct random users.
	$availableIndexes:=New collection
	For ($assigneeNumber; 0; $users.length-1)
		$availableIndexes.push($assigneeNumber)
	End for 
	$maxAssigneeCount:=$users.length
	If ($maxAssigneeCount>5)
		$maxAssigneeCount:=5
	End if 
	$assigneeCount:=(Random%$maxAssigneeCount)+1
	For ($assigneeNumber; 1; $assigneeCount)
		$randomPosition:=Random%$availableIndexes.length
		$randomIndex:=$availableIndexes[$randomPosition]
		$availableIndexes.remove($randomPosition)
		$assignedUser:=$users[$randomIndex]
		$assignee:=ds.TaskAssignee.new()
		$assignee.task:=$task
		$assignee.utilisateur:=$assignedUser
		$assignee.save()
	End for 
End for 
