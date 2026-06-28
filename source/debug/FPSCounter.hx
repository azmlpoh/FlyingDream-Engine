package debug;

import flixel.FlxG;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.util.FlxStringUtil;
import openfl.system.System as OpenFlSystem;

class FPSCounter extends Sprite
{
	public var currentFPS(default, null):Int = 0;
	public var totalMemory:Float = 0;

	var textField:TextField;
	var times:Array<Float> = [];
	var lastTime:Float = 0;

	public function new(x:Float = 10, y:Float = 10)
	{
		super();

		var format = new TextFormat(Paths.font("vcr.ttf"), 14, 0xFFFFFFFF);

		textField = new TextField();
		textField.selectable = false;
		textField.mouseEnabled = false;
		textField.defaultTextFormat = format;
		textField.autoSize = LEFT;
		textField.multiline = true;
		textField.text = "FPS: 0\nMemory: 0MB ( 0MB peak )\nFlying Dream Engine - DEV(0.1.8)";

		addChild(textField);

		this.x = x;
		this.y = y;

		addEventListener(openfl.events.Event.ENTER_FRAME, onEnterFrame);
	}

	function onEnterFrame(e:openfl.events.Event):Void
	{
		var now = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();

		if (lastTime == 0) {
			lastTime = now;
			return;
		}

		var delta = now - lastTime;
		lastTime = now;

		currentFPS = times.length;
		updateText();
	}

	function updateText():Void
	{
		var usedMemory:Float = OpenFlSystem.totalMemory;
		if (usedMemory > totalMemory) totalMemory = usedMemory;

		textField.text = 'FPS: $currentFPS\nMemory: ${FlxStringUtil.formatBytes(usedMemory)} ( ${FlxStringUtil.formatBytes(totalMemory)} paek)\nFlying Dream Engine - DEV(0.1.8)';

		if (currentFPS < 30)
			textField.textColor = 0xFFFF0000;
		else
			textField.textColor = 0xFFFFFFFF;
	}

	public function positionFPS(X:Float, Y:Float, ?scale:Float = 1)
	{
		this.x = FlxG.game.x + X;
		this.y = FlxG.game.y + Y;
	}
}