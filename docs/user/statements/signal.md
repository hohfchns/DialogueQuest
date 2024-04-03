# The signal statement

The signal statement does not quite do anything for the user.

It's functionality is sending a "message" of sorts for the Godot developer to implement into concrete functionality.

It's usage is:

```
signal | [param1] | [param2]...
```

For example:

```
signal | "play_song" | "Nightcall - Kavinsky"
```

The developer can for example check for the signal value "play_song", and play the song accordingly.

Also see:

Developer manual entry for [signals](#signals)


