//%attributes = {}
#DECLARE($currentUserId : Integer; $conversationId : Integer; $limit : Integer; $subformHeight : Integer; $subformWidth : Integer)->$form : Object

var $messages : Collection
var $message; $response; $pageObjects; $page; $measurementForm; $measurementPageObjects; $pageObject : Object
var $avatar; $avatarText; $bubble; $messageInfoText; $messageStatusText; $messageText; $messageButton; $measurementInfo; $measurementText : Object
var $objectSuffix; $objectName; $initials; $body; $messageInfo; $messageInfoAlign; $messageStatusIcon; $messageStatusColor; $messageStatusLabel; $avatarColor; $bubbleColor : Text
var $messageDate : Date
var $messageTime : Time
var $objectNames : Collection
var $messageNumber; $effectiveLimit; $effectiveHeight; $effectiveWidth; $maximumTextWidth; $bubbleHorizontalPadding; $top; $bubbleLeft; $avatarLeft; $bubbleWidth; $bubbleHeight; $contentWidth; $infoRowWidth; $infoWidth; $infoHeight; $textWidth; $textHeight; $statusWidth; $timestampSeparatorPosition; $verticalOffset : Integer
var $isCurrentUser : Boolean

$effectiveLimit:=$limit
If ($effectiveLimit<0)
	$effectiveLimit:=0
End if 

$effectiveHeight:=$subformHeight
If ($effectiveHeight<1)
	$effectiveHeight:=1
End if 
$effectiveWidth:=$subformWidth
If ($effectiveWidth<160)
	$effectiveWidth:=160
End if 
$maximumTextWidth:=$effectiveWidth-160
If ($maximumTextWidth<52)
	$maximumTextWidth:=52
End if 

$response:=Messaging_Server_Read_messages($currentUserId; $conversationId; $effectiveLimit)
If ($response.success)
	$messages:=$response.messages
Else 
	$messages:=New collection
End if 

$pageObjects:=New object
$bubbleHorizontalPadding:=14
$top:=0
$messageNumber:=0

// This temporary dynamic form is loaded off-screen to measure each message.
$measurementText:=New object(\
"type"; "text"; \
"text"; ""; \
"left"; 0; \
"top"; 0; \
"width"; $maximumTextWidth; \
"height"; 20; \
"wordwrap"; "normal")
$measurementInfo:=New object(\
"type"; "text"; \
"text"; ""; \
"left"; 0; \
"top"; 22; \
"width"; $maximumTextWidth; \
"height"; 16; \
"fontSize"; 11; \
"wordwrap"; "normal")
$measurementPageObjects:=New object("txtMeasure"; $measurementText; "txtMeasureInfo"; $measurementInfo)
$measurementForm:=New object
$measurementForm["$4d"]:=New object("version"; "1"; "kind"; "form")
$measurementForm.width:=$maximumTextWidth
$measurementForm.height:=38
$measurementForm.pages:=New collection(New object("objects"; New object); New object("objects"; $measurementPageObjects))

For each ($message; $messages)
	$messageNumber:=$messageNumber+1
	If ($messageNumber>1)
		$top:=$top+10
	End if 
	$objectSuffix:=String($messageNumber)
	$body:=$message.body
	$messageInfo:=$message.senderName
	If ($message.createdAt#Null)
		$messageDate:=Date($message.createdAt)
		$timestampSeparatorPosition:=Position("T"; $message.createdAt)
		If ($timestampSeparatorPosition>0)
			$messageTime:=Time(Substring($message.createdAt; $timestampSeparatorPosition+1; 8))
		Else 
			$messageTime:=Time($message.createdAt)
		End if 
		$messageInfo:=$messageInfo+" • "+String($messageDate; System date short)+" "+String($messageTime; HH MM)
	End if 
	If ($message.editedAt#Null)
		$messageInfo:=$messageInfo+" • modifié"
	End if 
	$initials:=$message.senderInitials
	If (Length($initials)=0)
		$initials:=Uppercase(Substring($message.senderName; 1; 2))
	End if 
	$isCurrentUser:=($message.senderId=$currentUserId)
	$statusWidth:=0
	$messageStatusIcon:=""
	$messageStatusColor:="#5F6368"
	$messageStatusLabel:=""
	If ($isCurrentUser)
		$statusWidth:=24
		If ($message.status="read")
			$messageStatusIcon:="✓✓"
			$messageStatusColor:="#1A73E8"
			$messageStatusLabel:="Lu"
		Else 
			If ($message.status="received")
				$messageStatusIcon:="✓✓"
				$messageStatusLabel:="Reçu"
			Else 
				$messageStatusIcon:="✓"
				$messageStatusLabel:="Envoyé"
			End if 
		End if 
	End if 
	
	$measurementText.text:=$body
	$measurementInfo.text:=$messageInfo
	FORM LOAD($measurementForm)
	OBJECT GET BEST SIZE(*; "txtMeasure"; $textWidth; $textHeight; $maximumTextWidth)
	OBJECT GET BEST SIZE(*; "txtMeasureInfo"; $infoWidth; $infoHeight; $maximumTextWidth)
	FORM UNLOAD
	If ($textWidth<52)
		$textWidth:=52
	End if 
	If ($textHeight<18)
		$textHeight:=18
	End if 
	If ($infoHeight<14)
		$infoHeight:=14
	End if 
	$contentWidth:=$textWidth+($bubbleHorizontalPadding*2)
	$infoRowWidth:=$infoWidth+$statusWidth+($bubbleHorizontalPadding*2)
	If ($infoRowWidth>$contentWidth)
		$contentWidth:=$infoRowWidth
	End if 
	$bubbleWidth:=$contentWidth
	$bubbleHeight:=$infoHeight+$textHeight+20
	If ($bubbleHeight<48)
		$bubbleHeight:=48
	End if 
	
	If ($isCurrentUser)
		$avatarLeft:=$effectiveWidth-36
		$bubbleLeft:=$avatarLeft-12-$bubbleWidth
		$messageInfoAlign:="right"
		$avatarColor:="#2E7D32"
		$bubbleColor:="#DCF8C6"
	Else 
		$avatarLeft:=0
		$bubbleLeft:=48
		$messageInfoAlign:="left"
		$avatarColor:="#546E7A"
		$bubbleColor:="#FFFFFF"
	End if 
	
	$avatar:=New object(\
	"type"; "oval"; \
	"left"; $avatarLeft; \
	"top"; $top; \
	"width"; 36; \
	"height"; 36; \
	"stroke"; "transparent"; \
	"fill"; $avatarColor)
	$pageObjects["avatar"+$objectSuffix]:=$avatar
	
	$avatarText:=New object(\
	"type"; "text"; \
	"text"; $initials; \
	"left"; $avatarLeft; \
	"top"; $top+9; \
	"width"; 36; \
	"height"; 18; \
	"stroke"; "#FFFFFF"; \
	"fontWeight"; "bold"; \
	"textAlign"; "center")
	$pageObjects["txtAvatar"+$objectSuffix]:=$avatarText
	
	$bubble:=New object(\
	"type"; "rectangle"; \
	"left"; $bubbleLeft; \
	"top"; $top; \
	"width"; $bubbleWidth; \
	"height"; $bubbleHeight; \
	"stroke"; "#C0C0C0"; \
	"fill"; $bubbleColor; \
	"cornerRadius"; 18)
	$pageObjects["bgMessage"+$objectSuffix]:=$bubble
	
	$messageInfoText:=New object(\
	"type"; "text"; \
	"text"; $messageInfo; \
	"left"; $bubbleLeft+$bubbleHorizontalPadding; \
	"top"; $top+7; \
	"width"; $bubbleWidth-($bubbleHorizontalPadding*2)-$statusWidth; \
	"height"; $infoHeight; \
	"stroke"; "#5F6368"; \
	"fontSize"; 11; \
	"wordwrap"; "normal"; \
	"textAlign"; $messageInfoAlign)
	$pageObjects["txtMessageInfo"+$objectSuffix]:=$messageInfoText
	
	If ($isCurrentUser)
		$messageStatusText:=New object(\
		"type"; "text"; \
		"text"; $messageStatusIcon; \
		"left"; $bubbleLeft+$bubbleWidth-$statusWidth-$bubbleHorizontalPadding; \
		"top"; $top+7; \
		"width"; $statusWidth; \
		"height"; $infoHeight; \
		"stroke"; $messageStatusColor; \
		"fontSize"; 12; \
		"fontWeight"; "bold"; \
		"helpTip"; $messageStatusLabel; \
		"textAlign"; "right")
		$pageObjects["txtMessageStatus"+$objectSuffix]:=$messageStatusText
	End if 
	
	$messageText:=New object(\
	"type"; "text"; \
	"text"; $body; \
	"left"; $bubbleLeft+$bubbleHorizontalPadding; \
	"top"; $top+$infoHeight+12; \
	"width"; $bubbleWidth-($bubbleHorizontalPadding*2); \
	"height"; $textHeight; \
	"stroke"; "#202124"; \
	"wordwrap"; "normal"; \
	"textAlign"; $messageInfoAlign)
	$pageObjects["txtMessage"+$objectSuffix]:=$messageText

	$messageButton:=New object(\
	"type"; "button"; \
	"style"; "custom"; \
	"borderStyle"; "none"; \
	"text"; ""; \
	"left"; $bubbleLeft; \
	"top"; $top; \
	"width"; $bubbleWidth; \
	"height"; $bubbleHeight; \
	"fill"; "transparent"; \
	"focusable"; False; \
	"helpTip"; "Clic droit pour convertir ce message en tâche"; \
	"events"; New collection("onClick"))
	$pageObjects["btnMessage"+String($message.ID)]:=$messageButton
	
	$top:=$top+$bubbleHeight
End for each 

If ($messages.length=0)
	$pageObjects.txtEmpty:=New object(\
	"type"; "text"; \
	"text"; "Aucun message"; \
	"left"; 0; \
	"top"; 0; \
	"width"; $effectiveWidth; \
	"height"; 24; \
	"stroke"; "#80868B"; \
	"textAlign"; "center")
	$top:=24
End if 

// Keep short conversations against the bottom edge without outer padding.
If ($top<$effectiveHeight)
	$verticalOffset:=$effectiveHeight-$top
	$objectNames:=OB Keys($pageObjects)
	For each ($objectName; $objectNames)
		$pageObject:=$pageObjects[$objectName]
		$pageObject.top:=$pageObject.top+$verticalOffset
	End for each 
	$top:=$effectiveHeight
End if 

$page:=New object("objects"; $pageObjects)
$form:=New object
$form["$4d"]:=New object("version"; "1"; "kind"; "form")
$form.width:=$effectiveWidth
$form.height:=$top
$form.rightMargin:=0
$form.bottomMargin:=0
$form.events:=New collection("onClick")
$form.method:="Conversation_message_events"
$form.pages:=New collection(New object("objects"; New object); $page)
