# The Flags system

Flags are global variables that can be accessed from both code and dialogue.

They are accessible via the global `DQFlags` instance `DialogueQuest.Flags`

An example:

``` gdscript

DialogueQuest.Flags.raise("flag1")

DialogueQuest.Flags.set_flag("flag2", 2)

DialogueQuest.Flags.set_flag("flag3", "a third flag")

# Outputs 2
print(DialogueQuest.Flags.get("flag2"))

# Outputs 'A third flag'
print(DialogueQuest.Flags.get("flag3"))
```

## Also see

The user manual entry on the `flag` statement

