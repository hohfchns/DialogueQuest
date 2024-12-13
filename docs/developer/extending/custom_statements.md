# Custom Statements

DialogueQuest allows you to add custom statements to `DQD` and extend the featureset of `DqdParser`

To do so, do the following:

``` gdscript
## my_node_or_autoload.gd

class SectionMySection extends DQDqdParser.DqdSection:
    var statement: String

    func solve_flags() -> void:
        pass

func _ready() -> void:
    DQDqdParser.statements.append(
	    DQDqdParser.Statement.new("my_statement", _my_statement_func)
    )

## Returns SectionPipeline on success
## Returns DQDqdParser.DqdError on failure
static func _my_statement_func(pipeline: PackedStringArray):
    if pipeline.size() <= 2:
        var error := DQDqdParser.DqdError.new("Error! Cannot parse statement my_statement, please provide at least 2 arguments.")
        return error

    var sec := SectionMySection.new()
    sec.statement = pipeline[1] + pipeline[2]
    return sec
```

First we create a new section class which extends `DQDqdParser.DqdSection`, this can be either a localy defined class like the example, or a new script with `class_name` definition.

We can give it the `solve_flags()` method which will define how the `${flag}` syntax works in [DQD](#writing-dialogue).

Now we need to create our parser function, in this case `_my_statement_func`. Note that the `static` is optional, however the rest of the signature is critical.

The function must take in an argument of type `PackedStringArray`, and must return either an object of class inheriting `DqdSection` indicating it is successful, or `DqdError` indicating it has failed.

The `pipeline` argument is an array of every pipe-seperated argument in the line the statement was found in.

Note that:
- It contains the statement itself (always, at index 0)
- It contains whitespace, you can use the helper functions `DQScriptingHelper.remove_whitespace`, `DQScriptingHelper.trim_whitespace`, `DQScriptingHelper.trim_whitespace_prefix`, `DQScriptingHelper.trim_whitespace_suffix`.

Lastly we must add a new `DQDqdParser.Statement` object to `DQDqdParser.statements`.

The `DQDqdParser.Statement` constructor takes 2 arguments:
- The statement itself, the word that will be referred to in DQD.
- The callback function that will be used to parse the the statement.


Right now, your statement is parsed, however it cannot actually do anything until you implement it's logic. See [Custom Logic](#custom-logic)


