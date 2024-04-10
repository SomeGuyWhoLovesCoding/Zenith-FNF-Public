Hey there, welcome to this repository.

**We recommend you to use Haxe 4.2.5.**

# Libraries needed to compile this engine

Flixel: ``haxelib git flixel https://github.com/FNF-CNE-Devs/flixel.git`` (If you have an already installed git, delete it first)

Flixel Addons: ``haxelib install flixel-addons``

Flixel UI: ``haxelib install flixel-ui``

Lime: ``haxelib git lime https://github.com/Raltyro/lime`` **DOES NOT WORK ON NEKO BUILDS!** (If lime isn't set to git: ``haxelib set lime git``), or just ``haxelib install lime``

Openfl: ``haxelib install openfl``

Emitter: ``haxelib git emitter https://github.com/Dimensionscape/Emitter``

# Frequently asked questions

1. Q: How do I play FNF Zenith on linux?, A: To test this engine on there, you must have a computer of that operating system and THEN do ``lime test linux`` or ``haxelib run lime test linux``. *The same goes with mac!*
2. Q: Why does the compiler throw an error like ``..../flixel/5,6,2/flixel/input/actions/FlxActionManager.hx:54: characters 47-96 : Type not found : FlxTypedSignal`` or other weird errors!?, A: Well, it appears that latest haxe officially kills shadowing classes, or idk. The only way to fix that error is downgrade to 4.2.5.