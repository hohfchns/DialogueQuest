# The flag statement

A `flag`, is simply a value that can exist, or not exist.

The act of creating a flag is called `raising` it, afterwards we can check if it exists, and what it is set to.

It's usage is:

```
flag | raise | [flag]
flag | set | [value] | [flag]
flag | inc | [flag]
flag | inc | [amount] | [flag]
flag | dec | [flag]
flag | dec | [amount] | [flag]
flag | delete | [flag]
```
A basic example would be:

```
flag | raise | is_using_dialogue_quest

// This will happen
branch | flag | is_using_dialogue_quest
    say | We are using DialogueQuest.
branch | end

// This will not happen
branch | no_flag | is_using_dialogue_quest
    say | We are NOT using DialogueQuest.
branch | end
```

You can also use `flag | inc` and `flag | dec` to use integer (whole number) flags:

```
flag | inc | money

// Will say `I have 1 money`
say | I have ${money} money

flag | inc | 6 | money

// Will say `I have 7 money now`
say | I have ${money} money now

flag | dec | money

// Will say `I have 6 money now`
say | I have ${money} money now
```

You can use `flag | set` to set a flag as an arbitrary value like so:

```
flag | set | Mage | player_class

// Will say `Oh sick! I am a Mage`
say | Oh sick! I am a ${player_class}

flag | set | 20 | number_of_enemies

// Will say We have 20 enemies here, that's a lot!
say | We have ${number_of_enemies} enemies here, that's a lot!
```

*Do note the quatations around the word Mage, indicating it is a [String value](https://en.wikipedia.org/wiki/String_(computer_science))*

And finally, you can delete a flag as well:

<pre>
```
flag | raise | road_is_safe

// Will say `<i>The player proceeds forward</i>`
branch | flag | road_is_safe
    say | [i]The player proceeds forward
branch | end
branch | no_flag | road_is_safe
    say | [i]The player stays back
branch | end

flag | delete | road_is_safe

// Will say `<i>The player stays back</i>`
branch | flag | road_is_safe
    say | [i]The player proceeds forward
branch | end
branch | no_flag | road_is_safe
    say | [i]The player stays back
branch | end
```


