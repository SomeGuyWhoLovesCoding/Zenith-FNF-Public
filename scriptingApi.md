Welcome to the FNF Zenith scripting API!

Here we will introduce you to something neat here.

# Requirements

HScript improved: ``haxelib git zenith-hscript https://github.com/FNF-CNE-Devs/hscript-improved``

# Guide

Here's the thing. This shit only supports HScript because it has actual functionality.

So, let's get started.

## How to add a script

Basically, make a "scripts" folder in assets. Then, make a document that ends with ".hx".

You should see something like this: "assets/scripts/script.hx"

## Built-in functions

### State-wise

``create()``: This function is called before creating the current state.

``createPost()``: This function is called after the current state was created.

``update(elapsed)``: This function is called before updating the current state.

``updatePost(elapsed)``: This function is called after the current state was updated.

``destroy()``: This function is called before destroying the current state. (Happens occasionally before switching to a state)

``destroyPost()``: This function is called after the state was destroyed. (After switching to a new state)

``stepHit()``: This function is called when ``stepHit()`` is called.

``beatHit()``: This function is called when ``beatHit()`` is called.

``getVar(variable)``: This function gets a variable from the interpreter.

``setVar(variable, value)``: This function sets a variable from the interpreter to the new value.

### Gameplay-wise

``startCountdown()``: This function is called when the countdown has started.

``startSong()``: This function is called when the countdown has ended.

``endSong()``: This function is called when the song has ended.

``onKeyDown(keyCode, keyModifier)``: This function is called when pressing down a key.

``onKeyUp(keyCode, keyModifier)``: This function is called when releasing a key.

``onNoteHit(note)``: This function is called when hitting a note.

``onHold(sustain)``: This function is called every frame when holding down a sustain note.

``onNoteMiss(note)``: This function is called when missing a note.

## Example usage

```haxe
function triggerEvent(eventName, value1, value2)
{
	switch(eventName)
	{
		case "Trace string":
			trace(value1,value2);
	}
}
```

Hope you enjoyed this!