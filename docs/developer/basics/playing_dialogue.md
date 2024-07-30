# Playing Dialogue

## Scene setup

To play dialogue, you should set up your scene as follows:
```
...
CanvasLayer
    DQDialoguePlayer
    DQDialogueBox
    DQChoiceMenu
...
```

Click on the `DQDialoguePlayer` and provide it with the `DQDialogueBox`, as well as `DQChoiceMenu`.

Also create a `DQDialoguePlayerSettings` for it. It is recommended to save this resource as a file in your project.

You can also do this setup through code, however make sure the `DQDialoguePlayer` node set up before it is added to the scene.

When setting up the scene, make sure you instantiate the scene for each component, rather than instantiating the script object.

The scenes can be found at the following paths:

```
prefabs/systems/dqd/dialogue_player.tscn
prefabs/ui/dialogue/components/dialogue_box/dialogue_box.tscn
prefabs/ui/dialogue/components/choice_menu/choice_menu.tscn
```

## Starting the dialogue

In order to start the dialogue, use the `DQDialoguePlayer.play()` method.

``` gdscript
dialogue_player.play("my_dialogue_name")
# These are also valid ways to provide the dialogue
# dialogue_player.play("my_dialogue_name.dqd")
# dialogue_player.play("res://dialogue_quest/my_dialogue_name.dqd")
```

**Take note -** If your `.dqd` file is not in your [data directory](#the-data-directory), you will have to provide the full filepath.

## Stopping the dialogue

If you want to stop the dialogue early, you can call the `DQDialoguePlayer.stop()` method which will end the dialogue early.

