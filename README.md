# DialogueQuest - An easy dialogue system


## What is DialogueQuest?

DialogueQuest is a dialogue system (shocker!) for the Godot 4 game engine, that is designed with a few core principles:

- Collaboration - DialogueQuest is made with the vision of separating coders from scriptwriters.
- Simplicity - DialogueQuest does not try to be anything more than it needs to be.
- Stability - DialogueQuest keeps a limited scope in order to stay managable.
- Intuitivity - DialogueQuest always attempts to be easy to grasp and pick up quickly.

## The meat and bones

The dialogue is a simple text-based format, that goes something like this:

``` markdown
*statement* | *param1* | *param2* | *...*
```

An example would be:

```
say | joe | Hello DialogueQuest user! How are you today?
say | dialogue_user | I am fine, and loving this system!
```

A more advanced example could be:

<pre>
say | joe | What else can I do with <b>[b]DialogueQuest[/b]</b>?
 
call | print("Well joe, you can use <i>[i]GDScript[/i]</i> from DialogueQuest quite easily!")
 
say | joe | Oh wow, that's great!
 
signal | "joe_is" | "happy" | true
</pre>

A few notes:
- The signal statement raises a global signal with arguments that are parsed into GDScript variables
- The call statement runs raw GDScript code
- The [b][/b] and [i][/i] are `bbcode` formatting. You can read about it [on the Godot documentation](https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html).

## How do I use it?

### Install the addon

- Clone the repository, or on Github, click `Code -> Download ZIP`
- Copy the `addons/dialogue_quest` folder to your Godot project's `addons/dialogue_quest`
- Open your Godot project and go to `Project -> Project Settings -> Plugins` and enable `DialogueQuest`
- *(Recommended)* Go to `Project -> Project Settings -> General` and search for `Dialogue Quest`, then set `Data Directory` to a folder where you will store DialogueQuest files (characters, dialogues, etc.)

### Creating dialogue

To create dialogue, create a new `.dqd` file and place it in your DialogueQuest data directory, either through the Godot file browser or your operating system.

### Creating characters

To create a character, simple create a new `DQCharacter` resource, and place it in your DialogueQuest data directory

DialogueQuest will automatically search for your character according to the `Character Id` you set for it.

### Starting dialogue

To start a new dialogue, you should set up your scene as follows:
```
...
CanvasLayer
    DQDialogueBox
        DQDialoguePlayer
...
```

Click on the `DQDialoguePlayer` and provide it with the `DQDialogueBox` through the inspector (also possible through code)

In order to start the dialogue, simply use the following code:

``` gdscript
var dialogue_player: DQDialoguePlayer = get_node(....)

dialogue_player.play("my_dialogue_name")
# There are also valid ways to provide the dialogue
# dialogue_player.play("my_dialogue_name.dqd")
# dialogue_player.play("res://dialogue_quest/my_dialogue_name.dqd")
```

*Note - In order for DialogueQuest to find the dialogue by name (and not full file path), it **must** be inside the DialogueQuest data directory*

## Advanced Usage

### Customization

Customizing is relatively easy, it is done with Godot native features.

The `DQDialogueBox` node has a `Theme` that you can replace with your own.

Each character can also override the theme for their name text or their speech text.

It is also possible to create a subclass of `DQDialogueBox` or `DQDialoguePlayer` to customize behaviour even further.

