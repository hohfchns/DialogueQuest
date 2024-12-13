# The Say Statement

The say statement is the most common statement in DialogueQuest.

It's usage is:

```
say | [character_id] | [speech]
say | [character_id] | [speech] | [speech2]
say | [character_id] | [speech] | [speech2] |
say | [speech] 
say | [speech] | [speech2]
say || [speech] | [speech2] |
```

The basic use case would be:

```
say | my_character | Hey, I am saying something
```

And:

```
say | There is dialogue without character. Perhaps it is a ghost...
```

The character_id field can also be provided empty for the same result:

```
say | | I am still a ghost...
```

If you want to pause in the middle, you can use multiple speech pipes as so:

```
say | DialogueQuest is absolutely | legen|dary!
```

If you end the say statement with an empty pipe, the dialogue will advance without user input:

```
say | dude1 | Hey man so I heard about this game called DeshanimQuest and |
say | dude2 | Yeah whatever dude
say | dude1 | Hey don't cut me off like that!
```

If using it without a character, you **must** provide an empty character:

```
say | This is not going to work... |
```

```
say | | This does work though! |
```

## See Also

[Writing Dialogue](#writing-dialogue---dqd)

[BBCode and Text Effects](#bbcode-and-text-effects)


