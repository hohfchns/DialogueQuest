extends Node
class_name DQSignals

signal dialogue_started(dialogue_path: String)
signal dialogue_ended(dialogue_path: String)

signal dialogue_signal(params: Array)

signal choice_made(choice: String)
