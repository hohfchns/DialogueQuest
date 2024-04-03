# Theming

DialogueQuest uses mostly Godot's native Theme system for designing how the interface looks.

You can create a new Theme and import the settings from the default DialogueQuest theme, or create one completely from scratch as the default theme is quite small.

The main way of customizing dialogue components in DialogueQuest is simply creating an inherited scene, and changing it however you like.

Some nodes such as `DQDialogueBox` have `settings` objects, for example `DQDialogueBoxSettings`, which provides some common customizations.

## See Also

[Theme](https://docs.godotengine.org/en/stable/classes/class_theme.html)

[Using the theme editor](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_theme_editor.html)

