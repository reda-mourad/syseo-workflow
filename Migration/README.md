# Binary host schema migration

The component uses the host datastore. Its tables must therefore be added to the
binary host structure once, before the component is used.

`New-HostSchemaMigration.ps1` creates a host-specific, additive 4D structure XML.
It keeps the component-owned tables, internal relations, and indexes; removes the
simulated `Utilisateur` and `Patient` tables and the component's database settings;
and assigns new table IDs above the binary host's highest existing table ID.

4D 20 R7 does not resolve an imported relation whose destination table already
exists outside the additive XML definition. The generated XML therefore contains
the eight relations between component-owned tables but deliberately omits the six
relations to `Utilisateur` and `Patient`.

## 1. Back up and export the host structure

Make a verified backup of the host structure and data. Open the binary host with
4D Developer 20 R7 in standalone, interpreted Design mode, then export its
structure definition to XML. You can use **File > Export > Structure definition
to XML file...**, or temporarily run this host method:

```4d
var $structure : Text
EXPORT STRUCTURE($structure; xml format)
File("C:\Migration\Host.structure.xml").setText($structure)
```

## 2. Generate the host-specific import

From the component repository root:

```powershell
.\Migration\New-HostSchemaMigration.ps1 `
    -HostStructurePath 'C:\Migration\Host.structure.xml' `
    -OutputPath 'C:\Migration\SyseoWorkflow.structure.xml'
```

If Windows reports that running scripts is disabled, launch the generator in a
child PowerShell process with a process-only execution-policy override:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File .\Migration\New-HostSchemaMigration.ps1 `
    -HostStructurePath 'C:\Migration\Host.structure.xml' `
    -OutputPath 'C:\Migration\SyseoWorkflow.structure.xml'
```

`-ExecutionPolicy Bypass` applies only to that child process; it does not change
the execution policy saved for the user or computer.

The generator stops without producing an import when it finds a missing or
incompatible host contract, a duplicate component table, an index-name conflict,
or a definition UUID collision.

## 3. Import once into the binary host

Keep the host open in standalone, interpreted Design mode and run this code from
a method stored in the host (not from a remote client):

```4d
var $structure : Text
$structure:=File("C:\Migration\SyseoWorkflow.structure.xml").getText()
IMPORT STRUCTURE($structure)
```

Save the structure, restart the host, and verify these dataclasses through ORDA:

- `ds.Conversation`
- `ds.ConversationMember`
- `ds.Message`
- `ds.Task`
- `ds.TaskAssignee`
- `ds.Tag`
- `ds.TaskTag`

Create the six host-facing relations listed in `HOST_RELATIONS.md`, entering both
relation names exactly. Then verify the relations to `ds.Utilisateur` and
`ds.Patient`, install or update the component, and compile the host.

`IMPORT STRUCTURE` is additive and is not an upgrade engine. Do not run the same
import twice. Future component schema versions should ship a separate, versioned
migration that contains only the new structural changes.
