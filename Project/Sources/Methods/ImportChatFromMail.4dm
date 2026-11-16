//%attributes = {"shared":true}
#DECLARE()->$result : Object

var $mails : cs.MailSelection
var $mail : cs.MailEntity
var $senderHistory : cs.MailEntity
var $recipients : cs.Mail_RecepteurSelection
var $recipient : cs.Mail_RecepteurEntity
var $user : cs.UtilisateurEntity
var $conversation : cs.ConversationEntity
var $member : cs.ConversationMemberEntity
var $message : cs.MessageEntity
var $identities; $candidateIds; $memberIds; $headers : Collection
var $aliases; $identity; $header; $saveStatus : Object
var $text; $name; $key; $body; $timestamp; $error : Text
var $start; $foundPosition; $foundLength; $i; $end; $senderId; $userId; $candidateId : Integer
var $conversationCount; $memberCount; $messageCount : Integer
var $messageDate : Date
var $messageTime : Time

CONFIRM("Poursuivre avec une importation propre ? (Supprimer les données du nouveau système de discussion)"; "Oui"; "Non")

If (OK=1)
	
	ds.Message.all().drop()
	ds.ConversationMember.all().drop()
	ds.Conversation.all().drop()
	
End if 

$result:={success: False; conversations: 0; members: 0; messages: 0; mailId: 0; error: ""}
$error:=""
$mails:=ds.Mail.all().orderBy("TimeStamp asc, xNumID asc")

If ($error="")
	// Keep historical aliases as well as current names. One name can have several IDs.
	$identities:=[]
	For each ($user; ds.Utilisateur.all())
		$identities.push({name: $user.Nom; id: $user.xNumUser})
	End for each 
	For each ($mail; $mails)
		$identities.push({name: $mail.Emetteur; id: $mail.xIdEmmeteur})
	End for each 
	For each ($recipient; ds.Mail_Recepteur.all())
		$identities.push({name: $recipient.Recepteur; id: $recipient.Id_Recepteur})
	End for each 
	$aliases:={}
	For each ($identity; $identities)
		If (($identity.name#"") && ($identity.id>0))
			$key:=Lowercase($identity.name)
			If ($aliases[$key]=Null)
				$aliases[$key]:=[]
			End if 
			$candidateIds:=$aliases[$key]
			If ($candidateIds.indexOf($identity.id)<0)
				$candidateIds.push($identity.id)
			End if 
		End if 
	End for each 
	
	// A failed save or unresolved user rolls back the entire import.
	ds.startTransaction()
	// Keep the requested replacement of messaging data inside the transaction.
	ds.Message.all().drop()
	ds.ConversationMember.all().drop()
	ds.Conversation.all().drop()
	If ((ds.Conversation.getCount()>0) || (ds.ConversationMember.getCount()>0) || (ds.Message.getCount()>0))
		$error:="Existing messaging data could not be cleared."
	End if 
	For each ($mail; $mails) While ($error="")
		$result.mailId:=$mail.xNumID
		$memberIds:=New collection($mail.xIdEmmeteur)
		$recipients:=ds.Mail_Recepteur.query("xNum_Mail = :1"; $mail.xNumID)
		For each ($recipient; $recipients)
			If ($memberIds.indexOf($recipient.Id_Recepteur)<0)
				$memberIds.push($recipient.Id_Recepteur)
			End if 
		End for each 
		
		$text:=Replace string($mail.Message; Char(13)+Char(10); Char(10))
		$text:=Replace string($text; Char(13); Char(10))
		$headers:=[]
		$start:=1
		While (($error="") && (Match regex("(?m)^[^\\r\\n:]+ : "; $text; $start; $foundPosition; $foundLength)))
			$name:=Substring($text; $foundPosition; $foundLength-3)
			$key:=Lowercase($name)
			$candidateIds:=$aliases[$key]
			If ($candidateIds#Null)
				$senderId:=0
				If (($foundPosition=1) && ($key=Lowercase($mail.Emetteur)))
					// The first block is the latest reply, authored by the mail emitter.
					$senderId:=$mail.xIdEmmeteur
				Else 
					For each ($candidateId; $candidateIds)
						If ($memberIds.indexOf($candidateId)>=0)
							If ($senderId=0)
								$senderId:=$candidateId
							Else 
								$error:="Ambiguous sender: "+$name
							End if 
						End if 
					End for each 
					If (($senderId=0) && ($candidateIds.length=1))
						$senderId:=$candidateIds[0]
					End if 
					If (($senderId=0) && ($candidateIds.length>1))
						// A display name can be reused by a later user (Julie: 30 then 42).
						// Use the last dated sender identity known at this thread's date.
						$senderHistory:=ds.Mail.query("Emetteur = :1 AND xIdEmmeteur in :2 AND TimeStamp <= :3"; $name; $candidateIds; $mail.TimeStamp).orderBy("TimeStamp desc, xNumID desc").first()
						If ($senderHistory#Null)
							$senderId:=$senderHistory.xIdEmmeteur
						End if 
					End if 
				End if 
				If ($senderId=0)
					$error:="Cannot resolve sender: "+$name
				Else 
					$headers.push({start: $foundPosition; length: $foundLength; senderId: $senderId})
				End if 
			End if 
			// Unrecognized labels such as "indication : " remain in the message body.
			$start:=$foundPosition+$foundLength
		End while 
		
		If ($headers.length=0)
			$headers.push({start: 1; length: 0; senderId: $mail.xIdEmmeteur})
		Else 
			If ($headers[0].start>1)
				$headers.unshift({start: 1; length: 0; senderId: $mail.xIdEmmeteur})
			End if 
		End if 
		For each ($header; $headers)
			If ($memberIds.indexOf($header.senderId)<0)
				$memberIds.push($header.senderId)
			End if 
		End for each 
		For each ($userId; $memberIds) While ($error="")
			If (ds.Utilisateur.get($userId)=Null)
				$error:="Utilisateur not found: "+String($userId)
			End if 
		End for each 
		
		// CSV timestamps are seconds since 1990-01-01, verified against DateMessage.
		// Replies have no individual dates; preserve the thread date and order by ID.
		$messageDate:=$mail.DateMessage
		$messageTime:=?00:00:00?
		If ($mail.TimeStamp>0)
			If ($messageDate=!00-00-00!)
				$messageDate:=!1990-01-01!+Int($mail.TimeStamp/86400)
			End if 
			$messageTime:=Time($mail.TimeStamp%86400)
		End if 
		If ($messageDate=!00-00-00!)
			$error:="The mail has no migration date."
		End if 
		$timestamp:=String($messageDate; ISO date; $messageTime)
		
		If ($error="")
			$conversation:=ds.Conversation.new()
			$conversation.ID_creator:=$mail.xIdEmmeteur
			$conversation.kind:="group"
			If ($memberIds.length=2)
				$conversation.kind:="dm"
			End if 
			$conversation.name:=Substring($mail.Objet; 1; 255)
			$conversation.created_at:=$timestamp
			$conversation.updated_at:=$timestamp
			$saveStatus:=$conversation.save()
			If (Not($saveStatus.success))
				$error:="Conversation: "+$saveStatus.statusText
			Else 
				$conversationCount:=$conversationCount+1
			End if 
		End if 
		
		For each ($userId; $memberIds) While ($error="")
			$member:=ds.ConversationMember.new()
			$member.ID_Conversation:=$conversation.ID
			$member.ID_Utilisateur:=$userId
			$member.joined_at:=$timestamp
			$member.notifications_enabled:=True
			// Leave per-message delivery/read timestamps unknown.
			$saveStatus:=$member.save()
			If (Not($saveStatus.success))
				$error:="ConversationMember: "+$saveStatus.statusText
			Else 
				$memberCount:=$memberCount+1
			End if 
		End for each 
		
		// Save oldest replies first so auto-generated IDs follow conversation order.
		For ($i; $headers.length-1; 0; -1)
			If ($error="")
				$header:=$headers[$i]
				$start:=$header.start+$header.length
				$end:=Length($text)+1
				If ($i<($headers.length-1))
					$end:=$headers[$i+1].start
				End if 
				$body:=""
				If ($end>$start)
					$body:=Substring($text; $start; $end-$start)
				End if 
				$message:=ds.Message.new()
				$message.ID_Conversation:=$conversation.ID
				$message.ID_sender:=$header.senderId
				$message.body:=$body
				$message.created_at:=$timestamp
				$saveStatus:=$message.save()
				If (Not($saveStatus.success))
					$error:="Message: "+$saveStatus.statusText
				Else 
					$messageCount:=$messageCount+1
				End if 
			End if 
		End for 
	End for each 
	
	If ($error="")
		ds.validateTransaction()
		$result.success:=True
		$result.conversations:=$conversationCount
		$result.members:=$memberCount
		$result.messages:=$messageCount
		$result.mailId:=0
	Else 
		ds.cancelTransaction()
	End if 
End if 

$result.error:=$error
If ($error#"")
	LOG EVENT(Into system standard outputs; "Migration failed at Mail "+String($result.mailId)+": "+$error; Error message)
Else 
	LOG EVENT(Into system standard outputs; "Migration completed: "+String($result.conversations)+" conversations, "+String($result.members)+" members, "+String($result.messages)+" messages."; Information message)
	ALERT("Migration finie!")
End if 
