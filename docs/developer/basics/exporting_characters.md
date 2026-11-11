# Exporting Characters


DialogueQuest allows for exporting your characters to files that can then be imported in DialogueQuestTester or another Godot project using DialogueQuest.

Exported DialogueQuest characters are saved in the `.dqc` format.

*Note - Exported characters are **not** Godot resources. Their only functionality is exporting and importing.*

To export, go to the `DialogueQuest` tab in the Godot editor, select your characters, and click `Export`. You will then be prompted for the directory to save the characters in.

To import, go to the `DialogueQuest` tab in the Godot editor, and press `Import`, then select all relevant `.dqc` character files.

Imports validate character fields before applying them. Existing destination files
are replaced only after the new file has been written successfully. Duplicate
destination names within one batch are reported and skipped after the first success.
The reported count includes only successful writes; a partial batch reports an error.

Character IDs must be valid non-empty filenames without path separators. The
`serialize_to_file`, `deserialize`, and `deserialize_from_file` methods return an
`Error` value (`OK` on success), and report failures through `DialogueQuest.error`.

`.dqc` files contain metadata and references to portraits and themes, not the assets
themselves. Copy those assets to matching paths in the receiving project when needed.
Unavailable optional resources are omitted, with an informational message; character
metadata can still be imported by the Tester.

# See Also

[DialogueQuestTester](#dialoguequest-for-non-coders)

