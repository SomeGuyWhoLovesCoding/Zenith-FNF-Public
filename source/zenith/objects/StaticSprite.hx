package zenith.objects;

import openfl.display.Graphics;

import flixel.FlxBasic.IFlxBasic;
import flixel.animation.FlxAnimationController;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxBitmapDataUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDirectionFlags;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using flixel.util.FlxColorTransformUtil;

// Just a FlxSprite copy without animation support.

class StaticSprite extends FlxBasic
{

	/**
	 * Set the angle (in degrees) of a sprite to rotate it. WARNING: rotating sprites
	 * decreases their rendering performance by a factor of ~10x when using blitting!
	 */
	public var angle(default, set):Float = 0;

	/**
	 * X position of the upper left corner of this object in world space.
	 */
	public var x(default, set):Float = 0;

	/**
	 * Y position of the upper left corner of this object in world space.
	 */
	public var y(default, set):Float = 0;

	/**
	 * The width of this object's hitbox. For sprites, use `offset` to control the hitbox position.
	 */
	@:isVar
	public var width(get, set):Float;

	/**
	 * The height of this object's hitbox. For sprites, use `offset` to control the hitbox position.
	 */
	@:isVar
	public var height(get, set):Float;

	@:noCompletion
	function set_x(value:Float):Float
	{
		return x = value;
	}

	@:noCompletion
	function set_y(value:Float):Float
	{
		return y = value;
	}

	@:noCompletion
	function set_width(value:Float):Float
	{
		#if FLX_DEBUG
		if (!(exists = value > 0))
		{
			FlxG.log.warn("An object's width cannot be smaller than 0. Use offset for sprites to control the hitbox position!");
			return value;
		}
		#end

		return width = value;
	}

	@:noCompletion
	function set_height(value:Float):Float
	{
		#if FLX_DEBUG
		if (!(exists = value > 0))
		{
			FlxG.log.warn("An object's height cannot be smaller than 0. Use offset for sprites to control the hitbox position!");
			return value;
		}
		#end

		return height = value;
	}

	@:noCompletion
	function get_width():Float
	{
		return width;
	}

	@:noCompletion
	function get_height():Float
	{
		return height;
	}

	@:noCompletion
	function set_angle(a:Float):Float
	{
		return angle = a;
	}

	/**
	 * Controls how much this object is affected by camera scrolling. `0` = no movement (e.g. a background layer),
	 * `1` = same movement speed as the foreground. Default value is `(1,1)`,
	 * except for UI elements like `FlxButton` where it's `(0,0)`.
	 */
	public var scrollFactor(default, null):FlxPoint;

	@:noCompletion
	var _point:FlxPoint = FlxPoint.get();
	@:noCompletion
	var _rect:FlxRect = FlxRect.get();

	/**
	 * Returns the screen position of this object.
	 *
	 * @param   result  Optional arg for the returning point
	 * @param   camera  The desired "screen" coordinate space. If `null`, `FlxG.camera` is used.
	 * @return  The screen position of this object.
	 */
	public function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
	{
		if (result == null)
			result = FlxPoint.get();

		if (camera == null)
			camera = FlxG.camera;

		result.set(x, y);

		return result.subtract(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
	}

	#if FLX_DEBUG
	public function drawDebug():Void
	{
		for (camera in cameras)
			drawDebugOnCamera(camera);
	}

	/**
	 * Override this function to draw custom "debug mode" graphics to the
	 * specified camera while the debugger's `drawDebug` mode is toggled on.
	 *
	 * @param   Camera   Which camera to draw the debug visuals to.
	 */
	public function drawDebugOnCamera(camera:FlxCamera):Void
	{
		if (!camera.visible || !camera.exists || !isOnScreen(camera))
			return;

		var rect = getBoundingBox(camera);
		var gfx:Graphics = beginDrawDebug(camera);
		drawDebugBoundingBox(gfx, rect);
		endDrawDebug(camera);
	}

	inline function drawDebugBoundingBox(gfx:Graphics, rect:FlxRect)
	{
		// fill static graphics object with square shape
		gfx.lineStyle(1, 0xFF776622, 0.75);
		gfx.drawRect(rect.x + 0.5, rect.y + 0.5, rect.width - 1.0, rect.height - 1.0);
	}

	function beginDrawDebug(camera:FlxCamera):Graphics
	{
		if (FlxG.renderBlit)
		{
			FlxSpriteUtil.flashGfx.clear();
			return FlxSpriteUtil.flashGfx;
		}
		else
		{
			return camera.debugLayer.graphics;
		}
	}

	inline function endDrawDebug(camera:FlxCamera)
	{
		if (FlxG.renderBlit)
			camera.buffer.draw(FlxSpriteUtil.flashGfxSprite);
	}
	#end

	@:access(flixel.FlxCamera)
	function getBoundingBox(camera:FlxCamera):FlxRect
	{
		getScreenPosition(_point, camera);

		_rect.set(_point.x, _point.y, width, height);
		_rect = camera.transformRect(_rect);

		return _rect;
	}

	inline public function setFrame(frame:FlxFrame):Void
	{
		_flashRect.x = _flashRect.y = 0;

		_frame = frame.copyTo(null);
		_flashRect.width = frameWidth = Std.int(_frame.sourceSize.x);
		_flashRect.height = frameHeight = Std.int(_frame.sourceSize.y);

		origin.x = _halfSize.x = 0.5 * frameWidth;
		origin.y = _halfSize.y = 0.5 * frameHeight;

		width = (scale.x < 0.0 ? -scale.x : scale.x) * frameWidth;
		height = (scale.y < 0.0 ? -scale.y : scale.y) * frameHeight;
		offset.x = -0.5 * (width - frameWidth);
		offset.y = -0.5 * (height - frameHeight);
	}

	// TODO: maybe convert this var to property...

	/**
	 * The current display state of the sprite including current animation frame,
	 * tint, flip etc... may be `null` unless `useFramePixels` is `true`.
	 */
	public var framePixels:BitmapData;

	/**
	 * Always `true` on `FlxG.renderBlit`. On `FlxG.renderTile` it determines whether
	 * `framePixels` is used and defaults to `false` for performance reasons.
	 */
	public var useFramePixels(default, set):Bool = true;

	/**
	 * Controls whether the object is smoothed when rotated, affects performance.
	 */
	public var antialiasing(default, set):Bool = FlxSprite.defaultAntialiasing;

	/**
	 * Set this flag to true to force the sprite to update during the `draw()` call.
	 * NOTE: Rarely if ever necessary, most sprite operations will flip this flag automatically.
	 */
	public var dirty:Bool = true;

	/**
	 * The width of the actual graphic or image being displayed (not necessarily the game object/bounding box).
	 */
	public var frameWidth(default, null):Int = 0;

	/**
	 * The height of the actual graphic or image being displayed (not necessarily the game object/bounding box).
	 */
	public var frameHeight(default, null):Int = 0;

	public var graphic(default, set):FlxGraphic;

	/**
	 * The minimum angle (out of 360°) for which a new baked rotation exists. Example: `90` means there
	 * are 4 baked rotations in the spritesheet. `0` if this sprite does not have any baked rotations.
	 * @see https://snippets.haxeflixel.com/sprites/baked-rotations/
	 */
	public var bakedRotationAngle(default, null):Float = 0;

	/**
	 * Set alpha to a number between `0` and `1` to change the opacity of the sprite.
	 @see https://snippets.haxeflixel.com/sprites/alpha/
	 */
	public var alpha(default, set):Float = 1.0;

	/**
	 * Can be set to `LEFT`, `RIGHT`, `UP`, and `DOWN` to take advantage
	 * of flipped sprites and/or just track player orientation more easily.
	 * @see https://snippets.haxeflixel.com/sprites/facing/
	 */
	public var facing(default, set):FlxDirectionFlags = RIGHT;

	/**
	 * Whether this sprite is flipped on the X axis.
	 */
	public var flipX(default, set):Bool = false;

	/**
	 * Whether this sprite is flipped on the Y axis.
	 */
	public var flipY(default, set):Bool = false;

	/**
	 * WARNING: The `origin` of the sprite will default to its center. If you change this,
	 * the visuals and the collisions will likely be pretty out-of-sync if you do any rotation.
	 */
	public var origin(default, null):FlxPoint;

	/**
	 * The position of the sprite's graphic relative to its hitbox. For example, `offset.x = 10;` will
	 * show the graphic 10 pixels left of the hitbox. Likely needs to be adjusted after changing a sprite's
	 * `width`, `height` or `scale`.
	 */
	public var offset(default, null):FlxPoint;

	/**
	 * Change the size of your sprite's graphic.
	 * NOTE: The hitbox is not automatically adjusted, use `updateHitbox()` for that.
	 * WARNING: With `FlxG.renderBlit`, scaling sprites decreases rendering performance by a factor of about x10!
	 * @see https://snippets.haxeflixel.com/sprites/scale/
	 */
	public var scale(default, null):FlxPoint;

	/**
	 * Blending modes, just like Photoshop or whatever, e.g. "multiply", "screen", etc.
	 */
	public var blend(default, set):BlendMode;

	/**
	 * Tints the whole sprite to a color (`0xRRGGBB` format) - similar to OpenGL vertex colors. You can use
	 * `0xAARRGGBB` colors, but the alpha value will simply be ignored. To change the opacity use `alpha`.
	 * @see https://snippets.haxeflixel.com/sprites/color/
	 */
	public var color(default, set):FlxColor = 0xffffff;

	public var colorTransform(default, null):ColorTransform;

	/**
	 * Whether or not to use a `ColorTransform` set via `setColorTransform()`.
	 */
	public var useColorTransform(default, null):Bool = false;

	/**
	 * Clipping rectangle for this sprite.
	 * Changing the rect's properties directly doesn't have any effect,
	 * reassign the property to update it (`sprite.clipRect = sprite.clipRect;`).
	 * Set to `null` to discard graphic frame clipping.
	 */
	public var clipRect(default, set):FlxRect;

	function set_clipRect(rect:FlxRect):FlxRect
	{
		if (clipRect != null)
		{
			clipRect.put();
		}
		_frame = _frame.clipTo(rect, _frame);

		return clipRect = rect;
	}

	/**
	 * GLSL shader for this sprite. Avoid changing it frequently as this is a costly operation.
	 * @since 4.1.0
	 */
	public var shader:FlxShader;

	/**
	 * The actual frame used for sprite rendering
	 */
	@:noCompletion
	var _frame:FlxFrame;

	/**
	 * Graphic of `_frame`. Used in tile render mode, when `useFramePixels` is `true`.
	 */
	@:noCompletion
	var _frameGraphic:FlxGraphic;

	@:noCompletion
	var _facingHorizontalMult:Int = 1;
	@:noCompletion
	var _facingVerticalMult:Int = 1;

	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	@:noCompletion
	var _flashPoint:Point;

	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	@:noCompletion
	var _flashRect:Rectangle;

	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	@:noCompletion
	var _flashRect2:Rectangle;

	/**
	 * Internal, reused frequently during drawing and animating. Always contains `(0,0)`.
	 */
	@:noCompletion
	var _flashPointZero:Point;

	/**
	 * Internal, helps with animation, caching and drawing.
	 */
	@:noCompletion
	var _matrix:FlxMatrix;

	/**
	 * Rendering helper variable
	 */
	@:noCompletion
	var _halfSize:FlxPoint;
	
	/**
	 *  Helper variable
	 */
	@:noCompletion
	var _scaledOrigin:FlxPoint;

	/**
	 * These vars are being used for rendering in some of `StaticSprite` subclasses (`FlxTileblock`, `FlxBar`,
	 * and `FlxBitmapText`) and for checks if the sprite is in camera's view.
	 */
	@:noCompletion
	var _sinAngle:Float = 0.0;

	@:noCompletion
	var _cosAngle:Float = 1.0;

	/**
	 * Maps `FlxDirectionFlags` values to axis flips
	 */
	@:noCompletion
	var _facingFlip:Map<FlxDirectionFlags, {x:Bool, y:Bool}> = new Map<FlxDirectionFlags, {x:Bool, y:Bool}>();

	var onDraw:()->(Void);

	/**
	 * Creates a `StaticSprite` at a specified position with a specified one-frame graphic.
	 * If none is provided, a 16x16 image of the HaxeFlixel logo is used.
	 *
	 * @param   X               The initial X position of the sprite.
	 * @param   Y               The initial Y position of the sprite.
	 * @param   SimpleGraphic   The graphic you want to display
	 *                          (OPTIONAL - for simple stuff only, do NOT use for animated images!).
	 */
	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		x = X;
		y = Y;

		onDraw = () ->
		{
			checkEmptyFrame();

			if (alpha == 0.0 || _frame.type == FlxFrameType.EMPTY)
				return;

			for (camera in cameras)
			{
				if (!camera.visible || !camera.exists || !isOnScreen(camera))
					continue;

				_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
				_matrix.translate(-origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);

				if (bakedRotationAngle <= 0)
				{
					var radians:Float = angle * FlxAngle.TO_RAD;
					_sinAngle = FlxMath.fastSin(radians);
					_cosAngle = FlxMath.fastCos(radians);

					if (angle != 0.0)
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
				}

				getScreenPosition(_point, camera).subtractPoint(offset);
				_point.add(origin.x, origin.y);
				_matrix.translate(_point.x, _point.y);

				camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);

				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}

			#if FLX_DEBUG
			if (FlxG.debugger.drawDebug)
				drawDebug();
			#end
		}

		super();

		flixelType = OBJECT;
		scrollFactor = FlxPoint.get(1.0, 1.0);

		_flashPoint = new Point();
		_flashRect = new Rectangle();
		_flashRect2 = new Rectangle();
		_flashPointZero = new Point();
		offset = FlxPoint.get(0.0, 0.0);
		origin = FlxPoint.get(0.0, 0.0);
		scale = FlxPoint.get(1.0, 1.0);
		_halfSize = FlxPoint.get();
		_matrix = new FlxMatrix();
		colorTransform = new ColorTransform();
		_scaledOrigin = new FlxPoint();

		useFramePixels = FlxG.renderBlit;
		if (SimpleGraphic != null)
			loadGraphic(SimpleGraphic);
	}

	/**
	 * **WARNING:** A destroyed `FlxBasic` can't be used anymore.
	 * It may even cause crashes if it is still part of a group or state.
	 * You may want to use `kill()` instead if you want to disable the object temporarily only and `revive()` it later.
	 *
	 * This function is usually not called manually (Flixel calls it automatically during state switches for all `add()`ed objects).
	 *
	 * Override this function to `null` out variables manually or call `destroy()` on class members if necessary.
	 * Don't forget to call `super.destroy()`!
	 */
	override public function destroy():Void
	{
		super.destroy();

		scrollFactor = FlxDestroyUtil.put(scrollFactor);
		_point = FlxDestroyUtil.put(_point);
		_rect = FlxDestroyUtil.put(_rect);

		offset = FlxDestroyUtil.put(offset);
		origin = FlxDestroyUtil.put(origin);
		scale = FlxDestroyUtil.put(scale);
		_halfSize = FlxDestroyUtil.put(_halfSize);
		_scaledOrigin = FlxDestroyUtil.put(_scaledOrigin);

		framePixels = FlxDestroyUtil.dispose(framePixels);

		_flashPoint = null;
		_flashRect = null;
		_flashRect2 = null;
		_flashPointZero = null;
		_matrix = null;
		colorTransform = null;
		blend = null;

		graphic = null;
		_frame = FlxDestroyUtil.destroy(_frame);
		_frameGraphic = FlxDestroyUtil.destroy(_frameGraphic);

		shader = null;
	}

	public function clone():StaticSprite
	{
		return (new StaticSprite()).loadGraphicFromSprite(this);
	}

	/**
	 * Load graphic from another `StaticSprite` and copy its tile sheet data.
	 * This method can useful for non-flash targets.
	 *
	 * @param   Sprite   The `StaticSprite` from which you want to load graphic data.
	 * @return  This `StaticSprite` instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadGraphicFromSprite(Sprite:StaticSprite):StaticSprite
	{
		bakedRotationAngle = Sprite.bakedRotationAngle;
		if (bakedRotationAngle > 0)
		{
			width = Sprite.width;
			height = Sprite.height;
			centerOffsets();
		}
		antialiasing = Sprite.antialiasing;
		graphicLoaded();
		clipRect = Sprite.clipRect;
		return this;
	}

	/**
	 * Load an image from an embedded graphic file.
	 *
	 * HaxeFlixel's graphic caching system keeps track of loaded image data.
	 * When you load an identical copy of a previously used image, by default
	 * HaxeFlixel copies the previous reference onto the `pixels` field instead
	 * of creating another copy of the image data, to save memory.
	 *
	 * NOTE: This method updates hitbox size and frame size.
	 *
	 * @param   graphic      The image you want to use.
	 * @param   animated     Whether the `Graphic` parameter is a single sprite or a row / grid of sprites.
	 * @param   frameWidth   Specify the width of your sprite
	 *                       (helps figure out what to do with non-square sprites or sprite sheets).
	 * @param   frameHeight  Specify the height of your sprite
	 *                       (helps figure out what to do with non-square sprites or sprite sheets).
	 * @param   unique       Whether the graphic should be a unique instance in the graphics cache.
	 *                       Set this to `true` if you want to modify the `pixels` field without changing
	 *                       the `pixels` of other sprites with the same `BitmapData`.
	 * @param   key          Set this parameter if you're loading `BitmapData`.
	 * @return  This `StaticSprite` instance (nice for chaining stuff together, if you're into that).
	 */
	var graphicCache:Map<FlxGraphicAsset, FlxGraphic> = new Map<FlxGraphicAsset, FlxGraphic>();
	public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):StaticSprite
	{
		var graph:FlxGraphic = FlxG.bitmap.add(graphic, unique, key);

		if (graph == null)
			return this;

		if (frameWidth == 0)
		{
			frameWidth = animated ? graph.height : graph.width;
			frameWidth = (frameWidth > graph.width) ? graph.width : frameWidth;
		}
		else if (frameWidth > graph.width)
			FlxG.log.warn('frameWidth:$frameWidth is larger than the graphic\'s width:${graph.width}');

		if (frameHeight == 0)
		{
			frameHeight = animated ? frameWidth : graph.height;
			frameHeight = (frameHeight > graph.height) ? graph.height : frameHeight;
		}
		else if (frameHeight > graph.height)
			FlxG.log.warn('frameHeight:$frameHeight is larger than the graphic\'s height:${graph.height}');

		_frame = graph.imageFrame.frame;

		return this;
	}

	/**
	 * This function creates a flat colored rectangular image dynamically.
	 *
	 * HaxeFlixel's graphic caching system keeps track of loaded image data.
	 * When you make an identical copy of a previously used image, by default
	 * HaxeFlixel copies the previous reference onto the pixels field instead
	 * of creating another copy of the image data, to save memory.
	 *
	 * NOTE: This method updates hitbox size and frame size.
	 *
	 * @param   Width    The width of the sprite you want to generate.
	 * @param   Height   The height of the sprite you want to generate.
	 * @param   Color    Specifies the color of the generated block (ARGB format).
	 * @param   Unique   Whether the graphic should be a unique instance in the graphics cache. Default is `false`.
	 *                   Set this to `true` if you want to modify the `pixels` field without changing the
	 *                   `pixels` of other sprites with the same `BitmapData`.
	 * @param   Key      An optional `String` key to identify this graphic in the cache.
	 *                   If `null`, the key is determined by `Width`, `Height` and `Color`.
	 *                   If `Unique` is `true` and a graphic with this `Key` already exists,
	 *                   it is used as a prefix to find a new unique name like `"Key3"`.
	 * @return  This `StaticSprite` instance (nice for chaining stuff together, if you're into that).
	 */
	public function makeGraphic(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):StaticSprite
	{
		var graph:FlxGraphic = FlxG.bitmap.create(Width, Height, Color, Unique, Key);
		_frame = graph.imageFrame.frame;
		return this;
	}

	/**
	 * Called whenever a new graphic is loaded for this sprite (after `loadGraphic()`, `makeGraphic()` etc).
	 */
	public function graphicLoaded():Void {}

	/**
	 * Resets some internal variables used for frame `BitmapData` calculation.
	 */
	public inline function resetSize():Void
	{
		_flashRect.x = 0;
		_flashRect.y = 0;
		_flashRect.width = frameWidth;
		_flashRect.height = frameHeight;
	}

	/**
	 * Resets frame size to frame dimensions.
	 */
	public inline function resetFrameSize():Void
	{
		if (_frame != null)
		{
			frameWidth = Std.int(_frame.sourceSize.x);
			frameHeight = Std.int(_frame.sourceSize.y);
		}
		_halfSize.set(0.5 * frameWidth, 0.5 * frameHeight);
		resetSize();
	}

	/**
	 * Resets sprite's size back to frame size.
	 */
	public inline function resetSizeFromFrame():Void
	{
		width = frameWidth;
		height = frameHeight;
	}

	/**
	 * Helper function to set the graphic's dimensions by using `scale`, allowing you to keep the current aspect ratio
	 * should one of the numbers be `<= 0`. It might make sense to call `updateHitbox()` afterwards!
	 *
	 * @param   width    How wide the graphic should be. If `<= 0`, and `height` is set, the aspect ratio will be kept.
	 * @param   height   How high the graphic should be. If `<= 0`, and `width` is set, the aspect ratio will be kept.
	 */
	public function setGraphicSize(width = 0.0, height = 0.0):Void
	{
		if (width <= 0 && height <= 0)
			return;

		var newScaleX:Float = width / frameWidth;
		var newScaleY:Float = height / frameHeight;
		scale.set(newScaleX, newScaleY);

		if (width <= 0)
			scale.x = newScaleY;
		else if (height <= 0)
			scale.y = newScaleX;
	}

	/**
	 * Updates the sprite's hitbox (`width`, `height`, `offset`) according to the current `scale`.
	 * Also calls `centerOrigin()`.
	 */
	public function updateHitbox():Void
	{
		width = (scale.x < 0.0 ? -scale.x : scale.x) * frameWidth;
		height = (scale.y < 0.0 ? -scale.y : scale.y) * frameHeight;
		offset.set(-0.5 * (width - frameWidth), -0.5 * (height - frameHeight));
		centerOrigin();
	}

	/**
	 * Resets some important variables for sprite optimization and rendering.
	 */
	@:noCompletion
	function resetHelpers():Void
	{
		resetFrameSize();
		resetSizeFromFrame();
		_flashRect2.x = 0;
		_flashRect2.y = 0;

		if (graphic != null)
		{
			_flashRect2.width = graphic.width;
			_flashRect2.height = graphic.height;
		}

		centerOrigin();

		if (FlxG.renderBlit)
			dirty = true;
	}

	@:noCompletion
	function checkEmptyFrame()
	{
		if (_frame == null)
			loadGraphic("flixel/images/logo/default.png");
		else if (graphic != null)
		{
			// switch graphic but log and preserve size
			final width = this.width;
			final height = this.height;
			FlxG.log.error('Cannot render a destroyed graphic, the placeholder image will be used instead');
			loadGraphic("flixel/images/logo/default.png");
			this.width = width;
			this.height = height;
		}
	}

	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen.
	 */
	override public function draw():Void
	{
		onDraw();
	}

	/**
	 * Helper function that adjusts the offset automatically to center the bounding box within the graphic.
	 *
	 * @param   AdjustPosition   Adjusts the actual X and Y position just once to match the offset change.
	 */
	public function centerOffsets(AdjustPosition:Bool = false):Void
	{
		offset.x = (frameWidth - width) * 0.5;
		offset.y = (frameHeight - height) * 0.5;
		if (AdjustPosition)
		{
			x += offset.x;
			y += offset.y;
		}
	}

	/**
	 * Sets the sprite's origin to its center - useful after adjusting
	 * `scale` to make sure rotations work as expected.
	 */
	public inline function centerOrigin():Void
	{
		origin.set(frameWidth * 0.5, frameHeight * 0.5);
	}

	/**
	 * Replaces all pixels with specified `Color` with `NewColor` pixels.
	 * WARNING: very expensive (especially on big graphics) as it iterates over every single pixel.
	 *
	 * @param   Color            Color to replace
	 * @param   NewColor         New color
	 * @param   FetchPositions   Whether we need to store positions of pixels which colors were replaced.
	 * @return  `Array` with replaced pixels positions
	 */
	public function replaceColor(Color:FlxColor, NewColor:FlxColor, FetchPositions:Bool = false):Array<FlxPoint>
	{
		var positions = FlxBitmapDataUtil.replaceColor(graphic.bitmap, Color, NewColor, FetchPositions);
		if (positions != null)
			dirty = true;
		return positions;
	}

	/**
	 * Sets the sprite's color transformation with control over color offsets.
	 * With `FlxG.renderTile`, offsets are only supported on OpenFL Next version 3.6.0 or higher.
	 *
	 * @param   redMultiplier     The value for the red multiplier, in the range from `0` to `1`.
	 * @param   greenMultiplier   The value for the green multiplier, in the range from `0` to `1`.
	 * @param   blueMultiplier    The value for the blue multiplier, in the range from `0` to `1`.
	 * @param   alphaMultiplier   The value for the alpha transparency multiplier, in the range from `0` to `1`.
	 * @param   redOffset         The offset value for the red color channel, in the range from `-255` to `255`.
	 * @param   greenOffset       The offset value for the green color channel, in the range from `-255` to `255`.
	 * @param   blueOffset        The offset for the blue color channel value, in the range from `-255` to `255`.
	 * @param   alphaOffset       The offset for alpha transparency channel value, in the range from `-255` to `255`.
	 */
	public function setColorTransform(redMultiplier = 1.0, greenMultiplier = 1.0, blueMultiplier = 1.0, alphaMultiplier = 1.0,
			redOffset = 0, greenOffset = 0, blueOffset = 0, alphaOffset = 0):Void
	{
		color = FlxColor.fromRGBFloat(redMultiplier, greenMultiplier, blueMultiplier).to24Bit();
		alpha = alphaMultiplier;

		colorTransform.setMultipliers(redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);
		colorTransform.setOffsets(redOffset, greenOffset, blueOffset, alphaOffset);

		useColorTransform = alpha != 1 || color != 0xffffff || colorTransform.hasRGBOffsets();
		dirty = true;
	}
	
	function updateColorTransform():Void
	{
		if (colorTransform == null)
			return;

		useColorTransform = alpha != 1 || color != 0xffffff;
		if (useColorTransform)
			colorTransform.setMultipliers(color.redFloat, color.greenFloat, color.blueFloat, alpha);
		else
			colorTransform.setMultipliers(1, 1, 1, 1);

		dirty = true;
	}

	/**
	 * Retrieve the midpoint of this sprite's graphic in world coordinates.
	 *
	 * @param   point   Allows you to pass in an existing `FlxPoint` if you're so inclined.
	 *                  Otherwise a new one is created.
	 * @return  A `FlxPoint` containing the midpoint of this sprite's graphic in world coordinates.
	 */
	public function getGraphicMidpoint(?point:FlxPoint):FlxPoint
	{
		if (point == null)
			point = FlxPoint.get();
		return point.set(x + frameWidth * 0.5 * scale.x, y + frameHeight * 0.5 * scale.y);
	}

	/**
	 * Check and see if this object is currently on screen. Differs from `FlxObject`'s implementation
	 * in that it takes the actual graphic into account, not just the hitbox or bounding box or whatever.
	 *
	 * @param   Camera  Specify which game camera you want. If `null`, `FlxG.camera` is used.
	 * @return  Whether the object is on screen or not.
	 */
	inline public function isOnScreen(?camera:FlxCamera):Bool
	{
		if (camera == null)
			camera = FlxG.camera;
		
		return camera.containsRect(getScreenBounds(_rect, camera));
	}

	/**
	 * Calculates the smallest globally aligned bounding box that encompasses this
	 * sprite's width and height, at its current rotation.
	 * Note, if called on a `StaticSprite`, the origin is used, but scale and offset are ignored.
	 * Use `getScreenBounds` to use these properties.
	 * @param newRect The optional output `FlxRect` to be returned, if `null`, a new one is created.
	 * @return A globally aligned `FlxRect` that fully contains the input object's width and height.
	 * @since 4.11.0
	 */
	function getRotatedBounds(?newRect:FlxRect)
	{
		if (newRect == null)
			newRect = FlxRect.get();
		
		newRect.set(x, y, width, height);
		return newRect.getRotatedBounds(angle, origin, newRect);
	}
	
	/**
	 * Calculates the smallest globally aligned bounding box that encompasses this sprite's graphic as it
	 * would be displayed. Honors scrollFactor, rotation, scale, offset and origin.
	 * @param newRect Optional output `FlxRect`, if `null`, a new one is created.
	 * @param camera  Optional camera used for scrollFactor, if null `FlxG.camera` is used.
	 * @return A globally aligned `FlxRect` that fully contains the input sprite.
	 * @since 4.11.0
	 */
	public function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		if (newRect == null)
			newRect = FlxRect.get();
		
		if (camera == null)
			camera = FlxG.camera;
		
		newRect.setPosition(x, y);

		_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);
		newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x;
		newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y;

		newRect.setSize(frameWidth * (scale.x < 0.0 ? -scale.x : scale.x), frameHeight * (scale.y < 0.0 ? -scale.y : scale.y));
		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
	}
	
	/**
	 * Set how a sprite flips when facing in a particular direction.
	 *
	 * @param   Direction   Use constants `LEFT`, `RIGHT`, `UP`, and `DOWN`.
	 *                      These may be combined with the bitwise OR operator.
	 *                      E.g. To make a sprite flip horizontally when it is facing both `UP` and `LEFT`,
	 *                      use `setFacingFlip(LEFT | UP, true, false);`
	 * @param   FlipX       Whether to flip the sprite on the X axis.
	 * @param   FlipY       Whether to flip the sprite on the Y axis.
	 */
	public inline function setFacingFlip(Direction:FlxDirectionFlags, FlipX:Bool, FlipY:Bool):Void
	{
		_facingFlip.set(Direction, {x: FlipX, y: FlipY});
	}

	@:noCompletion
	function set_facing(Direction:FlxDirectionFlags):FlxDirectionFlags
	{
		var flip = _facingFlip.get(Direction);
		if (flip != null)
		{
			flipX = flip.x;
			flipY = flip.y;
		}

		return facing = Direction;
	}

	@:noCompletion
	function set_alpha(Alpha:Float):Float
	{
		if (alpha == Alpha)
		{
			return Alpha;
		}
		alpha = FlxMath.bound(Alpha, 0, 1);
		updateColorTransform();
		return alpha;
	}

	@:noCompletion
	function set_color(Color:FlxColor):Int
	{
		if (color == Color)
		{
			return Color;
		}
		color = Color;
		updateColorTransform();
		return color;
	}

	@:noCompletion
	function set_blend(Value:BlendMode):BlendMode
	{
		return blend = Value;
	}

	/**
	 * Internal function for setting graphic property for this object.
	 * Changes the graphic's `useCount` for better memory tracking.
	 */
	@:noCompletion
	function set_graphic(value:FlxGraphic):FlxGraphic
	{
		if (graphic != value)
		{
			// If new graphic is not null, increase its use count
			if (value != null)
				value.incrementUseCount();
			
			// If old graphic is not null, decrease its use count
			if (graphic != null)
				graphic.decrementUseCount();
			
			graphic = value;
		}
		
		return value;
	}

	@:noCompletion
	function set_flipX(Value:Bool):Bool
	{
		if (FlxG.renderTile)
		{
			_facingHorizontalMult = Value ? -1 : 1;
		}
		dirty = (flipX != Value) || dirty;
		return flipX = Value;
	}

	@:noCompletion
	function set_flipY(Value:Bool):Bool
	{
		if (FlxG.renderTile)
		{
			_facingVerticalMult = Value ? -1 : 1;
		}
		dirty = (flipY != Value) || dirty;
		return flipY = Value;
	}

	@:noCompletion
	function set_antialiasing(value:Bool):Bool
	{
		return antialiasing = value;
	}

	@:noCompletion
	function set_useFramePixels(value:Bool):Bool
	{
		if (FlxG.renderTile)
		{
			if (value != useFramePixels)
				useFramePixels = value;

			return value;
		}
		else
		{
			useFramePixels = true;
			return true;
		}
	}

	@:noCompletion
	inline function checkFlipX():Bool
	{
		return flipX != _frame.flipX;
	}

	@:noCompletion
	inline function checkFlipY():Bool
	{
		return flipY != _frame.flipY;
	}
}