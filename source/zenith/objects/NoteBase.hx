package zenith.objects;

import openfl.display.Graphics;
import flixel.FlxBasic.IFlxBasic;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
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

// Based off FlxSprite, but without flipX, flipY, and animation.
class NoteBase extends FlxBasic
{
	public var x:Float = 0.0;
	public var y:Float = 0.0;
	public var width(default, set):Float = 0.0;
	function set_width(w:Float):Float
		return width = w;

	public var height(default, set):Float = 0.0;
	function set_height(h:Float):Float
		return height = h;

	public var angle:Float = 0.0;

	@:noCompletion
	var _point:FlxPoint = FlxPoint.get();
	@:noCompletion
	var _rect:FlxRect = FlxRect.get();

	/**
	 * Important variable for collision processing.
	 * By default this value is set automatically during at the start of `update()`.
	 */
	public var last(default, null):FlxPoint;

	/**
	 * Controls how much this object is affected by camera scrolling. `0` = no movement (e.g. a background layer),
	 * `1` = same movement speed as the foreground. Default value is `(1,1)`,
	 * except for UI elements like `FlxButton` where it's `(0,0)`.
	 */
	public var scrollFactor(default, null):FlxPoint;

	// Note properties

	public var strumTime:Float = 0.0;
	public var noteData:Int = 0;
	public var gfNote:Bool = false;

	public var lane:Int = 0;

	public var strum:StrumNote = null;

	public var multSpeed:Float = 1.0;
	public var distance:Float = 0.0;

	public var offsetX:Int = 0;
	public var offsetY:Int = 0;

	static public var colorArray:Array<Int> = [0xffc941d5, 0xff00ffff, 0xff0ffb3e, 0xfffa3e3e];
	static public var angleArray:Array<Float> = [0.0, -90.0, 90.0, 180.0];

	/**
	 * Controls whether the object is smoothed when rotated, affects performance.
	 */
	public var antialiasing:Bool = FlxSprite.defaultAntialiasing;

	/**
	 * Set this flag to true to force the sprite to update during the `draw()` call.
	 * NOTE: Rarely if ever necessary, most sprite operations will flip this flag automatically.
	 */
	public var dirty:Bool = true;

	/**
	 * This sprite's graphic / `BitmapData` object.
	 * Automatically adjusts graphic size and render helpers if changed.
	 */
	public var pixels(get, set):BitmapData;

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
	public var blend:BlendMode;

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
	public var clipRect:FlxRect;

	/**
	 * The actual frame used for sprite rendering
	 */
	@:noCompletion
	var _frame:FlxFrame;

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
	 * These vars are being used for rendering in some of `FlxSprite` subclasses (`FlxTileblock`, `FlxBar`,
	 * and `FlxBitmapText`) and for checks if the sprite is in camera's view.
	 */
	@:noCompletion
	var _sinAngle:Float = 0.0;

	@:noCompletion
	var _cosAngle:Float = 1.0;

	var onDraw:()->(Void);

	public function new():Void
	{
		onDraw = () ->
		{
			if (_frame == null || alpha == 0.0 || _frame.type == FlxFrameType.EMPTY)
				return;
	
			var cameras = inline getCamerasLegacy();
			for (camera in cameras)
			{
				if (!camera.visible || !camera.exists || !isOnScreen(camera))
					continue;
	
				_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, false, false);
				_matrix.translate(-origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);
	
				if (bakedRotationAngle <= 0)
				{
					var radians:Float = angle * FlxAngle.TO_RAD;
					_sinAngle = FlxMath.fastSin(radians);
					_cosAngle = FlxMath.fastCos(radians);
	
					if (angle != 0)
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
				}
	
				getScreenPosition(_point, camera).subtractPoint(offset);
				_point.add(origin.x, origin.y);
				_matrix.translate(_point.x, _point.y);
	
				camera.drawPixels(_frame, null, _matrix, colorTransform, blend, antialiasing, null);
	
				#if FLX_DEBUG
				if (FlxG.debugger.drawDebug)
					drawDebugOnCamera(camera);
				FlxBasic.visibleCount++;
				#end
			}
		}

		flixelType = OBJECT;
		last = FlxPoint.get(x, y);
		scrollFactor = FlxPoint.get(1.0, 1.0);

		_flashPoint = new Point();
		_flashRect = new Rectangle();
		_flashRect2 = new Rectangle();
		_flashPointZero = new Point();
		offset = FlxPoint.get(0.0, 0.0);
		origin = FlxPoint.get(0.0, 0.0);
		scale = FlxPoint.get(0.7, 0.7);
		_halfSize = FlxPoint.get();
		_matrix = new FlxMatrix();
		colorTransform = new ColorTransform();
		_scaledOrigin = new FlxPoint();

		super();
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
		last = FlxDestroyUtil.put(last);
		_point = FlxDestroyUtil.put(_point);
		_rect = FlxDestroyUtil.put(_rect);

		offset = FlxDestroyUtil.put(offset);
		origin = FlxDestroyUtil.put(origin);
		scale = FlxDestroyUtil.put(scale);
		_halfSize = FlxDestroyUtil.put(_halfSize);
		_scaledOrigin = FlxDestroyUtil.put(_scaledOrigin);

		_flashPoint = null;
		_flashRect = null;
		_flashRect2 = null;
		_flashPointZero = null;
		_matrix = null;
		colorTransform = null;
		blend = null;

		graphic = null;
		_frame = FlxDestroyUtil.destroy(_frame);
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
		_flashRect.x = _flashRect.y = 0;
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
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
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
		_flashRect2.x = _flashRect2.y = 0;

		if (graphic != null)
		{
			_flashRect2.width = graphic.width;
			_flashRect2.height = graphic.height;
		}

		centerOrigin();
	}

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
			redOffset = 0.0, greenOffset = 0.0, blueOffset = 0.0, alphaOffset = 0.0):Void
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

		useColorTransform = alpha != 1.0 || color != 0xffffff;
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
	public function isOnScreen(?camera:FlxCamera):Bool
	{
		if (camera == null)
			camera = FlxG.camera;
		
		return camera.containsRect(getScreenBounds(_rect, camera));
	}

	/**
	 * Returns the result of `isSimpleRenderBlit()` if `FlxG.renderBlit` is
	 * `true`, or `false` if `FlxG.renderTile` is `true`.
	 */
	public function isSimpleRender(?camera:FlxCamera):Bool
	{
		if (FlxG.renderTile)
			return false;

		return isSimpleRenderBlit(camera);
	}

	/**
	 * Determines the function used for rendering in blitting:
	 * `copyPixels()` for simple sprites, `draw()` for complex ones.
	 * Sprites are considered simple when they have an `angle` of `0`, a `scale` of `1`,
	 * don't use `blend` and `pixelPerfectRender` is `true`.
	 *
	 * @param   camera   If a camera is passed its `pixelPerfectRender` flag is taken into account
	 */
	public inline function isSimpleRenderBlit(?camera:FlxCamera):Bool
	{
		return (angle == 0.0 || bakedRotationAngle > 0) && scale.x == 1.0 && scale.y == 1.0 && blend == null;
	}

	/**
	 * Calculates the smallest globally aligned bounding box that encompasses this
	 * sprite's width and height, at its current rotation.
	 * Note, if called on a `FlxSprite`, the origin is used, but scale and offset are ignored.
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

		newRect.setSize(frameWidth * Math.abs(scale.x), frameHeight * Math.abs(scale.y));
		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
	}

	@:noCompletion
	function get_pixels():BitmapData
	{
		return (graphic == null) ? null : graphic.bitmap;
	}

	@:noCompletion
	function set_pixels(Pixels:BitmapData):BitmapData
	{
		var key:String = FlxG.bitmap.findKeyForBitmap(Pixels);

		if (key == null)
		{
			key = FlxG.bitmap.getUniqueKey();
			graphic = FlxG.bitmap.add(Pixels, false, key);
		}
		else
		{
			graphic = FlxG.bitmap.get(key);
		}
		return Pixels;
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

	#if FLX_DEBUG
	/**
	 * Override this function to draw custom "debug mode" graphics to the
	 * specified camera while the debugger's `drawDebug` mode is toggled on.
	 *
	 * @param   Camera   Which camera to draw the debug visuals to.
	 */
	public function drawDebugOnCamera(camera:FlxCamera):Void
	{
		var rect = getBoundingBox(camera);
		var gfx:Graphics = beginDrawDebug(camera);
		drawDebugBoundingBox(gfx, rect);
		endDrawDebug(camera);
	}

	function drawDebugBoundingBox(gfx:Graphics, rect:FlxRect)
	{
		// Find the color to use
		var color:Int = 0xFF779933;

		// fill static graphics object with square shape
		gfx.lineStyle(1, color, 0.75);
		gfx.drawRect(rect.x + 0.5, rect.y + 0.5, rect.width - 1.0, rect.height - 1.0);
	}

	inline function beginDrawDebug(camera:FlxCamera):Graphics
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
}