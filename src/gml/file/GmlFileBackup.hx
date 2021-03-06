package gml.file;
import electron.FileSystem;
import electron.Menu;
import haxe.io.Path;
import ui.Preferences;
using tools.NativeString;
using tools.NativeArray;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFileBackup {
	public static var menu:Menu;
	static function getPath(file:GmlFile) {
		var path = file.path;
		if (path == null) return null;
		path = Path.normalize(path);
		var dir = Path.normalize(Project.current.dir);
		if (!path.startsWith(dir)) return null;
		return path.insert(dir.length, "/#backups");
	}
	static inline function indexPath(path:String, i:Int) {
		return path + ".backup" + i;
	}
	public static function save(file:GmlFile, code:String) {
		var num = switch (Project.current.version) {
			case GmlVersion.v1: Preferences.current.backupCount.v1;
			case GmlVersion.v2: Preferences.current.backupCount.v2;
			case GmlVersion.live: Preferences.current.backupCount.live;
			default: 0;
		};
		if (num <= 0) return;
		//
		var path = getPath(file);
		if (path == null) return;
		//
		try {
			var i = num - 1;
			var gap = 0;
			while (gap < 4) {
				var bkp = indexPath(path, i);
				if (FileSystem.existsSync(bkp)) {
					FileSystem.unlinkSync(bkp);
					gap = 0;
				} else gap += 1;
				i += 1;
			}
			//
			i = num - 1;
			while (i >= 0) {
				var s1 = indexPath(path, i);
				i -= 1;
				var s0 = indexPath(path, i);
				if (FileSystem.existsSync(s0)) {
					FileSystem.renameSync(s0, s1);
				}
			}
			//
			var pjDir = Path.normalize(Project.current.dir);
			var dirs = Path.directory(path).substring(pjDir.length + 1).split("/");
			var dirp = pjDir;
			for (dir in dirs) {
				dirp += "/" + dir;
				if (!FileSystem.existsSync(dirp)) {
					FileSystem.mkdirSync(dirp);
				}
			}
			//
			code = "// " + Date.now().toString() + "\r\n" + code;
			FileSystem.writeFileSync(indexPath(path, 0), code);
		} catch (e:Dynamic) {
			Main.console.log("Error making backup: ", e);
		}
	}
	static function load(name:String, path:String, kind:GmlFileKind) {
		if (GmlFileKindTools.isGML(kind)) kind = Normal;
		var file = new GmlFile(name, path, kind);
		file.path = null; // prevent from saving a backup
		GmlFile.openTab(file);
	}
	public static function updateMenu(file:GmlFile):Bool {
		var path = getPath(file);
		if (path == null) return null;
		menu.clear();
		//
		var name = file.name;
		var kind = file.kind;
		file = null;
		//
		try {
			var i = 0, gap = 0;
			while (gap < 4) {
				var bkp = indexPath(path, i);
				i += 1;
				if (FileSystem.existsSync(bkp)) {
					var t = FileSystem.statSync(bkp).mtime;
					menu.append(new MenuItem({
						label: i + ": " + t.toString(),
						click: function() load(name + " <backup>", bkp, kind)
					}));
					gap = 0;
				} else gap += 1;
			}
		} catch (_:Dynamic) {
			return false;
		}
		return true;
	}
	public static function init(){
		menu = new Menu();
	}
}
