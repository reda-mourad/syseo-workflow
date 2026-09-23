//%attributes = {"invisible":true,"shared":true}
#DECLARE($patient : cs.PatientEntity)->$gender : Text

$gender:=""
If ($patient#Null)
	$gender:=$patient.Genre
	If (Length($gender)=0)
		$gender:=$patient.Sexe
	End if
End if
If (Length($gender)=0)
	$gender:="Non renseigné"
End if
