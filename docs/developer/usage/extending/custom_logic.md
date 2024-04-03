# Custom Logic

The logic of DialogueQuest is handled in the `DQDialoguePlayer` class.

In order to add custom logic, you must create a new class extending `DQDialoguePlayer`.

Once you do, you can handle your custom statement like so:

``` gdscript
## my_dialogue_player.gd
extends DQDialoguePlayer

func _ready() -> void:
    self.section_handlers.append(
        SectionHandler.new(SectionMySection, _handle_my_section),
    )

    super._ready()


func _handle_my_section(section: SectionMySection) -> void:
    # Here you have access to all parts of the DQDialoguePlayer
    print("This section doesn't do anything yet... It's statement is %s" section.statement)
```

To add a handler, we must add a `SectionHandler` object to the `section_handlers` array.

The constructor of `SectionHandler` takes two parameters, a class (object of type `GDScript`), and a `Callable`.

When the [parser](#custom-statements) returns the class you provided, the function you provided will be called with the parser's returned object.

Now we need to create our handler function, in this case `_handle_my_section`.

The function must take in an argument of your section class, in this case `SectionMySection`. It does not return anything.


