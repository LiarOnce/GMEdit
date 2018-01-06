package yy;
import electron.FileSystem;
import gml.Project;
import haxe.io.Path;
import js.Error;
import ui.GlobalSearch;

/**
 * ...
 * @author YellowAfterlife
 */
class YySearcher {
	public static function run(
		pj:Project, fn:ProjectSearcher, done:Void->Void, ?opt:GlobalSearchOpt
	):Void {
		var pjDir = pj.dir;
		var yyProject:YyProject = FileSystem.readJsonFileSync(pj.path);
		var rxName = Project.rxName;
		var filesLeft = 1;
		inline function next():Void {
			if (--filesLeft <= 0) done();
		}
		for (resPair in yyProject.resources) {
			var res = resPair.Value;
			var resName:String, resFull:String;
			switch (res.resourceType) {
				case "GMScript": if (opt == null || opt.checkScripts) {
					resName = rxName.replace(res.resourcePath, "$1");
					resFull = Path.join([pjDir, res.resourcePath]);
					resFull = Path.withoutExtension(resFull) + ".gml";
					filesLeft += 1;
					FileSystem.readTextFile(resFull, function(error, code) {
						if (error == null) fn(resName, resFull, code);
						next();
					});
				};
				case "GMObject": if (opt == null || opt.checkObjects) {
					resName = rxName.replace(res.resourcePath, "$1");
					resFull = Path.join([pjDir, res.resourcePath]);
					filesLeft += 1;
					FileSystem.readTextFile(resFull, function(error, data) {
						if (error == null) try {
							var resDir = Path.directory(resFull);
							var obj:YyObject = haxe.Json.parse(data);
							var code = obj.getCode(resFull);
							fn(resName, resFull, code);
						} catch (_:Dynamic) { };
						next();
					});
				};
				case "GMTimeline": if (opt == null || opt.checkObjects) {
					resName = rxName.replace(res.resourcePath, "$1");
					resFull = Path.join([pjDir, res.resourcePath]);
					filesLeft += 1;
					FileSystem.readTextFile(resFull, function(error, data) {
						if (error == null) try {
							var resDir = Path.directory(resFull);
							var obj:YyTimeline = haxe.Json.parse(data);
							var code = obj.getCode(resFull);
							fn(resName, resFull, code);
						} catch (_:Dynamic) { };
						next();
					});
				};
			}
		}
		next();
	}
}
