package psychlua;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.ui.FlxButton;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxRuntimeShader;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;

import haxe.Json;
import haxe.Timer;
import sys.io.File;
import sys.FileSystem;

import backend.Song;
import backend.Highscore;
import backend.Section;
import backend.Rating;
import backend.WeekData;
import backend.Difficulty;
import backend.Conductor;
import backend.StageData;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;
import objects.Character;
import objects.HealthIcon;
import objects.Alphabet;
import objects.AttachedSprite;
import objects.Bar;
import objects.BGSprite;

import states.PlayState;
import states.MainMenuState;
import states.FreeplayState;
import states.StoryMenuState;
import states.CreditsState;
import states.TitleState;
import options.OptionsState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;
import states.editors.MasterEditorMenu;

import substates.PauseSubState;
import substates.GameOverSubstate;

#if LUA_ALLOWED
import psychlua.FunkinLua;
import psychlua.LuaUtils;
#end

#if mobile
import mobile.TouchPad;
import mobile.MobileInputID;
#end

#if SScript
import tea.SScript;
#end

class HScript
{
	public var scriptName:String;
	public var scriptFile:String;
	public var modFolder:String;
	public var closed:Bool = false;
	public var parent:Dynamic;
	public var variables:Map<String, Dynamic> = new Map();
	public var callbacks:Map<String, Dynamic> = new Map();

	#if SScript
	public var interp:tea.SScript;
	#end

	public function new(file:String, ?parentState:Dynamic)
	{
		this.scriptFile = file;
		this.scriptName = file;
		this.parent = parentState;

		#if MODS_ALLOWED
		detectModFolder();
		#end

		loadAndExecute();
	}

	function detectModFolder()
	{
		#if MODS_ALLOWED
		var parts = scriptFile.split('/');
		for (i in 0...parts.length)
		{
			if (parts[i] == 'mods' && i + 1 < parts.length)
			{
				modFolder = parts[i + 1];
				break;
			}
		}
		#end
	}

	function loadAndExecute()
	{
		#if SScript
		try
		{
			var content = File.getContent(scriptFile);
			interp = new tea.SScript(content, false, false);

			setupGlobals();

			if (interp.parsingException != null)
			{
				showError('Parse Error', interp.parsingException.message);
				return;
			}

			if (interp.exists('create'))
			{
				var callValue = interp.call('create');
				if (!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if (e != null)
					{
						showError('Create Error', e.message);
					}
				}
			}
		}
		catch(e:Dynamic)
		{
			showError('Load Error', Std.string(e));
		}
		#else
		showError('SScript Not Available', 'SScript is not supported');
		#end
	}

	function setupGlobals()
	{
		#if SScript
		interp.set('FlxG', FlxG);
		interp.set('FlxMath', FlxMath);
		interp.set('FlxSprite', FlxSprite);
		interp.set('FlxCamera', FlxCamera);
		interp.set('FlxObject', FlxObject);
		interp.set('FlxText', FlxText);
		interp.set('FlxTimer', FlxTimer);
		interp.set('FlxTween', FlxTween);
		interp.set('FlxEase', FlxEase);
		interp.set('FlxColor', FlxColor);
		interp.set('FlxSound', FlxSound);
		interp.set('FlxPoint', FlxPoint);
		interp.set('FlxRect', FlxRect);
		interp.set('FlxGroup', FlxGroup);
		interp.set('FlxButton', FlxButton);
		interp.set('FlxKey', FlxKey);
		interp.set('FlxGamepad', FlxGamepad);

		#if (!flash && sys)
		interp.set('FlxRuntimeShader', FlxRuntimeShader);
		interp.set('FlxBackdrop', FlxBackdrop);
		#end

		interp.set('PlayState', PlayState);
		interp.set('game', PlayState.instance);
		interp.set('Conductor', Conductor);
		interp.set('Paths', Paths);
		interp.set('ClientPrefs', ClientPrefs);
		interp.set('Song', Song);
		interp.set('Highscore', Highscore);
		interp.set('Rating', Rating);
		interp.set('WeekData', WeekData);
		interp.set('Difficulty', Difficulty);
		interp.set('StageData', StageData);

		interp.set('Note', Note);
		interp.set('StrumNote', StrumNote);
		interp.set('NoteSplash', NoteSplash);
		interp.set('Character', Character);
		interp.set('HealthIcon', HealthIcon);
		interp.set('Alphabet', Alphabet);
		interp.set('AttachedSprite', AttachedSprite);
		interp.set('Bar', Bar);
		interp.set('BGSprite', BGSprite);

		interp.set('MainMenuState', MainMenuState);
		interp.set('FreeplayState', FreeplayState);
		interp.set('StoryMenuState', StoryMenuState);
		interp.set('CreditsState', CreditsState);
		interp.set('OptionsState', OptionsState);
		interp.set('TitleState', TitleState);
		interp.set('ChartingState', ChartingState);
		interp.set('CharacterEditorState', CharacterEditorState);
		interp.set('MasterEditorMenu', MasterEditorMenu);

		interp.set('PauseSubState', PauseSubState);
		interp.set('GameOverSubstate', GameOverSubstate);

		interp.set('Json', Json);
		interp.set('File', File);
		interp.set('FileSystem', FileSystem);
		interp.set('Timer', Timer);
		interp.set('Reflect', Reflect);
		interp.set('Type', Type);
		interp.set('Std', Std);
		interp.set('StringTools', StringTools);

		interp.set('this', this);
		interp.set('script', this);
		interp.set('parent', parent);

		#if mobile
		interp.set('MobileInputID', MobileInputID);
		#end

		registerFunctions();
		#end
	}

	function registerFunctions()
	{
		#if SScript
		interp.set('close', function() {
			closed = true;
			return true;
		});

		interp.set('add', function(obj:Dynamic) {
			if (parent != null && Reflect.hasField(parent, 'add'))
				Reflect.callMethod(parent, Reflect.field(parent, 'add'), [obj]);
			else
				FlxG.state.add(obj);
		});

		interp.set('remove', function(obj:Dynamic) {
			if (parent != null && Reflect.hasField(parent, 'remove'))
				Reflect.callMethod(parent, Reflect.field(parent, 'remove'), [obj, true]);
			else
				FlxG.state.remove(obj, true);
		});

		interp.set('insert', function(pos:Int, obj:Dynamic) {
			if (parent != null && Reflect.hasField(parent, 'insert'))
				Reflect.callMethod(parent, Reflect.field(parent, 'insert'), [pos, obj]);
			else
				FlxG.state.insert(pos, obj);
		});

		interp.set('setVar', function(name:String, value:Dynamic) {
			variables.set(name, value);
			return value;
		});

		interp.set('getVar', function(name:String) {
			return variables.get(name);
		});

		interp.set('removeVar', function(name:String) {
			if (variables.exists(name))
			{
				variables.remove(name);
				return true;
			}
			return false;
		});

		interp.set('call', function(name:String, ?args:Array<Dynamic>) {
			if (callbacks.exists(name))
			{
				var func = callbacks.get(name);
				if (args != null)
					return Reflect.callMethod(null, func, args);
				else
					return Reflect.callMethod(null, func, []);
			}
			return null;
		});

		interp.set('createCallback', function(name:String, func:Dynamic) {
			callbacks.set(name, func);
		});

		interp.set('runLuaCode', function(code:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			#if LUA_ALLOWED
			if (PlayState.instance.luaArray.length > 0)
			{
				var firstLua = PlayState.instance.luaArray[0];
				if (firstLua != null && firstLua.lua != null)
				{
					return firstLua.call('runLuaCode', [code, varsToBring, funcToRun, funcArgs]);
				}
			}
			trace('[HScript] runLuaCode: No Lua script available');
			#else
			trace('[HScript] runLuaCode: Lua is not supported');
			#end
			return null;
		});

		interp.set('debugPrint', function(text:String, ?color:FlxColor) {
			if (color == null) color = FlxColor.WHITE;
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug(text, color);
			trace('[HScript] $text');
		});

		interp.set('trace', function(text:Dynamic) {
			trace('[HScript] $text');
		});

		interp.set('switchState', function(stateClassName:String) {
			var clazz = Type.resolveClass('states.' + stateClassName);
			if (clazz != null)
				FlxG.switchState(Type.createInstance(clazz, []));
			else
				trace('[HScript] Unknown state: $stateClassName');
		});

		interp.set('startSong', function(songName:String, ?difficulty:Int = 1) {
			try
			{
				PlayState.SONG = Song.loadFromJson(songName.toLowerCase(), songName.toLowerCase());
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = difficulty;
				LoadingState.loadAndSwitchState(new PlayState());
			}
			catch(e:Dynamic)
			{
				trace('[HScript] Failed to load song: $songName');
			}
		});

		interp.set('getProperty', function(obj:String, ?prop:String) {
			if (prop == null)
				return Reflect.getProperty(PlayState.instance, obj);
			else
				return Reflect.getProperty(Reflect.getProperty(PlayState.instance, obj), prop);
		});

		interp.set('setProperty', function(obj:String, value:Dynamic, ?prop:String) {
			if (prop == null)
				Reflect.setProperty(PlayState.instance, obj, value);
			else
				Reflect.setProperty(Reflect.getProperty(PlayState.instance, obj), prop, value);
			return value;
		});

		interp.set('getObject', function(name:String) {
			return PlayState.instance.getLuaObject(name);
		});

		interp.set('screenCenter', function(obj:String, ?axis:String) {
			var target = PlayState.instance.getLuaObject(obj);
			if (target == null) target = Reflect.getProperty(PlayState.instance, obj);
			if (target != null)
			{
				if (axis == 'x') target.screenCenter(X);
				else if (axis == 'y') target.screenCenter(Y);
				else target.screenCenter(XY);
			}
		});

		interp.set('scaleObject', function(obj:String, x:Float, y:Float) {
			var target = PlayState.instance.getLuaObject(obj);
			if (target == null) target = Reflect.getProperty(PlayState.instance, obj);
			if (target != null && Std.isOfType(target, FlxSprite))
			{
				var spr:FlxSprite = cast target;
				spr.scale.set(x, y);
				spr.updateHitbox();
			}
		});

		interp.set('updateHitbox', function(obj:String) {
			var target = PlayState.instance.getLuaObject(obj);
			if (target == null) target = Reflect.getProperty(PlayState.instance, obj);
			if (target != null && Std.isOfType(target, FlxSprite))
			{
				var spr:FlxSprite = cast target;
				spr.updateHitbox();
			}
		});

		interp.set('setScrollFactor', function(obj:String, x:Float, y:Float) {
			var target = PlayState.instance.getLuaObject(obj);
			if (target == null) target = Reflect.getProperty(PlayState.instance, obj);
			if (target != null)
				target.scrollFactor.set(x, y);
		});

		interp.set('setObjectCamera', function(obj:String, camera:String) {
			var target = PlayState.instance.getLuaObject(obj);
			if (target == null) target = Reflect.getProperty(PlayState.instance, obj);
			if (target != null)
			{
				var cam = PlayState.instance.camHUD;
				if (camera == 'game') cam = PlayState.instance.camGame;
				else if (camera == 'other') cam = PlayState.instance.camOther;
				target.cameras = [cam];
			}
		});

		interp.set('addBehindGF', function(obj:Dynamic) {
			PlayState.instance.addBehindGF(obj);
		});

		interp.set('addBehindDad', function(obj:Dynamic) {
			PlayState.instance.addBehindDad(obj);
		});

		interp.set('addBehindBF', function(obj:Dynamic) {
			PlayState.instance.addBehindBF(obj);
		});

		interp.set('playSound', function(sound:String, volume:Float) {
			FlxG.sound.play(Paths.sound(sound), volume);
		});

		#if mobile
		interp.set('addTouchPad', function(dpad:String, action:String) {
			if (PlayState.instance != null)
			{
				PlayState.instance.makeLuaTouchPad(dpad, action);
				PlayState.instance.addLuaTouchPad();
			}
		});

		interp.set('removeTouchPad', function() {
			if (PlayState.instance != null)
				PlayState.instance.removeLuaTouchPad();
		});
		#end

		interp.set('controls', Controls.instance);
		interp.set('keyJustPressed', function(name:String) {
			name = name.toLowerCase();
			switch(name)
			{
				case 'left': return Controls.instance.NOTE_LEFT_P;
				case 'down': return Controls.instance.NOTE_DOWN_P;
				case 'up': return Controls.instance.NOTE_UP_P;
				case 'right': return Controls.instance.NOTE_RIGHT_P;
				default: return Controls.instance.justPressed(name);
			}
			return false;
		});

		interp.set('keyPressed', function(name:String) {
			name = name.toLowerCase();
			switch(name)
			{
				case 'left': return Controls.instance.NOTE_LEFT;
				case 'down': return Controls.instance.NOTE_DOWN;
				case 'up': return Controls.instance.NOTE_UP;
				case 'right': return Controls.instance.NOTE_RIGHT;
				default: return Controls.instance.pressed(name);
			}
			return false;
		});

		interp.set('keyReleased', function(name:String) {
			name = name.toLowerCase();
			switch(name)
			{
				case 'left': return Controls.instance.NOTE_LEFT_R;
				case 'down': return Controls.instance.NOTE_DOWN_R;
				case 'up': return Controls.instance.NOTE_UP_R;
				case 'right': return Controls.instance.NOTE_RIGHT_R;
				default: return Controls.instance.justReleased(name);
			}
			return false;
		});

		interp.set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			var str:String = '';
			if(libPackage.length > 0)
				str = libPackage + '.';
			var clazz = Type.resolveClass(str + libName);
			if (clazz != null)
				interp.set(libName, clazz);
		});

		interp.set('import', function(path:String) {
			var parts = path.split('.');
			var className = parts[parts.length - 1];
			var clazz = Type.resolveClass(path);
			if (clazz == null) clazz = Type.resolveClass('psychlua.' + className);
			if (clazz == null) clazz = Type.resolveClass('states.' + className);
			if (clazz == null) clazz = Type.resolveClass('backend.' + className);
			if (clazz == null) clazz = Type.resolveClass('objects.' + className);
			if (clazz != null)
			{
				interp.set(className, clazz);
				return clazz;
			}
			return null;
		});
		#end
	}

	public function callFunction(name:String, ?args:Array<Dynamic>):Dynamic
	{
		#if SScript
		if (closed || interp == null) return null;
		if (!interp.exists(name)) return null;

		try
		{
			var callValue = interp.call(name, args != null ? args : []);
			if (!callValue.succeeded)
			{
				var e = callValue.exceptions[0];
				if (e != null)
				{
					showError('Call Error', e.message);
				}
				return null;
			}
			return callValue.returnValue;
		}
		catch(e:Dynamic)
		{
			showError('Call Error', Std.string(e));
			return null;
		}
		#else
		return null;
		#end
	}

	public function setVariable(name:String, value:Dynamic)
	{
		#if SScript
		if (interp != null) interp.set(name, value);
		variables.set(name, value);
		#end
	}

	public function getVariable(name:String):Dynamic
	{
		#if SScript
		if (interp != null && interp.exists(name))
			return interp.get(name);
		#end
		return variables.get(name);
	}

	function showError(title:String, message:String)
	{
		var fullMsg = '[HScript] $scriptName: $title - $message';
		trace(fullMsg);
		if (PlayState.instance != null)
			PlayState.instance.addTextToDebug(fullMsg, FlxColor.RED);
	}

	public function destroy()
	{
		closed = true;
		#if SScript
		if (interp != null)
		{
			interp.destroy();
			interp = null;
		}
		#end
		variables.clear();
		callbacks.clear();
	}
}