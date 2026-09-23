# Relations to existing host tables

After importing `new.xml`, create these six relations in the 4D Structure editor.
For every relation, the component field is the N/source field and the host field
is the 1/destination field. Enter the relation names exactly as shown because
the component's ORDA code uses them as attributes.

| N/source field | 1/destination field | N to 1 name | 1 to N name |
|---|---|---|---|
| `Conversation.ID_creator` | `Utilisateur.xNumUser` | `creator` | `createdConversations` |
| `ConversationMember.ID_Utilisateur` | `Utilisateur.xNumUser` | `utilisateur` | `conversationMemberships` |
| `Message.ID_sender` | `Utilisateur.xNumUser` | `sender` | `sentMessages` |
| `Task.ID_creator` | `Utilisateur.xNumUser` | `creator` | `createdTasks` |
| `Task.ID_Patient` | `Patient.NoDossier` | `patient` | `tasks` |
| `TaskAssignee.ID_Utilisateur` | `Utilisateur.xNumUser` | `utilisateur` | `taskAssignments` |

The field types on both sides must be 32-bit integers. `Utilisateur.xNumUser`
and `Patient.NoDossier` must remain their respective primary keys.

The other eight relations are internal to the imported component tables and are
included in `new.xml`.
