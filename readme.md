Hey there, welcome to this repository.

**We recommend you to use Haxe 4.2.5.**

# Libraries needed to compile this engine

Flixel: ``haxelib git flixel https://github.com/FNF-CNE-Devs/flixel.git`` (If you have an already installed git, delete it first)

Flixel Addons: ``haxelib install flixel-addons``

Flixel UI: ``haxelib install flixel-ui``

Lime: ``haxelib git lime https://github.com/lime`` (If lime isn't set to git, delete the previous one and do ``haxelib set lime git``) *Works if not on neko, but useful for hasklink* (or just ``haxelib install lime``)

Openfl: ``haxelib install openfl``

Emitter: ``haxelib git emitter https://github.com/Dimensionscape/Emitter``

To compile on hasklink, [read this.](https://haxe.org/manual/target-hl-getting-started.html)

# Frequently asked questions

1st Q: How do I play FNF Zenith on linux?

1st A: To test this engine on there, you must have a computer of that operating system and THEN do ``lime test linux`` or ``haxelib run lime test linux``. *The same goes with mac!*

2nd Q: Why does the compiler throw an error like ``..../flixel/5,6,2/flixel/input/actions/FlxActionManager.hx:54: characters 47-96 : Type not found : FlxTypedSignal`` or other weird errors!?

2nd A: Well, it appears that latest haxe officially kills shadowing classes, or idk. The only way to fix that error is downgrade to 4.2.5.