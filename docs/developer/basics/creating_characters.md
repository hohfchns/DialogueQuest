# Creating Characters

Before we starting creating dialogues, we need to know how to create characters.

Creating characters is quite simple, simply create a new `DQCharacter` Resource in your [Data Directory](#the-data-directory), and DialogueQuest will automatically be able to find and use it.

When creating a characters, you must provide a `character_id`. This is how the character will be referred to in [DQD](#writing-dialogue).

If multiple resources use the same ID, the first character found by the directory
scan is used. Use unique IDs when you need an unambiguous reference. You can rescan
from code with `DialogueQuest.CharacterDB.refresh()`. Refreshing the editor list
clears its selection so old row positions cannot select different characters.

