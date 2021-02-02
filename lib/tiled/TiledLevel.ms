import "json"
import "stringUtil"


import "lib/tiled/TiledLayer"
TiledLayer = locals["lib/tiled/TiledLayer"]

// TODOS:
// Support tile properties
// 

// Limitations:
// Does not support rotated tiles or multiple images/tilemaps per layer. 
// 

Errors = {
	"FileNotExist": 1,
	1: "File does not exist.",

	"CannotLoadFile": 2,
	2: "Cannot load file or file empty.",

	"InvalidJSON": 3,
	3: "Unable to parse json file.",

	"InvalidTiledFile": 4,
	4: "Invalid Tiled file.",

	"ContainsNoLayers": 5,
	5: "Map does not contain any layer data.",

	"WrongImageFileExtension": 6,
	6: "Image file does not contain a valid extensin: .png, .jpg, .jpeg.",
}

TiledLevel = {
	"error": null,
	"errId": 0,
	"source": null,
	"imgPath": "",               // Image path of tileset images.
	"tilesetImgs": [],           // Array list of tileset images.

	"hasLayers": false,          // Only set to true once layers have been loaded. 
	"x": 0,
	"y": 0,

	// Tiled core data:
	"height": 0,                 // Vertical tile count
	"width" : 0,                 // Horizontal tile count
	"tileHeight" : 0,            // Pixel height of tiles
	"tileWidth": 0,              // Pixel width of tiles
	"layers": null,              // An array of TiledLayer, in view order and with layer data.

	// Additional Tiled metadata:
	"infinite": false,          // Infinite not yet supported!
	"orientation": "orthogonal", // Only 'orthogonal' supported!
	"renderOrder": "right-up",   // Order of overlapping tiles/objects
	"tiledVersion": "0",
	"version": 0.0,              // Number version: major.minor
	"type": "",                  // Tiled file type: map, (?)
	"compressionLevel": -1, 		 // Not sure... 
}

// tiledLayerIndex: Which layer (in the Tiled file) to render.
// displayIndex: Which minimicro display layer to use. 
// tilesetIndex: Which image to use for tiles. Minimicro can only support 1 image at a time per layer. 
// clearIdx:  What tile id to clear the map with? -1 means clear with transparent / empty tile. 
TiledLevel.addRenderLayer = function(tiledLayerIndex, displayIndex, tilesetIndex = -1, clearIdx = -1)
	if not self.layers then
		print "Cannot addRenderLayer: No such layer exists: " + tiledLayerIndex
		return false
	end if

	if not self.layers.hasIndex(tiledLayerIndex) then
		// Layers out of index!
		print "TiledLevel: addRenderLayer: Layer out of index: " + tiledLayerIndex
		return false
	end if

	// By default, tilesetIndex will equal tiledLayerIndex. 
	if tilesetIndex == -1 then tilesetIndex = tiledLayerIndex
	
	if not self.tilesetImgs.hasIndex(tilesetIndex) then
		print "TiledLevel: addRenderLayer: Cannot find tileset source of index: " + tilesetIndex
		tilesetIndex = 0
	end if

	img = self.tilesetImgs[tilesetIndex]

	return self.layers[tiledLayerIndex].setRenderLayer(displayIndex, img, clearIdx)
end function

// Render all layers (call once). 
TiledLevel.render = function()
	if not self.hasLayers then return 

	for i in range(0, self.layers.len - 1) 
		self.layers[i].render
	end for
end function

// Set zoom level. 
TiledLevel.setZoom = function(zoom) 
	if not self.hasLayers then return 

	for i in range(0, self.layers.len - 1) 
		self.layers[i].setZoom zoom
	end for
end function

// Scroll relative to the current position (via dx, dy).
TiledLevel.scrollBy = function(dx, dy) 
	if not self.hasLayers then return 
	if not (dx isa number) then dx = 0
	if not (dy isa number) then dy = 0

	x = self.x + dx
	y = self.y + dy

	self.x = x
	self.y = y

	for i in range(0, self.layers.len - 1)
		self.layers[i].display.scrollX = x
		self.layers[i].display.scrollY = y
	end for

end function

// Scroll instantaneously to an x, y coordinate. 
TiledLevel.scrollTo = function(x, y)
	if not self.hasLayers then return 
	if not (x isa number) then x = self.x
	if not (y isa number) then y = self.y

	self.x = x
	self.y = y

	for i in range(0, self.layers.len - 1)
		self.layers[i].display.scrollX = x
		self.layers[i].display.scrollY = y
	end for
end function

// Used internally to create and return errors. 
TiledLevel.setError = function(errorId, msg = null)
	self.errId = errorId

	if msg != null and msg isa string then
		self.error = msg
	else
		if Errors.hasIndex(errorId) then
			self.error = Errors[errorId]
		end if
	end if

	return self
end function

TiledLevel._isValidMap = function()
	return self.source.hasIndex("tiledversion") and self.source.hasIndex("type") and self.source.type == "map"
end function

TiledLevel._parseMap = function(map, imgPath)
	self.source = map
	self.imgPath = imgPath
	
	// Check if the file is a valid tiled map.
	if not self._isValidMap then
		return self.setError(Errors.InvalidTiledFile)
	end if

	// Load core data:
	self.height = map.height
	self.width = map.width
	self.tileHeight = map.tileheight
	self.tileWidth = map.tilewidth
	self.layers = self._parseLayers

	// Load meta data:
	self.orientation = map.orientation
	self.renderOrder = map.renderorder
	self.tiledVersion = map.tiledversion
	self.version = map.version
	self.infinite = map.infinite
	self.type = map.type
	self.compressionLevel = map.compressionlevel

	// Grab image sources from all tilesets.
	self._parseTilesets map.tilesets

	return self
end function

TiledLevel._parseLayers = function()
	layers = []

	if self.source == null then
		return layers
	end if

	length = self.source.layers.len
	if length == 0 then
		self.setError(Errors.ContainsNoLayers)
		return layers
	end if

	for i in range(0, length - 1)
		maxSize = self.tileWidth
		if self.tileHeight > maxSize then 
			maxSize = self.tileHeight
		end if

		layer = new TiledLayer
		layers.push layer.load(self.source.layers[i], maxSize)
		
		self.hasLayers = true
	end for

	return layers
end function

TiledLevel._parseTilesets = function(tilesets)
	for i in range(0, tilesets.len - 1)
		tilesetDef = tilesets[i]
		fSource = tilesetDef.source

		// Load tileset file.
		tileset = self._loadTilesetFile(self.imgPath + "/" + fSource)

		if tileset isa number then 
			return self.setError(tileset)
		end if

		imgPath = self.imgPath + "/" + tileset.image
		if not self._hasValidImageExtension(imgPath) then
			return TiledLevel.Errors.WrongImageFileExtension
		end if

		img = file.loadImage(imgPath)
		// print "Loading tileset image: " + (self.imgPath + "/" + tileset.image)

		// A width/height of 8 is an arbitrary number 	
		if not img or img.width == 8 then 
			print "TiledLayer: Could not load image: " + self.imgPath + "/" + tilesets[i].source
			self.tilesetImgs.push false
		else
			self.tilesetImgs.push img
		end if
	end for
end function

TiledLevel._loadTilesetFile = function(filePath)
	// Load tilemap file and parse it. 
	if not file.exists(filePath) then
		print "Invalid filepath: " + filePath
		return TiledLevel.Errors.FileNotExist
	end if

	fHandle = file.open(filePath)
	fString = fHandle.read

	if fString == "" then
		return TiledLevel.Errors.CannotLoadFile
	end if

	tileset = json.parse(fString)

	// Not sure how JSON.parse handles invalid JSON data...
	if tileset == null then
		return TiledLevel.Errors.InvalidJSON
	end if

	return tileset
end function

TiledLevel._hasValidImageExtension = function(imgPath)
	if not (imgPath isa string) then return false 
	return imgPath.endsWith(".json") or imgPath.endsWith(".png") or imgPath.endsWith(".jpg")
end function


TiledLevel.Errors = Errors
return TiledLevel