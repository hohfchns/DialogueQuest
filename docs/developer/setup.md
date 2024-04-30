# Installation and Setup

The recommended way to install DialogueQuest is vida Godot's builtin Asset Library.

However if you want to get the latest features, you should install via the repository as such:

---

On Linux / Mac:

``` bash
cd my_godot_project
git clone https://github.com/hohfchns/DialogueQuest 
mkdir -p addons/
mv ./DialogueQuest/addons/DialogueQuest ./addons
rm -rf DialogueQuest
```

Or in one line: `git clone https://github.com/hohfchns/DialogueQuest && mkdir -p addons/ && mv ./DialogueQuest/addons/DialogueQuest ./addons && rm -rf DialogueQuest`

---

On Windows:

In your Godot project:

- Clone the repository
- Make directory called `addons`
- Move the folder `DialogueQuest\addons\DialogueQuest` inside `addons`
- Delete the cloned repository

---

Open your Godot project, go to `Project -> Project Settings -> Plugins` and enable `DialogueQuest`

## The Data Directory

Go to `Project -> Project Settings -> General` and search for `Dialogue Quest`, then set `Data Directory` to a folder where you will store DialogueQuest files (characters, dialogues, etc.)

This folder is by default set to `res://dialogue_quest/`

This folder is where you will be storing your [characters](#creating-characters) and [dialogues](#creating-dialogue)


