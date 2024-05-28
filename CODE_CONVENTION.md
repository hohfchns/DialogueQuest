# DialogueQuest codebase convention

# File structure

All project files must be in `snake_case` format.

The folder structure is organized like so:

```
├── addons
│   └── dialogue_quest
│       ├── art
│       ├── prefabs
│       ├── resources
│       └── scripts
```

`art` is for image-related files (aseprite, png, jpeg, etc.).

`prefabs` is for Godot scenes that are not meant to be the "main scene" of the game.

`resources` is for Godot resources.

`scripts` is for any GDScript files.

The subfolders of each of these primary folders should be more or less mirrored, especially with `prefabs` and `scripts`, which should be exact mirrors for filepaths between a prefab (scene) and it's script.

Some notable subfolders are:
- `scripts/helpers` - Contains scripts that help with general coding
- `resources/components/settings` - Contains default Settings resources (sane defaults) for DialogueQuest components

# Comments

Comments should be used only when necessary.

Good times to comment are:

- The naming or code flow is confusing or unclear, and cannot clarify itself
- Warning of a potentially unexpected operation. for example, modifying a node passed to a function
- Explaining "smart" code. For example, doing a mathematical operation on generics

# Error Handling

Godot does not natively support Exceptions, however DialogueQuest makes use of some alternatives:

## Asserts

DialogueQuest makes heavy use of `assert` statements

A function should always aim to cover all of it's failing points with `assert` statements

It is always better to fail expected in an expected way, and give the user information on what went wrong

## DialogueQuest.error signal

DialogueQuest has the signal `DialogueQuest.error`, which is emitted when an expected error occurs, and is usually combined with `assert`.

A very common pattern in the DialogueQuest code is:

``` gdscript
func do_something(with: Array) -> void:
    if with.size() < 5:
        var s := "DialogueQuest | Error | do_something | Length of `width` should be at least 5"
        DialogueQuest.error.emit(s)
        assert(false, s)
```

This allows us to handle errors both in debug, and in an actual game.

A good example of it's power is the [DialogueQuestTester](https://github.com/hohfchns/DialogueQuestTester) app. It uses the `DialogueQuest.error` signal to display a popup showing the error that occured to a user, and when running in the editor, the assert sends you right to the failing point.

# GDScript

## Classes

DialogueQuest scripts should always provide a `class_name`.

Every class name in DialogueQuest should start with `DQ` to avoid potential conflicts with a user project. The same naming convention goes for Autoloads, except for the wrapper Autoload `DialogueQuest`.

Class names should always be in `CamelCase` with a capital letter for every word. Any abbreviation that is 2 letters or less should be capitalized fully:

``` gdscript
# BAD! Needs to start with DQ
class_name MyClass
# GOOD! 
class_name DQMyClass

# BAD! Abbreviation of 2 letters should be capitalized
class_name DQMyDb
# GOOD! 
class_name DQMyDB

# GOOD! Abbreviation is 3 letters, it's okay to only capitalize first
class_name DQMyDndGame
```

### Autoloads

DialogueQuest uses a single Autoload with the class_name `DQInterface` and the Autoload name `DialogueQuest`.

Instead of adding more Autoloads which could dirty a user project, we add our class as a child of `DQInterface`, like so:

``` gdscript
# dialogue_quest_interface.gd

# Create the instance as a private member
var _new_system := DQNewSystem.new()

# Create a public property that returns our instance and disables the setter
var NewSystem: DQNewSystem:
    set(value):
        pass
    get:
        return _new_system

# ....

func _ready() -> void:
    add_child(_new_system)

```

### Static Classes

Some classes in DialogueQuest feature state-agnostic code, and nothing but static functions.

These functions will usually be found in the `scripts/helpers` folder.

### Local Classes

DialogueQuest encourages use of local classes, as they provide namespace-like functionality and allow for more explicit typing.

See the following example:

``` gdscript
# a.gd
class_name MathClass

static func add_ints(left: int, right: int) -> Dictionary:
    return {
        "left": left,
        "right": right,
        "sum": left + right
    }

# b.gd
func _ready() -> void:
    var res: Dictionary = MathClass.add_ints(1, 2)
    print(res["left"])
    print(res["right"])
    print(res["sum"])

# ---------------------------------------- #
# a.gd
class_name MathClass

class AddIntsResult:
    var left: int
    var right: int
    var sum: int

    func _init(left: int, right: int, sum: int):
        self.left = left
        self.right = right
        self.sum = sum

static func add_ints(left: int, right: int) -> AddIntsResult:
    return AddIntsResult.new(left, right, left + right)

# b.gd
func _ready() -> void:
    var res: MathClass.AddIntsResult = MathClass.add_ints(1, 2)
    print(res.left)
    print(res.right)
    print(res.sum)
```

The second example is much preferable, as it provides a more explicit return type with less room for error and confusion.

## Private Members

Member functions/variables/signals/etc. can be marked as private by using the `_name` syntax, like so:

``` gdscript
# a.gd
class_name A
var public_var: int = 0
var _private_var: int = 1
var _my_var: float = 0.1

func say_hello() -> void:
    print("Hello World")

func _function_a() -> void:
    print("This should only be called by A")

# b.gd
func _ready() -> void:
    var my_a := A.new()

    # Good!
    print(my_a.pubic_var)

    # Bad!
    print(my_a._private_var)

    # Good!
    my_a.say_hello()

    # Bad!
    my_a._function_a()
```

Private signals are also supported by this syntax, however a private signal is quite uncommon, and should be avoided when possible.

Whenever declaring member variables and functions, always consider the publicity of it.

A member not marked as private means anyone who has access to the object can and *should* use that member.

## Functions

All functions must use `snake_case` naming.

Function names should always be descriptive of their functionality unless context makes sense of it.

### Docstrings

Most functions don't need docstrings. Docstrings should be used when the function's name and parameters cannot fully explain what it does.

A function like `print(string: String) -> void` does not need a docstring, however a function like `run_algorithm(with_args: Array) -> int` does.

Docstring convention has a few enforced rules in DialogueQuest:

Adhere as much as possible to the [official GDScript docstring syntax](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html)

- Types must be properly marked: (`int` -> Bad) | (`[int]` -> Good)

Dictionaries with intended types or parameters must be explained in a docstring. You can write dictionary typing similar to the following:

``` gdscript
## A Dictionary of format { food([String]) : cost([int]) }
var food_cost: Dictionary { "Apple": 2, "Tomato": 1 }
```

### Typing

Functions must always define the types for arguments and returns, unless they specifically take in or return a generic type.

If the function does return a generic type, it must be explained in the docstring, for example:

``` gdscript

func py_sum_int(a: int, b: int) -> int:
    return a + b

## Emulates python integer division
## Returns an [int] if there is no remainder on division, otherwise returns a [float]
func py_div_int(a: int, b: int):
    if a % b == 0:
        return int(a / b)
    return float(a) / float(b)

```

## Variables

A variable in DialogueQuest should always be typed, unless it specifically intended for it to be a generic.

It is also recommended to use the `:=` operator, especially when using `ClassName.new()`

``` gdscript
# Bad!
var a = 0

# Good!
var a: int = 0

# Good!
var a: float = 0

# Good!
var a := 0

# Bad!
var a = Button.new()

# Good! But not recommended
var a: Button = Button.new()

# Good!
var a := Button.new()
```

When using functions that return generics / superclasses, always try to convert to your required node with the `as` keyword.


``` gdscript
func add_button(btn_scene: PackedScene) -> void:
    var btn := btn_scene.instantiate() as Button

    assert(btn != null, "DialogueQuest | Fatal Error | Cannot create scene, `add_button` provided non-button scene")

    add_child(btn)
```

When iterating children, always verify their types if possible.

``` gdscript
# This is also fine!
func get_buttons() -> Array[Button]:
    var res: Array[Button] = []
    for c in get_children():
        if c is Button:
            res.append(c)
    return res
```

### Properties

Properties are public member variables with setters and getters.

They have the same syntax as a regular variable, however their setters and getters are closer to functions.

For example:

``` gdscript
var buttons: Array[Button] = [] : set = set_buttons, get = get_buttons

func set_buttons(value: Array[Button]) -> void:
    for c in get_children():
        if c is Button:
            remove_child(c)
            c.queue_free()

    for b in value:
        add_child(b)

func get_buttons() -> Array[Buttons]:
    var res: Array[Button] = []
    for c in get_children():
        if c is Button:
            res.append(c)
    return res
```

### Wrapper Properties

Wrapper Properties are Properties that specifically act as a sort of pointer to another object's member properties, for example:

``` gdscript
# a.gd
    class_name A

@export
var _label: Label

var text: String :
    set(value):
        if not _label:
            await ready
        text = value
        _label.text = value
    get:
        if not _label:
            # We do not want an async getter, so we just count on _label being present in runtime
            return text
        return _label.text

# b.gd
@export
var a: A

func _ready() -> void:
    print("A has a label with text: %s" % a.text)
    a.text = "Now it is different"
    print("A has a label with text: %s" % a.text)
```

In this example, `A`'s `text` property is a wrapper for it's label's text.

This allows us to directly edit the label's text via an `A` node/scene, whether in code or in editor.

## StringName

[StringNames](https://docs.godotengine.org/en/stable/contributing/development/core_and_modules/core_types.html#stringname) are Godot's way of optimizing constant strings, and comparing two equal StringName is an extremely fast operation.

StringNames should be used as much as possible where they make sense. For example an ID, a name, filepaths, or anything that will not change during runtime.

StringNames are also implicitly caster to String by Godot when needed, so there is no reason to avoid them.

# Prefabs

## Settings Resources

When creating a new component, especially UI components, you should create a settings resource for it, that defines the common options that it can work upon.

This makes the process of configurating and swapping between configurations much easier.

## Component Children

When creating a new component, never rely on the user of the component having direct access to it's children, whether from code or the editor.

Instead, you have the following alternatives, assuming the user will need access to the child:

- Have the user supply the child, similar to the way Area/Body objects require their CollisionsShape children to be supplied. You can do this either by child detection or by @export'ing the node.
- Add [wrapper properties](#wrapper-properties) for any parameters of the child that the user might want to edit.
- Give access to the child via code. This method is least preferable as you cannot edit the child in the editor this way.

You should **never** rely on Godot's `Editable Children` option, as it is very buggy and breaks often.

# Documentation

You are more than welcome to contribute to the documentation of the project.

All of the documentation is present in the `docs/` folder of the repository, and sorted in a sensical way.

The files in `docs/developer/` are exculsively for the Developer Guide, while the files in `docs/user` are exclusively for the User Guide.

The User Guide should only contain contents that are relevant to `DQD` and writers, it should contain no info directly regarding Godot. A safe assumption is that everyone reading it is solely a user of [DialogueQuestTester](https://github.com/hohfchns/DialogueQuestTester), and has no knowledge otherwise.

The Developer Guide should contain contents that are relevant to Godot users, DialogueQuest developers, and anything inbetween. It should contain up-to-date knowledge on the main systems of DialogueQuest, how they work, and how to use them or extend them within a Godot project.

When contributing to the documentation, you should compile the PDF files for yourself to **test them**, however **do not commit them**, as that is the responsibility of the project developers.


