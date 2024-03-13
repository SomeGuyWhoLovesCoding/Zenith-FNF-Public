package zenith.system;

import sys.thread.ElasticThreadPool;

class ThreadHandler
{
	private static var thread(default, null):ElasticThreadPool = new ElasticThreadPool(2);

	public static function run(task:Void->Void, onFinish:Void->Void = null):Void
	{
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
	}
}