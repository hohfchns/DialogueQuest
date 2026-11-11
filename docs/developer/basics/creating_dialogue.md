# Creating Dialogue

Use **Project > Tools > Validate DialogueQuest Dialogue** to check a `.dqd` file
without playing it. Validation reports syntax errors and unmatched branches with
their source file and line number.

Code and standalone tools can use `DQDqdParser.validate_from_file(path)` or
`DQDqdParser.validate_from_text(text, source_path)`. Both return a `ParseResult`
with `sections`, `errors`, and `is_valid()`. Only play sections from a valid result.
Validation does not execute dialogue commands or emit `DialogueQuest.error`.
The existing `parse_from_file` and `parse_from_text` methods still emit errors and
assert on invalid input; in release builds they return an empty array on failure.

To create a dialogue, simply create a new `.dqd` file.

If you put the file in your [data directory](#the-data-directory), you will not have to specify a full path for it. See [Starting the Dialogue](#starting-the-dialogue)


