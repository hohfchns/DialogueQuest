# Writing Dialogue - DQD

## Basics

DQD stands for `DialogueQuest Dialogue` and is the dialogue format of DialogueQuest.

The DQD format uses the `.dqd` file extension.

DQD is a simple text-based format, that goes something like this:

```
statement | param1 | param2 | ...
```

Every line starts with a statement which 'moves forward' in the line like a pipeline.

The most basic and most used statement is the [say](#the-say-statement) statment, which looks like this:

```
say | joe | Hello DialogueQuest
say | You don't even need a character
```

## Comments

DQD Support comments.

A line that starts with `//` is considered a comment, and will not be parsed/executed.

Comments are useful for explaining things like branches, flags, or even leaving a comment for your team on their good work :)

Comments can also be used to temporarily disable parts of the dialogue without deleting them.

An example of comments:

```
// The line bellow is commented and will not run. This is a comment too by the way! 
// say | This is a comment, you will not see this dialogue
say | This is not a comment, you will see it
```


## Flag Solving

See [flag](#the-flag-statement)

If you have set a flag, you can get it's value with the special syntax `${flag}`

For example:

```
flag | inc | 5 | monkeys
say | There are ${monkeys} little monkeys jumping on the bed.
```

## BBCode and Text Effects

In order to have text effects and formatting such as **bold text**, *italic text*, and much more.

BBCode is a well-known format, and you can find out more about it [on the Godot documentation](https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html#reference), but here's a basic example:

```
say | italian_man | [i]I am speaking in italic! No not italian...
say | brave_man | I am brave and [b]bold[/b] in the face of danger.
say | small_man | [font_size=8]Please don't make fun of my font size, I'm quite insecure about it.
```

## See Also

[characters](#characters)

[say](#the-say-statement)

[choice](#the-choice-statement)

[branch](#the-branch-statement)

[DialogueQuest BBCodes](#dialoguequest-specific-bbcode)

