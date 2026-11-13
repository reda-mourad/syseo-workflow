//%attributes = {}
ds.TaskTag.all().drop()
ds.TaskAssignee.all().drop()
ds.Task.all().drop()
ds.Tag.all().drop()
ds.Message.all().drop()
ds.ConversationMember.all().drop()
ds.Conversation.all().drop()
ds.Patient.all().drop()
//ds.Utilisateur.all().drop()

var $text : Text
var $messages : Collection
var $current; $next : Object
var $found_length; $found_pos; $i; $j; $start; $length : Integer
var $user : cs.UtilisateurEntity
var $conversation : cs.ConversationEntity
var $message : cs.MessageEntity

ARRAY INTEGER($emmeteurs; 0)
ALL RECORDS([Mail])
DISTINCT VALUES([Mail]xIdEmmeteur; $emmeteurs)

For ($i; 1; Size of array($emmeteurs))
	
	QUERY([Mail_Recepteur]; [Mail_Recepteur]Id_Recepteur=$emmeteurs{$i})
	RELATE ONE SELECTION([Mail_Recepteur]; [Mail])
	
	While (Not(End selection([Mail])))
		
		$start:=1
		$messages:=[]
		
		While (Match regex(".* : "; [Mail]Message; $start; $found_pos; $found_length))
			
			$text:=Substring([Mail]Message; $found_pos; $found_length)
			$text:=Replace string($text; " : "; "")
			$user:=ds.Utilisateur.query("Nom = :1"; $text).first()
			$messages.push({start: $found_pos; length: $found_length; sender: $text; user: $user})
			$start:=$found_pos+$found_length
			
		End while 
		
		For ($j; 0; $messages.length)
			$current:=$messages[$j]
			$next:=$j<($messages.length-1) ? $messages[$j+1] : Null
			
			$length:=$next#Null ? $next.start-($current.start+$current.length) : Length([Mail]Message)
			$start:=$current.start+$current.length
			$current.message:=Substring([Mail]Message; $start; $length)
			
		End for 
		
		$conversation:=ds.Conversation.new()
		$conversation.ID_creator:=[Mail]xIdEmmeteur
		$conversation.save()
		
		NEXT RECORD([Mail])
	End while 
	
End for 
