import "lib/tiled/TiledObject"
TiledObject = locals["lib/tiled/TiledObject"]

// TODO: Everything about objectgroup support was added after downloading the library.

TiledObjectGroup = {
    "draworder": "",
    "id": 0,
    "name": "",
    "objects": [], // Array of TiledObject.
    "opacity": 0,
    "type": "",
    "visible": false,
    "x": 0,
    "y": 0,
}

TiledObjectGroup.load = function(layer, tileSize)
	self.draworder = layer.draworder
    self.id = layer.id
    self.name = layer.name
    self.opacity = layer.opacity
    self.type = layer.type
    self.visible = layer.visible
    self.x = layer.x
    self.y = layer.y
	
	self.objects = self._parseObjects(layer.objects)
	return self
end function

TiledObjectGroup.getByName = function(name)
    for obj in self.objects
        if obj.name == name then return obj
    end for
    return null
end function

TiledObjectGroup._parseObjects = function(raw)
    objects = []
    for item in raw
        objects.push (new TiledObject).load(item)
    end for
    return objects
end function

return TiledObjectGroup
