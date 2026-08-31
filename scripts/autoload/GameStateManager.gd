extends Node
enum State { TITLE, PLAYING, PAUSED }
var state: State = State.PLAYING
func go_title() -> void: state = State.TITLE; SignalBus.show_dialogue.emit("System", "Title screen")
func pause_game() -> void: state = State.PAUSED; get_tree().paused = true
func resume_game() -> void: state = State.PLAYING; get_tree().paused = false
