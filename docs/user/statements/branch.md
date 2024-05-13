# The Branch Statement

The branch statement allows dialogue to happen in different ways depending on a variety of factors.

When a branch statement is encountered, the dialogue can go in one way or another, like a fork in the road or *branch*es of a tree.

It is recommended to first understand [flag](#the-flag-statement), [choice](#the-choice-statement), and [flag solving](#flag-solving) as they are essential for undertstanding branching.

It's usage is:

```
branch | flag | [flag]
branch | no_flag [flag]
branch | choice | [choice1] | [choice2]...
branch | evaluate | [expression]
branch | end
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

## See Also

[flag](#the-flag-statement)

[choice](#the-choice-statement)

[flag solving](#flag-solving)

[GDScript Control Flow](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#statements-and-control-flow)

[What are Expressions?](https://www.geeksforgeeks.org/what-is-an-expression-and-what-are-the-types-of-expressions/)

[GDScript Expression class](https://docs.godotengine.org/en/stable/tutorials/scripting/evaluating_expressions.html)

