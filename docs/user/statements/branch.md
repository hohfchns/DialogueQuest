# The Branch Statement

The branch statement allows dialogue to happen in different ways depending on a variety of factors.

When a branch statement is encountered, the dialogue can go in one way or another, like a fork in the road or *branch*es of a tree.

It is recommended to first understand [flag](#the-flag-statement), [choice](#the-choice-statement), and [flag solving](#flag-solving) as they are essential for undertstanding branching.

It's usage is:

```
branch | choice | [choice1] | [choice2]...
branch | evaluate | [expression]
branch | end

branch | flags | [flag1] | [flag2]...
branch | flag | [flag]
branch | flag | [flag1] | [flag2]...
branch | no_flag | [flag]
branch | no_flag | [flag1] | [flag2]...
branch | flag > | [flag] | [value]
branch | flag < | [flag] | [value]
branch | flag = | [flag] | [value]
branch | flag != | [flag] | [value]
branch | flag >= | [flag] | [value]
branch | flag <= | [flag] | [value]
```

A simple example of a branch would be:

```
say | Let's see about this branching thing

flag | raise | loves_dialogue_quest

branch | flag | loves_dialogue_quest
    // We will see this
    say | I love DialogueQuest!
branch | end

branch | no_flag | loves_dialogue_quest
    // We will not see this
    say | I HATE DialogueQuest!
branch | end
```

A branch checks a **condition**, and if it finds that condition to be **true**, it runs the contents until it reaches the next `branch | end` statement.

## Choice

When using choices, we must use the `branch | choice` statement, like so

```
choice | a | b

branch | choice | a
    say | We picked A
branch | end
branch | choice | b
    say | We picked B
branch | end
```

We do not have to provide a branch for every choice.

We can also check for multiple choices, like so:

```
choice | a | b | c | d

branch | choice | a | b
    say | We picked either A or B!
branch | end
```

## Evalute

`evaluate` is the most complex branch statement, and will use [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#statements-and-control-flow) to solve the branch.

It can be used like the following:

```
branch | evaluate | true
    say | This will always happen.
branch | end

branch | evaluate | false
    say | This will never happen.
branch | end

branch | evaluate | 5 == 10
    say | This won't happen because 5 is not 10 :)
branch | end

branch | evaluate | 10 > 5
    say | This will happen.
branch | end

branch | evaluate | 5 != 10
    say | This will happen.
branch | end

branch | evaluate | 5 >= 5
    say | This will happen.
branch | end

branch | evaluate | this == that
    say | This won't happen.
branch | end

branch | evaluate | that == that
    say | This will happen.
branch | end

```

evaluate can also be used with [flag solving](#flag-solving)

```
branch | evaluate | ${main_character} == joe
    say | joe | Yo, uh-huh
branch | end

branch | evaluate | ${number_of_corners} == 3
    say | This is my hat
branch | end

// You can also use the 'or', 'and', '&&', '||' statements to check multiple conditions.
branch | evaluate | ${number_of_corners} > 3 or ${number_of_corners} < 3
    say | This is not my hat
branch | end
```

## Flags

The `branch | flag` statement is quite versatile, and can be used in a few ways:

This is the simplest flag check:

```
branch | flag | some_basic_flag
    say | This really is basic
branch | end
```

We can also check multiple flags at the same time:

```
branch | flag | red_flag | green_flag
    say | I'll choose either anyway
branch | end

flag | raise | green_flag
branch | flag | red_flag | green_flag
    // We will see this
    say | Great!
branch | end

flag | delete | green_flag
flag | raise | red_flag
// Only red_flag is raised at this point
branch | flag | red_flag | green_flag
    // We will see this
    say | Still great...?
branch | end

branch | flag | orange_flag
    // We will not see this
    say | What does an orange flag mean?
branch | end
```

In the above example, the branch will be entered if *any* of the flags are raised.

There is also the alternative `branch | flags` (note the `s` for plural), which will only be entered if *all* flags are raised

```
flag | raise | table
flag | raise | tea

branch | flags | table | tea
    // We will see this
    say | Tea is great.
branch | end

branch | flags | table | plate
    // We will not see this
    say | Cookies are great.
branch | end
```

Finally there is the `branch | no_flag` statement, which will only be entered if *none* of the flags are raised

```
flag | raise | pickles
flag | raise | lettuce

branch | no_flag | knife
    // We will see this
    say | How will I cut my pickles?
branch | end

branch | no_flag | pickles | tomatoes | lettuce
    // We will not see this because
    say | I love my burgers dry as the desert.
branch | end
```

## Flag operators

The `branch | flag` also has versions for using comparison operators, such as `> (greater than)`, `< (lesser than)`, `= (equals)`, `>= (greater than or equals)`, and `<= (lesser than or equals)`.

```
flag | set | 10 | stairs

branch | flag >= | stairs | 11
    // We will not see this
    say | I'm gonna take the elevator.
branch | end

branch | flag != | stairs | 0
    // We will see this
    say | We have stairs
branch | end

branch | flag < | stairs | 2
    // We will not see this
    say | Even a baby can climb these
branch | end

branch | flag = | stairs | 10
    // We will see this
    say | The perfect amount of stairs
branch | end
```

## See Also

[flag](#the-flag-statement)

[choice](#the-choice-statement)

[flag solving](#flag-solving)

[GDScript Control Flow](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#statements-and-control-flow)

[What are Expressions?](https://www.geeksforgeeks.org/what-is-an-expression-and-what-are-the-types-of-expressions/)

[GDScript Expression class](https://docs.godotengine.org/en/stable/tutorials/scripting/evaluating_expressions.html)

