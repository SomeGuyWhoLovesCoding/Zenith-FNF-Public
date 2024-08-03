/* This is an example script for you to try out! */

function hitNote(noteData)
{
    FlxG.camera.shake(0.006, 0.1, null, true);
    Gameplay.instance.score -= 50;
}