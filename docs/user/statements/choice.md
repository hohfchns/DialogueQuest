# The choice statement

The choice statement will bring up a menu with items that the user has to choose from.

It is inherently dependant on the [branch](#the-branch-statement) statement

It's usage is:

```
choice | [choice1] | [choice2]...
```

For example:

```
say | Which one do you like better? Apples or Oranges?
choice | Apples | Oranges | You can't compare

branch | choice | Apples
    say | Doctors hate you
branch | end
branch | choice | Oranges
    say | Juicy!
branch | end
branch | choice | You can't compare
    say | You're just so smart, aren't you?
branch | end
```

