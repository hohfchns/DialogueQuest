# DialogueQuest specific BBCode

If you haven't already, check out the [BBCode and Text Effects](#bbcode-and-text-effects) section.

DialogueQuest implements a few custom BBCodes:

## The `speed` bbcode

The `speed` bbcode sets the dialogue speed (letters per second) within the bounds of the BBCode.

For example:

```
say | This is a regular say statment
say | [speed=1]This is a suuuper slooow say statment
say | [speed=500]This is a really fast say statment
say | [speed=10]Now I'm slow[/speed][speed=100] And now I'm fast
```

## The `pause` statement

The `pause` statement makes the dialogue pause for a specified time (in seconds) before automatically continuing.

For example:

```
say | I have hi[pause=0.5]-hiccups and a bit of a s[pause=0.1]-s[pause=0.1]-s[pause=0.1]-tutter
```

# See Also

[DQD](#writing-dialogue---dqd)

[BBCode and Text Effects](#bbcode-and-text-effects)

