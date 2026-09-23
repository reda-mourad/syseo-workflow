# Syseo Workflow

Messaging and task management for Syseo Endo, with a local development project that supplies a simulated host schema.

The launcher opens a shared workspace with **Tâches** and **Messagerie** tabs. Its badge combines unread conversations and unfinished tasks assigned to the current user. Each tab has its own badge; zero-count badges are hidden.

## Requirements

- **4D Developer 20 R7** for editing and running a remote client.
- **4D Server 20 R7** for interactive testing, including notifications. Server and clients can run on the same computer. Use matching versions and licenses allowing the required concurrent clients.
- **Tool4D 20 R7** (`tool4d.exe`) on `PATH` for the compilation check.
- Windows and PowerShell for the supplied `.bat` check and host migration script.

The version target is **20 R7**, as recorded by `compatibilityVersion: 2070` in `Project/syseo-workflow.4DProject`. Do not substitute 20 LTS or upgrade the project metadata as part of setup.

The normal interactive startup requires **4D Remote Mode**: `Messaging_Client_Register` rejects standalone mode. Opening the project directly in 4D Developer is useful for preparing data and editing, but does not start the registered messaging session.

## 1. Open the development project

1. Clone or copy this repository to a writable local directory.
2. Open `Project/syseo-workflow.4DProject` with 4D Developer 20 R7.
3. Create a disposable development data file when prompted, preferably under the repository's ignored `Data` directory. Data and seed input files are not supplied by Git.
4. Cancel the user-ID startup prompt while preparing the database. The startup database method invokes the `_` project method, which requests an ID and tries to register a remote client.

Keep the whole project directory, including `Resources`, together. No npm or Python dependency installation is needed to run the application.

## 2. Prepare and seed sample data

**Run `_SEED` only against disposable development data. It deletes all existing entities in TaskTag, TaskAssignee, Task, Tag, Message, ConversationMember, Conversation, Patient, and Utilisateur before reading the input files. Never run it in Syseo Endo or against production data.**

The seed method reads these two UTF-8 JSON files from the Desktop of the account executing it:

- `users.json`
- `patients.json`

It uses `Folder(fk desktop folder)`, so use the actual Desktop location, including any redirected/OneDrive Desktop. The files contain top-level JSON arrays. Prepare and validate both files **before** executing `_SEED`; missing or malformed files are encountered after deletion.

For a small synthetic fixture, save the following as `users.json`:

```json
[
  {"xNumUser": 17, "Nom": "Docteur Test A", "Initiales": "DA", "Privilèges": 2},
  {"xNumUser": 18, "Nom": "Infirmier Test B", "Initiales": "IB", "Privilèges": 6},
  {"xNumUser": 19, "Nom": "Docteur Test C", "Initiales": "DC", "Privilèges": 2},
  {"xNumUser": 20, "Nom": "Infirmier Test D", "Initiales": "ID", "Privilèges": 6},
  {"xNumUser": 21, "Nom": "Administrateur Test", "Initiales": "AT", "Privilèges": 1}
]
```

Save this as `patients.json`:

```json
[
  {"NoDossier": 1001, "Nom": "Patient fictif", "Prénom": "Alice", "Date Naissance": "1980-01-15"},
  {"NoDossier": 1002, "Nom": "Patient fictif", "Prénom": "Benoit", "Date Naissance": "1990-06-20"}
]
```

Use unique integer keys. The users array must not be empty. Include user **17** and at least one other user to generate conversations; five users allow all group sizes. Patient data can be an empty array if patient-linked tasks are not needed. These examples are synthetic; do not commit patient or credential exports.

In the 4D Explorer's project methods, select and execute `_SEED` in the local development database. It imports the fixtures, creates nine tags, generates **500 random tasks**, and creates up to five conversations involving user 17, each with 6–12 messages. Approximately 30% of tasks are completed and 15% are urgent; exact counts and assignments vary on each run.

After seeding, inspect `Utilisateur`, `Patient`, `Task`, and `Conversation` in the data editor. Confirm the sample user IDs exist. Close standalone 4D before opening the same database with 4D Server; do not open the same data file in two database engines.

## 3. Run locally with a user ID

1. Open `Project/syseo-workflow.4DProject` in **4D Server 20 R7**, selecting the seeded development data file.
2. Start **4D Developer 20 R7** as a client and choose **File > Open > Remote Project** (or **Connect to 4D Server**).
3. Select the published project. If discovery does not list it, use the connection dialog's **Custom** tab with `127.0.0.1` when the server is on the same machine. Add the configured server port when necessary.
4. At **Identifiant utilisateur**, enter **17**. The launcher opens after successful registration.
5. Click **Tâches et messagerie** to enter the workspace. Tasks is the initial tab.

See the official [4D client/server connection documentation](https://developer.4d.com/docs/21/Desktop/clientServer) for the Available and Custom connection options. The repository remains targeted at 20 R7.

The entered number is `Utilisateur.xNumUser`, not a 4D account name or a row number. Profile values are `1` (administrator), `2` (doctor), and `6` (nurse); administrator has no additional workflow-specific privileges.

If the startup prompt was canceled, execute the `_` project method from the remote client's Explorer. If entering an ID opens nothing, check that the client is in Remote Mode and that the ID exists. The `_` harness currently does not display registration errors.

### Test another user

For sequential testing, close all workflow windows before changing identity. Execute `Messaging_Client_Unregister`, then execute `_` and enter another fixture ID, such as **18**. Reopen the workspace after registration so its form handlers use the new identity.

For live messaging tests, connect **two separate remote client instances** to the same local server:

| Client | Example ID | Purpose |
|---|---:|---|
| A | 17 | Send messages and create or assign tasks |
| B | 18 | Receive messages, inspect badges, and complete assigned tasks |

Registration uses the name `Messaging.User.<ID>`. Use different IDs on concurrently registered clients. Opening two workflow windows in one client is not a substitute: the client has one registered identity in shared storage.

### Manual verification

1. From user 17, create a direct conversation with user 18 and send a message.
2. On user 18, verify the incoming notification and unread-conversation badge while Messaging is not showing that conversation.
3. Open the conversation: its unread indicator clears. Verify the list moves conversations with newer messages to the top.
4. Create a group conversation and repeat with additional users.
5. Right-click a message and choose **Convertir ce message en tâche**. The workspace should switch to Tasks and show a new task with the message text prefilled. Save to persist it.
6. Assign unfinished tasks to user 18, with and without urgency. Both contribute to the task badge; only urgent assignment generates the urgent-task OS notification.
7. Complete an assigned task and verify both the task badge and combined launcher badge update. Completing a shared task completes it for every assignee.
8. Verify zero-count badges disappear and Tasks/Messaging buttons highlight the selected tab in light blue.

The messaging badge counts **conversations with unread messages**, not individual messages. Random seed data can already contribute to badge totals.

## 4. Run the compilation check

From a normal terminal in the repository root:

```powershell
Get-Command tool4d.exe
.\compile-test.bat
```

The script runs:

```text
tool4d.exe "Project/syseo-workflow.4DProject" --dataless --skip-onstartup --startup-method "CLI_COMPILE"
```

Run it **outside any sandbox**. When using Codex, request unsandboxed execution as required by `AGENTS.md`.

`CLI_COMPILE` performs a syntax/compilation check without opening application data or running the user prompt. Look for `[PASS]` or `[FAIL]` and the printed diagnostics; do not rely only on the process exit code. This check does not seed data or exercise UI, notifications, or multi-user behavior. Use the manual checks above for those behaviors.

## 5. Integrate as a component in Syseo Endo

### Prepare the host schema

This repository's documented integration model uses the **host datastore**. The development catalog simulates the host's `Utilisateur` and `Patient`; installing a component does not migrate this schema or copy the development data. Validate the integration on a backed-up test copy of Syseo Endo before deployment.

The host must provide:

| Host dataclass | Required fields |
|---|---|
| `Utilisateur` | `xNumUser` (int32 primary key), `Nom`, `Initiales`, `Privilèges` (integer) |
| `Patient` | `NoDossier` (int32 primary key), `Nom`, `Prénom`, `Date Naissance` |

The workflow-owned dataclasses are `Conversation`, `ConversationMember`, `Message`, `Task`, `TaskAssignee`, `Tag`, and `TaskTag`. Preserve their field, index, and relation definitions from the project catalog. Workflow primary keys are integer `ID` fields generated by sequences.

For the binary Syseo Endo host:

1. Back up its structure and data, then export the host structure to XML from 4D Developer 20 R7 in standalone interpreted Design mode.
2. From this repository root, generate an additive import:

   ```powershell
   .\Migration\New-HostSchemaMigration.ps1 `
       -HostStructurePath 'C:\Migration\SyseoEndo.structure.xml' `
       -OutputPath 'C:\Migration\SyseoWorkflow.structure.xml'
   ```

3. Follow [Migration/README.md](Migration/README.md) to import the generated XML **once**, from the host in standalone Design mode, then restart it.
4. Create the six host-facing relations listed in [Migration/HOST_RELATIONS.md](Migration/HOST_RELATIONS.md), using the exact names. The generator includes the eight internal relations but omits these six links to existing host tables.

Do not import the development `Utilisateur` or `Patient` tables, run `_SEED` in the host, or repeat the initial additive import as an upgrade procedure. See [COMPONENT_INTEGRATION.md](COMPONENT_INTEGRATION.md) for the full data contract.

### Build and install the component

1. Open this project with 4D Developer 20 R7 and run the compilation check.
2. In **Design > Build Application**, choose **Build component** on the compiled structure page and select an output directory.
3. Copy the generated `syseo-workflow.4dbase` package, including its `.4dz` file and `Resources`, into the host's `Components` folder. For a binary host, this folder sits beside the host structure file.
4. Restart the host/server to load the component; reconnect remote clients. Compile the host with the component installed and verify all ORDA dataclasses and relations.

The official [4D component build documentation](https://developer.4d.com/docs/20/Desktop/building#build-component) describes the generated `.4dbase` package. A compiled host requires a compiled component; the shared project methods are its public entry points ([4D component documentation](https://developer.4d.com/docs/20/Extensions/develop-components#sharing-of-project-methods)). The methods below are already marked shared in this repository.

### Connect the Syseo Endo client lifecycle

After Syseo Endo authenticates its user, pass that user's actual `Utilisateur.xNumUser` to `Messaging_Client_Register` **on the remote client**. Handle the returned `success` and `error` properties. The test `_` prompt is not an authentication mechanism and must not be used for production login.

For example, in a host wrapper receiving the authenticated ID:

```4d
#DECLARE($currentUserId : Integer)
var $registration : Object

$registration:=Messaging_Client_Register($currentUserId)
If ($registration.success)
    Launcher_Client_Open
Else
    ALERT($registration.error)
End if
```

Alternatively, bind a host menu/button to `Launcher_Client_Open` after registration. `Messaging_Client_Open` opens the shared workspace directly on Messaging. Keep identity registration at the session level, not on every navigation click.

Call `Messaging_Client_Unregister` during host logout or client exit. Close workflow windows before switching users, then register the new ID and reopen them. Wire these calls into the host lifecycle explicitly; do not assume this development project's startup/exit methods will perform host initialization.

Finally, repeat the two-client manual verification above against the Syseo Endo test host. Check message delivery/read status, conversion into the embedded task editor, assignment/completion, and combined badge totals before deploying the component.
