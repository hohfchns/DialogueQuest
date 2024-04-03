# DialogueQuest signals


There are a few important signals in DialogueQuest:

## The error signal

DialogueQuest uses `assert` statements for it's critical errors, which will pause the game when running in the editor, however will not do so in a release build.

For the purpose of handling errors in release builds as well as GUI, DialogueQuest emits the `DialogueQuest.error(message: String)` signal when an error occures.

## DQSignals

Other main signals are available via the `DQSignals` instance `DialogueQuest.Signals`

The signals are:

- dialogue_started(dialogue_path: String)
- dialogue_ended(dialogue_path: String)
- dialogue_signal(params: Array)
    - Emitted via the `signal` statment in dialogue.
- choice_made(choice: String)
    - Emitted when a player makes a choice during dialogue.

## See also

The `signal` statement in the user manual.

The `choice` statement in the user manual.

