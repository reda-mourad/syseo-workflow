[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$HostStructurePath,

    [string]$ComponentCatalogPath,

    [string]$OutputPath = (Join-Path (Get-Location) 'SyseoWorkflow.structure.xml')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ComponentCatalogPath)) {
    $ComponentCatalogPath = Join-Path $PSScriptRoot '..\Project\Sources\catalog.4DCatalog'
}

$ownedTableNames = @(
    'Conversation',
    'ConversationMember',
    'Message',
    'Task',
    'TaskAssignee',
    'Tag',
    'TaskTag'
)

$userPrivilegeFieldName = 'Privil' + [string][char]0x00E8 + 'ges'
$patientFirstNameFieldName = 'Pr' + [string][char]0x00E9 + 'nom'
$userFields = @{
    'xNumUser' = '4'
    'Nom' = '10'
    'Initiales' = '10'
}
$userFields[$userPrivilegeFieldName] = '4'
$patientFields = @{
    'NoDossier' = '4'
    'Nom' = '10'
    'Date Naissance' = '8'
}
$patientFields[$patientFirstNameFieldName] = '10'

$externalContracts = @(
    @{
        Table = 'Utilisateur'
        Fields = $userFields
        PrimaryKey = 'xNumUser'
    },
    @{
        Table = 'Patient'
        Fields = $patientFields
        PrimaryKey = 'NoDossier'
    }
)

function Read-StructureXml {
    param([Parameter(Mandatory = $true)][string]$Path)

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $document = New-Object System.Xml.XmlDocument
    $document.PreserveWhitespace = $false
    $document.XmlResolver = $null
    $document.Load($resolvedPath)

    if ($null -eq $document.DocumentElement -or $document.DocumentElement.LocalName -ne 'base') {
        throw "'$resolvedPath' is not a 4D structure definition (expected a <base> root element)."
    }

    return $document
}

function Get-TableNode {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlDocument]$Document,
        [Parameter(Mandatory = $true)][string]$Name
    )

    return $Document.SelectSingleNode("/base/table[@name='$Name']")
}

function Get-FieldNode {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlElement]$Table,
        [Parameter(Mandatory = $true)][string]$Name
    )

    foreach ($field in $Table.SelectNodes('field')) {
        if ($field.GetAttribute('name') -ceq $Name) {
            return $field
        }
    }

    return $null
}

$hostDocument = Read-StructureXml -Path $HostStructurePath
$migrationDocument = Read-StructureXml -Path $ComponentCatalogPath

foreach ($contract in $externalContracts) {
    $hostTable = Get-TableNode -Document $hostDocument -Name $contract.Table
    if ($null -eq $hostTable) {
        throw "The host structure does not contain the required table '$($contract.Table)'."
    }

    foreach ($fieldName in $contract.Fields.Keys) {
        $hostField = Get-FieldNode -Table $hostTable -Name $fieldName
        if ($null -eq $hostField) {
            throw "The host table '$($contract.Table)' does not contain the required field '$fieldName'."
        }

        $expectedType = $contract.Fields[$fieldName]
        if ($hostField.GetAttribute('type') -ne $expectedType) {
            throw "The host field '$($contract.Table).$fieldName' has type '$($hostField.GetAttribute('type'))'; expected 4D type '$expectedType'."
        }
    }

    $primaryKey = $hostTable.SelectSingleNode('primary_key')
    if ($null -eq $primaryKey -or $primaryKey.GetAttribute('field_name') -cne $contract.PrimaryKey) {
        throw "The host field '$($contract.Table).$($contract.PrimaryKey)' must be the table primary key."
    }
}

foreach ($tableName in $ownedTableNames) {
    if ($null -ne (Get-TableNode -Document $hostDocument -Name $tableName)) {
        throw "The host already contains '$tableName'. IMPORT STRUCTURE is additive and would abort on this duplicate table name."
    }
}

foreach ($table in @($migrationDocument.SelectNodes('/base/table'))) {
    if ($ownedTableNames -cnotcontains $table.GetAttribute('name')) {
        [void]$table.ParentNode.RemoveChild($table)
    }
}

$maximumHostTableId = 0
foreach ($hostTable in $hostDocument.SelectNodes('/base/table')) {
    $hostTableId = 0
    if ([int]::TryParse($hostTable.GetAttribute('id'), [ref]$hostTableId) -and $hostTableId -gt $maximumHostTableId) {
        $maximumHostTableId = $hostTableId
    }
}

$nextTableId = $maximumHostTableId + 1
foreach ($tableName in $ownedTableNames) {
    $migrationTable = Get-TableNode -Document $migrationDocument -Name $tableName
    if ($null -eq $migrationTable) {
        throw "The component catalog does not contain the expected table '$tableName'."
    }

    $migrationTable.SetAttribute('id', [string]$nextTableId)
    $nextTableId++
}

foreach ($relation in @($migrationDocument.SelectNodes('/base/relation'))) {
    $sourceTableName = $relation.SelectSingleNode("related_field[@kind='source']/field_ref/table_ref").GetAttribute('name')
    if ($ownedTableNames -cnotcontains $sourceTableName) {
        [void]$relation.ParentNode.RemoveChild($relation)
        continue
    }

    $destinationTableName = $relation.SelectSingleNode("related_field[@kind='destination']/field_ref/table_ref").GetAttribute('name')
    if (@($externalContracts | ForEach-Object { $_.Table }) -ccontains $destinationTableName) {
        # IMPORT STRUCTURE 20 R7 cannot resolve a relation destination that is
        # already present in the host but omitted from the additive definition.
        # These host-facing relations are created manually after the import.
        [void]$relation.ParentNode.RemoveChild($relation)
    }
}

foreach ($index in @($migrationDocument.SelectNodes('/base/index'))) {
    $firstTableReference = $index.SelectSingleNode('field_ref/table_ref')
    if ($null -eq $firstTableReference -or $ownedTableNames -cnotcontains $firstTableReference.GetAttribute('name')) {
        [void]$index.ParentNode.RemoveChild($index)
    }
}

foreach ($baseExtra in @($migrationDocument.SelectNodes('/base/base_extra'))) {
    [void]$baseExtra.ParentNode.RemoveChild($baseExtra)
}

$migrationDocument.DocumentElement.SetAttribute('name', 'SyseoWorkflowSchemaMigration')
$migrationDocument.DocumentElement.SetAttribute('uuid', ([guid]::NewGuid().ToString('N').ToUpperInvariant()))

$hostIndexNames = @{}
foreach ($hostIndex in $hostDocument.SelectNodes('/base/index[@name]')) {
    $hostIndexNames[$hostIndex.GetAttribute('name')] = $true
}
foreach ($migrationIndex in $migrationDocument.SelectNodes('/base/index[@name]')) {
    $indexName = $migrationIndex.GetAttribute('name')
    if ($hostIndexNames.ContainsKey($indexName)) {
        throw "The host already contains an index named '$indexName'. Rename that host index or adjust the migration before importing."
    }
}

$hostDefinitionUuids = @{}
foreach ($node in $hostDocument.SelectNodes('//*[@uuid]')) {
    if ($node.LocalName -notin @('field_ref', 'table_ref')) {
        $hostDefinitionUuids[$node.GetAttribute('uuid')] = $true
    }
}
foreach ($node in $migrationDocument.SelectNodes('//*[@uuid]')) {
    if ($node.LocalName -notin @('field_ref', 'table_ref')) {
        $uuid = $node.GetAttribute('uuid')
        if ($hostDefinitionUuids.ContainsKey($uuid)) {
            throw "UUID collision detected for imported <$($node.LocalName)> '$uuid'. The migration was not written."
        }
    }
}

$absoluteOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $absoluteOutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    [void](New-Item -ItemType Directory -Path $outputDirectory)
}

$settings = New-Object System.Xml.XmlWriterSettings
$settings.Encoding = New-Object System.Text.UTF8Encoding($false)
$settings.Indent = $true
$settings.IndentChars = "`t"
$settings.NewLineChars = "`r`n"
$settings.NewLineHandling = [System.Xml.NewLineHandling]::Replace

$writer = [System.Xml.XmlWriter]::Create($absoluteOutputPath, $settings)
try {
    $migrationDocument.Save($writer)
}
finally {
    $writer.Dispose()
}

$tableCount = $migrationDocument.SelectNodes('/base/table').Count
$relationCount = $migrationDocument.SelectNodes('/base/relation').Count
$indexCount = $migrationDocument.SelectNodes('/base/index').Count

Write-Host "Created: $absoluteOutputPath"
Write-Host "Contains: $tableCount tables, $relationCount relations, $indexCount indexes"
Write-Host 'Import this file once from a host-side method in standalone, interpreted Design mode.'
Write-Host 'Then create the six host-facing relations listed in Migration/HOST_RELATIONS.md.'
