var $options : Object
var $result : Object
var $error : Object
var $errorCount : Integer
var $warningCount : Integer
var $startedAt : Integer
var $durationMs : Integer
var $escape : Text
var $reset : Text
var $bold : Text
var $dim : Text
var $red : Text
var $yellow : Text
var $green : Text
var $cyan : Text
var $location : Text

$options:={}
$options.targets:=New collection
$errorCount:=0
$warningCount:=0

// ANSI styling keeps diagnostics easy to scan in local terminals and CI logs.
$escape:=Char(27)
$reset:=$escape+"[0m"
$bold:=$escape+"[1m"
$dim:=$escape+"[2m"
$red:=$escape+"[31m"
$yellow:=$escape+"[33m"
$green:=$escape+"[32m"
$cyan:=$escape+"[36m"

LOG EVENT(Into system standard outputs; $bold+$cyan+"4D SYNTAX CHECK"+$reset+"\n"+$dim+"-------------------------------"+$reset+"\n"; Information message)

$startedAt:=Milliseconds
$result:=Compile project($options)
$durationMs:=Milliseconds-$startedAt

If ($result.errors#Null)
    For each ($error; $result.errors)
        $location:=$error.code.file.fullName+":"+String($error.lineInFile)
        
        If ($error.isError)
            $errorCount:=$errorCount+1
            LOG EVENT(Into system standard outputs; $bold+$red+"[ERROR] "+$reset+$location+"\n        "+$error.message+"\n"; Error message)
        Else 
            $warningCount:=$warningCount+1
            LOG EVENT(Into system standard outputs; $bold+$yellow+"[WARN]  "+$reset+$location+"\n        "+$error.message+"\n"; Warning message)
        End if 
    End for each 
End if 

If ($result.success)
    LOG EVENT(Into system standard outputs; $dim+"-------------------------------"+$reset+"\n"+$bold+$green+"[PASS] "+$reset+"Syntax check completed | "+String($warningCount)+" warning(s) | Duration: "+String($durationMs)+" ms\n"; Information message)
Else 
    LOG EVENT(Into system standard outputs; $dim+"-------------------------------"+$reset+"\n"+$bold+$red+"[FAIL] "+$reset+"Syntax check failed | "+String($errorCount)+" error(s), "+String($warningCount)+" warning(s) | Duration: "+String($durationMs)+" ms\n"; Error message)
End if 