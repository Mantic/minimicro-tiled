import "json"

import "lib/tiled/TiledLevel"
TiledLevel = locals["lib/tiled/TiledLevel"]

// TODO: I incremented this since I fixed a bug and added object group support.
VERSION = "0.0.2"

// tilemapFile: relative path (from app root) of the json export of a Tiled tilemap file. 
// imgPath: relative (to root of app) of where image files are located. EG: "images/maps"
load = function(tilemapFile, imgPath)
	tl = new TiledLevel
	tl.version = VERSION

	// Load tilemap file and parse it. 
	if not file.exists(tilemapFile) then
		return tl.setError(TiledLevel.Errors.FileNotExist)
	end if

	fHandle = file.open(tilemapFile)
	fSource = fHandle.read

	if fSource == "" then
		return tl.setError(TiledLevel.Errors.CannotLoadFile)
	end if

	tmap = json.parse(fSource)

	// Not sure how JSON.parse handles invalid JSON data...
	if tmap == null then
		return tl.setError(TiledLevel.Errors.InvalidJSON)
	end if

	// Parse map and construct the Tiled Level
	return tl._parseMap(tmap, imgPath)
end function

/// EXAMPLE USAGE: 
// 	tlevel = Tiled.load("res/tilemaps/dungeon1.json", "res/tilemaps")
//	if tlevel.error then 
//		print "Error loading tiled level: " + tlevel.error
//		return
//	end if
//  //           TiledLayer, Display layer, Tileset index
//  tlevel.addRenderLayer 0, APP.config.tileBG, 0
//  tlevel.setZoom 2
//  tlevel.render
//
