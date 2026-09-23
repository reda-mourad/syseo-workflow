//%attributes = {"shared":true}
var $descriptions; $tagLabels; $availableIndexes; $conversationDefinitions; $conversationUsers; $messageBodies : Collection
var $users : cs.UtilisateurSelection
var $otherUsers : cs.UtilisateurSelection
var $patients : cs.PatientSelection
var $tags : cs.TagSelection
var $conversation : cs.ConversationEntity
var $conversationMember : cs.ConversationMemberEntity
var $message : cs.MessageEntity
var $task : cs.TaskEntity
var $patient : cs.PatientEntity
var $tag : cs.TagEntity
var $taskTag : cs.TaskTagEntity
var $assignee : cs.TaskAssigneeEntity
var $creator; $assignedUser; $currentUser; $conversationUser; $messageSender : cs.UtilisateurEntity
var $conversationDefinition : Object
var $taskNumber; $tagNumber; $assigneeNumber; $conversationNumber; $memberNumber; $messageNumber; $randomPosition; $randomIndex; $tagCount; $maxTagCount; $assigneeCount; $maxAssigneeCount; $memberCount; $messageCount : Integer
var $completionRoll; $urgentRoll; $patientRoll; $createdDaysAgo; $daysSinceCreation; $updatedDaysAfterCreation; $createdTimeSeconds; $updatedTimeSeconds; $conversationDaysAgo; $messageDaysAgo; $messageTimeSeconds : Integer
var $description; $updatedAt; $conversationCreatedAt; $messageCreatedAt : Text
var $today; $dueDate; $createdDate; $updatedDate; $messageDate : Date
var $isUrgent : Boolean

// Delete dependent entities first so that all relations remain valid during cleanup.
ds.TaskTag.all().drop()
ds.TaskAssignee.all().drop()
ds.Task.all().drop()
ds.Tag.all().drop()
ds.Message.all().drop()
ds.ConversationMember.all().drop()
ds.Conversation.all().drop()
ds.Patient.all().drop()
ds.Utilisateur.all().drop()

$users:=ds.Utilisateur.fromCollection(JSON Parse(Folder(fk database folder).file("users.json").getText()))
ds.Patient.fromCollection(JSON Parse(Folder(fk database folder).file("patients.json").getText()))
$users:=ds.Utilisateur.all()
$patients:=ds.Patient.all()

$today:=Current date

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
"Suivi"; \
"Administratif"; \
"Clinique"; \
"Médicaments"; \
"Laboratoire"; \
"Imagerie"; \
"Orientation"; \
"Contact patient"; \
"Documentation")

$conversationDefinitions:=New collection(\
New object("kind"; "dm"; "name"; ""; "memberCount"; 2); \
New object("kind"; "dm"; "name"; ""; "memberCount"; 2); \
New object("kind"; "dm"; "name"; ""; "memberCount"; 2); \
New object("kind"; "group"; "name"; "Équipe clinique"; "memberCount"; 4); \
New object("kind"; "group"; "name"; "Coordination patients"; "memberCount"; 5))

$messageBodies:=New collection(\
"Bonjour, avez-vous vu la dernière mise à jour ?"; \
"Oui, je viens de consulter le dossier."; \
"Je m'en occupe dans la matinée."; \
"Merci, tenez-moi au courant dès que c'est fait."; \
"Le patient a confirmé son prochain rendez-vous."; \
"Parfait, je mets à jour les informations."; \
"Est-ce que quelqu'un peut vérifier les résultats ?"; \
"Je les regarde et je vous fais un retour."; \
"La demande a bien été transmise."; \
"Très bien, merci pour le suivi."; \
"Il reste un point à confirmer avec l'équipe."; \
"D'accord, on en reparle cet après-midi.")

$tags:=ds.Tag.newSelection()
For ($tagNumber; 0; $tagLabels.length-1)
	$tag:=ds.Tag.new()
	$tag.label:=$tagLabels[$tagNumber]
	$tag.is_active:=True
	$tag.save()
	$tags.add($tag)
End for 

// Create direct and group conversations containing user 17.
$currentUser:=$users.query("xNumUser = :1"; 17).first()
If ($currentUser#Null)
	$otherUsers:=$users.query("xNumUser # :1"; 17)
	$conversationNumber:=0
	For each ($conversationDefinition; $conversationDefinitions)
		$memberCount:=$conversationDefinition.memberCount
		If ($memberCount>($otherUsers.length+1))
			$memberCount:=$otherUsers.length+1
		End if 
		
		If ($memberCount>=2)
			$conversationNumber:=$conversationNumber+1
			$conversationUsers:=New collection
			$conversationUsers.push($currentUser)
			$availableIndexes:=New collection
			For ($memberNumber; 0; $otherUsers.length-1)
				$availableIndexes.push($memberNumber)
			End for 
			For ($memberNumber; 2; $memberCount)
				$randomPosition:=Random%$availableIndexes.length
				$randomIndex:=$availableIndexes[$randomPosition]
				$availableIndexes.remove($randomPosition)
				$conversationUser:=$otherUsers[$randomIndex]
				$conversationUsers.push($conversationUser)
			End for 
			
			$conversationDaysAgo:=(Random%8)+7
			$createdDate:=$today-$conversationDaysAgo
			$createdTimeSeconds:=(Random%14401)+28800
			$conversationCreatedAt:=String($createdDate; ISO date; Time($createdTimeSeconds))
			$conversation:=ds.Conversation.new()
			$conversation.kind:=$conversationDefinition.kind
			If (Length($conversationDefinition.name)>0)
				$conversation.name:=$conversationDefinition.name
			End if 
			$conversation.creator:=$currentUser
			$conversation.created_at:=$conversationCreatedAt
			$conversation.updated_at:=$conversationCreatedAt
			$conversation.save()
			
			For each ($conversationUser; $conversationUsers)
				$conversationMember:=ds.ConversationMember.new()
				$conversationMember.conversation:=$conversation
				$conversationMember.utilisateur:=$conversationUser
				$conversationMember.joined_at:=$conversationCreatedAt
				$conversationMember.notifications_enabled:=True
				$conversationMember.save()
			End for each 
			
			$messageCount:=(Random%7)+6
			For ($messageNumber; 1; $messageCount)
				$messageDaysAgo:=($messageCount-$messageNumber)\3
				$messageDate:=$today-$messageDaysAgo
				$messageTimeSeconds:=28800+(($messageNumber-1)*1800)
				$messageCreatedAt:=String($messageDate; ISO date; Time($messageTimeSeconds))
				If (($messageNumber%3)=0)
					$messageSender:=$currentUser
				Else 
					$messageSender:=$conversationUsers[Random%$conversationUsers.length]
				End if 
				$message:=ds.Message.new()
				$message.conversation:=$conversation
				$message.sender:=$messageSender
				$message.body:=$messageBodies[($conversationNumber+$messageNumber-2)%$messageBodies.length]
				$message.created_at:=$messageCreatedAt
				$message.save()
			End for 
			$conversation.updated_at:=$messageCreatedAt
			$conversation.save()
		End if 
	End for each 
End if 

For ($taskNumber; 1; 500)
	$task:=ds.Task.new()
	$description:=$descriptions[Random%$descriptions.length]
	$task.description:=$description
	
	// Create tasks during the previous 45 days, with updates occurring between creation and today.
	$createdDaysAgo:=(Random%45)+1
	$createdDate:=$today-$createdDaysAgo
	$daysSinceCreation:=$today-$createdDate
	$updatedDaysAfterCreation:=Random%($daysSinceCreation+1)
	$updatedDate:=$createdDate+$updatedDaysAfterCreation
	$createdTimeSeconds:=(Random%32401)+28800  // Between 08:00 and 17:00.
	If ($updatedDate=$createdDate)
		$updatedTimeSeconds:=$createdTimeSeconds+(Random%(61201-$createdTimeSeconds))
	Else 
		$updatedTimeSeconds:=(Random%32401)+28800
	End if 
	$task.created_at:=String($createdDate; ISO date; Time($createdTimeSeconds))
	$updatedAt:=String($updatedDate; ISO date; Time($updatedTimeSeconds))
	$task.updated_at:=$updatedAt
	
	// Roughly 30% of seeded tasks are completed; a null completion date means pending.
	$completionRoll:=Random%100
	If ($completionRoll<30)
		$task.completed_at:=$updatedAt
	End if 
	
	// Keep urgent work uncommon; all tasks are due between today and three days from now.
	$urgentRoll:=Random%100
	$isUrgent:=($urgentRoll<15)
	$task.is_urgent:=$isUrgent
	$dueDate:=$today+(Random%4)
	$task.due_at:=String($dueDate; ISO date)
	$creator:=$users[Random%$users.length]
	$task.creator:=$creator
	
	// Relate roughly 70% of seeded tasks to a random patient.
	$patientRoll:=Random%100
	If (($patientRoll<70) && ($patients.length>0))
		$patient:=$patients[Random%$patients.length]
		$task.patient:=$patient
	End if 
	$task.save()
	
	// Assign between one and five distinct tags.
	$availableIndexes:=New collection
	For ($tagNumber; 0; $tags.length-1)
		$availableIndexes.push($tagNumber)
	End for 
	$maxTagCount:=$tags.length
	If ($maxTagCount>5)
		$maxTagCount:=5
	End if 
	$tagCount:=0
	If ($maxTagCount>0)
		$tagCount:=(Random%$maxTagCount)+1
	End if 
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

ALERT("Seeding finished!")