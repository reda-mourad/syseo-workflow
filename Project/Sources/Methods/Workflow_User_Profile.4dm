//%attributes = {"invisible":true}
#DECLARE($privileges : Integer)->$profile : Text

Case of 
	: ($privileges=1)
		$profile:="Administrateur"
	: ($privileges=2)
		$profile:="Médecin"
	: ($privileges=6)
		$profile:="Infirmier"
	Else 
		$profile:=""
End case 
