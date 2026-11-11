# Exporting

When exporting your game, it is vital to include `.dqd` files in your build.

- Go to `Project -> Export`
- Select the platform you are exporting to (Linux/Windows/Web/etc.)
- Select the `Resources` tab
- Under `Filters to export non-resource files/folders`, add `*.dqd`

DialogueQuest reads Project Settings in exported games. If you still rely on a
legacy `.dialogue_quest_settings.conf` file, migrate its values to Project Settings
before removing `*.conf` from an existing export filter.



