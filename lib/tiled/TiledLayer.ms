//// LIMITATIONS: 
// Mini-Micro's tile display can only use one tileset per layer!
// Tile rotation is not supported. 
////

TiledLayer = {
	// Layer core data
	"x": 0,            // Layer x offset
	"y": 0,            // Layer y offset
	"height": 0,       // Vertical tile count
	"width": 0,        // Horizontal tile count
	"opacity": 1,      // Layer opacity: 0-1
	"visible": true,   // Layer visibility: true/false
	"data": null,      // An array of tile ids. Originally an array or string, depending on export settings. 

	// Layer metadata
	"id": 0,           // Layer id count
	"name": "",        // Layer name
	"type": "", 		   // Layer type: tilelayer, objectlayer

	// Custom data
	"zoom": 1,         // zoom effect = td.cellSize * zoom
	"scrollX": 0, 
	"scrollY": 0,
	"display": null, 
	"tileSize": 16,    // Size (in pixels) of an individual tile. 
	"clearIdx": 0,     // The tilemap index used to clear the display.
}

TiledLayer.load = function(map, tileSize)
	self.x = map.x
	self.y = map.y
	self.height = map.height
	self.width = map.width
	self.opacity = map.opacity
	self.visible = map.visible == true
	self.id = map.id
	self.name = map.name
	self.type = map.type

	self.tileSize = tileSize
	
	self.data = self._parseData(map.data)

	return self
end function

// Assigns a micromini layer to this tiled layer. 
TiledLayer.setRenderLayer = function(displayIndex, tilesetImage, firstgid, clearIdx = -1,)

	if displayIndex <= 0 or displayIndex > 7 then
		// Display index out of bounds!
		print "Display index out of bounds: " + displayIndex
		return false
	end if

	// print "Using display index: " + displayIndex
	display(displayIndex).mode = displayMode.tile
	td = display(displayIndex)

	if tilesetImage != null then 
		td.tileSet = tilesetImage
	else
		print "TiledLayer: setRenderLayer: No image provided!"
	end if

	if clearIdx < 0 then clearIdx = null
	td.clear clearIdx

	maxSize = self.width
	if self.height > self.width then
		maxSize = self.height
	end if

	td.tileSetTileSize = self.tileSize
	td.scrollX = self.scrollX
	td.scrollY = self.scrollY
	td.extent = [self.width, self.height]
	td.cellSize = self.tileSize * self.zoom

	self.display = td
	self.firstgid = firstgid

	return true
end function

// Renders this tiled layer to the given display layer. This is a slow function; only call once. 
TiledLayer.render = function()
	if self.display == null then
		return
	end if

	width = self.width
	height = self.height

	tileCount = width * height

	// Render cells
	for i in range(0, tileCount - 1)
		// TODO: The `- 1` here is a bug.  The offset should be based on the `firstgid` value in the map .tmj file.
		// self.display.setCell (i % width), floor(i/width), (self.data[i] - 1)
		self.display.setCell (i % width), floor(i/width), (self.data[i] - self.firstgid)
		
		// Just in case its a very large map, yield a few times to keep the system from locking up. 
		if i % 500 == 0 and i > 490 then
			yield
		end if
	end for
end function

TiledLayer.setZoom = function(zoom)
	if not self.display then 
		return 
	end if

	self.display.cellSize = self.tileSize * zoom
	self.zoom = zoom
end function

// Reverses the row order of the tiled map to the way micromini wants them. 
TiledLayer._parseData = function(raw)
	data = []
	rawList = []

	if raw isa string then
		//@@ Turn string into an array: rawList
		print "TiledLayer: compressed/base64 layer data not yet supported!"
	else if raw isa list then
		rawList = raw
	else
		print "Raw isa: " + raw.__isa
	end if

	// Correct Y order of tiles. By default Tiled "renders" tiles from the top-left as 0,0.
	// Since mini-micro renders with 0,0 being on the bottom-left, we need to invert the tile rows. 

	j = 0
	data = [null] * rawList.len
	  for i in range(0, rawList.len - 1)
		j = (i % self.width) + (self.width * (self.height - floor(i/self.width) - 1))
		data[j] = rawList[i]

		// Just in case its a very large map, yield a few times.
		if i % 500 == 0 and i > 490 then
			yield
		end if
  	end for

	return data
end function


return TiledLayer