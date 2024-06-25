# The Sound Statement

The `sound` statement allows you to play a one-time sound.

It's usage is:

```
sound | [sound]
sound | [sound] | [channel]
sound | [sound] | [channel] | [volume]
```

`sound` can be either a filepath to your sound, or if the sound file is within your [data directory](#the-data-directory) you can specify it by just the file name.

`channel` is an audio channel defined by a developer. If you are unsure which to specify, use the default `Master` channel.

`volume` is a volume that will be added/subtracted from the channel's default volume (in Decibels).

Here is a basic example:

```
sound | gunshot
sound | gunshot | Master | -30.0
sound | gunshot | SFX
sound | gunshot | SFX | 20.0
```

