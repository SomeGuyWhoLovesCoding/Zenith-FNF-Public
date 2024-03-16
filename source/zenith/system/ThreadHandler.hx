package zenith.system;

import sys.thread.FixedThreadPool;
import sys.thread.Mutex;

class ThreadHandler
{
	private static var thread(default, null):FixedThreadPool = new FixedThreadPool(1);

	public static function run(task:Void->Void, onFinish:Void->Void = null):Void
	{
		// Threading is not supported with low memory mode, it just silent crashes the game when you try to load an image. Hopefully that issue gets fixed.
		if (Paths.LowMemoryMode)
		{
			task();
			return;
		}

		var mutex:Mutex = new Mutex();
		mutex.acquire();

		thread.run(function()
		{
			try
			{
				task();
			}
			catch (e)
			{
				Sys.println('Thread Handler: The task was skipped due to an error - $e');
			}

			if (onFinish != null)
				onFinish();
		});

		mutex.release();
	}
}