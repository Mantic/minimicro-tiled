import "json"

import "lib/tiled/TiledLevel"
TiledLevel = locals["lib/tiled/TiledLevel"]

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
