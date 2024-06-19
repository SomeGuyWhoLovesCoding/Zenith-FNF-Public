package;

/**
 * ...
 * @author Chris__topher Speciale
 */
/**
 * A generic stack implementation.
 *
 * This class represents a simple stack data structure, which operates on the Last In, First Out (LIFO) principle.
 *
 * @param T The type of elements held in this stack.
 */
@:final
@:generic
class Stack<T>
{
	/**
	 * The current number of elements in the stack.
	 *
	 * @return The number of elements currently in the stack.
	 */
	public var length(get, never):Int;

	private var __items:Array<T>;
	private var __top:Int;

	private inline function get_length()
	{
		return __top;
	}

	/**
	 * Creates a new stack.
	 *
	 * @param length Optional. The initial size of the internal array used to store elements.
	 */
	public function new(?length:Int, ?objectFactory:T)
	{
		__items = new Array();
		if (length != null)
		{
			if (objectFactory == null)
				__items.resize(length);
			for (i in 0...length)
			{
				__items.push(objectFactory);
			}
		}

		__top = 0;
	}

	/**
	 * Pushes an element onto the top of the stack.
	 *
	 * @param item The element to push onto the stack.
	 */
	public inline function push(item:T):Void
	{
		if (__top >= __items.length)
		{
			__items.resize(__items.length > 0 ? __items.length * 2 : 1);
		}
		__items[__top++] = item;
	}

	/**
	 * Pops an element from the top of the stack.
	 *
	 * @return The element at the top of the stack, or `null` if the stack is empty.
	 */
	public inline function pop():Null<T>
	{
		return __top > 0 ? __items[--__top] : null;
	}

	/**
	 * Clears all elements from the stack.
	 *
	 * @param dispose Optional. If `true`, the internal array is resized to zero.
	 */
	public inline function clear(dispose:Bool = false):Void
	{
		__top = 0;
		if (dispose)
		{
			__items.resize(0);
		}
	}

	/**
	 * Retrieves the element at the top of the stack without removing it.
	 *
	 * @return The element at the top of the stack, or `null` if the stack is empty.
	 */
	public inline function last():Null<T>
	{
		return __top > 0 ? __items[__top - 1] : null;
	}

	public inline function iterator():Iterator<T>
	{
		return __items.iterator();
	}
}
