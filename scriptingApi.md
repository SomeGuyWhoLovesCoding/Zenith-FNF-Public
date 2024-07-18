Welcome to the FNF Zenith scripting API!

Here we will introduce you to something neat here.

# Requirements

HScript improved: ``haxelib git zenith-hscript https://github.com/FNF-CNE-Devs/hscript-improved``

# Guide

Here's the thing. This shit only supports HScript because it has actual object-oriented functionality and doesn't have methods for everything which made psych engine lua script code messy.

So, let's get started.

## How to add a script

Basically, make a "scripts" folder in assets. Then, make a text document that ends with ".hx".

You should see something like this: "assets/scripts/script.hx"

## Built-in functions

``onGameBoot()``; This function is called when the game boots. (Will have a ``modpack`` argument if modding support is fully finished)

Here's a fact! You can create your own custom save data by writing:

```haxe
function onGameBoot(modpack)
{
	if (!SaveData.contents.customSaves.exists("hi"))
	{
		var saveFile = new SaveFile("Hi!");
		saveFile.name = "hi"; // Change the name
		saveFile.data = 3; // Set the data to an int,
		SaveData.addToCustomSaves(saveFile);
	}
}
```

It allows your own custom savedata to load immediately.

### State-wise

``createPre()``: This function is called after the state class was created. Should only really be used for stuff that needs executed first before calling create.

``create()``: This function is called before creating the current state.

``createPost()``: This function is called after the current state was created.

``updatePre(elapsed)``: This function is called before the game executes the next frame.

*Only really useful for stuff you want to move first so you don't have to worry about it having the
frame delay*

``update(elapsed)``: This function is called before updating the current state.

``updatePost(elapsed)``: This function is called after the current state was updated.

``destroy()``: This function is called before destroying the current state. (Happens occasionally before switching to a state)

``destroyPost()``: This function is called after the state was destroyed. (After switching to a new state)

``onStepHit(curStep)``: This function is called when the conductor's ``onStepHit`` callback is called.

``onBeatHit(curBeat)``: This function is called when the conductor's ``onBeatHit`` callback is called.

``onMeasureHit(curMeasure)``: This function is called when the conductor's ``onMeasureHit`` callback is called.

``getVar(variable)``: This function gets a variable from the interpreter.

``setVar(variable, value)``: This function sets a variable from the interpreter to the new value.

### Gameplay-wise

``createStage(songName, songDifficulty)``: This function is called before the song's stage is created.

``createStagePost(songName, songDifficulty)``: This function is called after the song's characters are created. Useful for creating close objects on the stage.

``generateSong(songName, songDifficulty)``: This function is called after the song is loaded.

``startCountdown()``: This function is called when the countdown has started.

``startSong()``: This function is called when the countdown has ended.

``endSong()``: This function is called when the song has ended.

``moveCamera(whatCharacter)``: This function is called when the camera has moved to a specific character.

``onKeyDown(keyCode, keyModifier)``: This function is called before pressing down a key. (This is only available in-game)

``onKeyDownPost(keyCode, keyModifier)``: This function is called after pressing down a key. (This is only available in-game)

``onKeyUp(keyCode, keyModifier)``: This function is called before releasing a key. (This is only available in-game)

``onKeyUpPost(keyCode, keyModifier)``: This function is called after releasing a key. (This is only available in-game)

``newNote(note)``: This function is called after creating/reusing a note instance.

``newSustain(sustain)``: This function is called after creating/reusing a sustain note instance.

``onNoteHit(noteData)``: This function is called before hitting a note.

``onNoteHitPost(noteData)``: This function is called after hitting a note.

``onNoteMiss(noteDataData)``: This function is called before missing a note.

``onNoteMissPost(noteDataData)``: This function is called after missing a note.

``onHold(noteData)``: This function is called every frame before holding down a sustain note.

``onHoldPost(noteData)``: This function is called every frame after holding down a sustain note.

``onSustainMiss(noteData)``: This function is called before missing a sustain note.

``onSustainMissPost(noteData)``: This function is called after missing a sustain note.

``setupNoteData(note)``: This function is called after setting up the note data for recycling.

``setupSustainData(sustain)``: This function is called after setting up the sustain note data for recycling.

## Example usage

```haxe
function triggerEvent(eventName, value1, value2, value3, value4)
{
	switch(eventName)
	{
		case "Trace string":
			trace(value1,value2,value3,value4);
	}
}
```

## Tips

1. If you want to generate something after the song is generated, please use ``generateSong(songName, songDifficulty)``. This is a very good tip considering that mulithreading will basically call ``create()`` immediately.

2. If you want to create your own save data when the game boots, use the ``onGameBoot()`` function and do what I've shown at the top of "Built-in functions".

3.

# Final message

Hope you enjoyed this!
