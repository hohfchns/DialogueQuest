# Settings

Settings come from the `dialogue_quest` category in Project Settings, both in the
editor and exported games. All systems use the effective values exposed by
`DialogueQuest.Settings`. Standalone tools can override those values at runtime.

Older `.dialogue_quest_settings.conf` files are read only when the corresponding
Project Setting is absent. When migrating, set `data_directory` and `say_by_name`
in Project Settings to the values you want, then remove the legacy file if desired.
New projects do not need this file or an export filter for it.

`DialogueQuest.Settings.get_settings()` remains available and returns a
`ConfigFile` snapshot of the current effective values.

## Settings Options

- `data_directory`
  - The data directory is explained in the [data directory](#the-data-directory) section.
- `say_by_name`
  - If enabled, the `say` statement will be optional, and will automatically be used if the statment is a valid character ID. This may save time for writers, and is enabled by default.

## Also see

[data directory](#the-data-directory)

The user manual entry on the `say` statement

