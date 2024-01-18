// TiledObjectProperty = {}
// TiledObjectProperty.load = function(raw)
//     self.name = raw.name
//     self.type = raw.type
//     self.value = raw.value
// end function

TiledObject = {}

TiledObject.load = function(object)
    self.gid = object.gid
    self.height = object.height
    self.id = object.id
    self.name = object.name
    self.type = object.type
    self.visible = object.visible
    self.width = object.width
    self.x = object.x
    self.y = object.y

    // There's a prop.type, but I'm not sure it's needed here.
    for prop in object.properties
        self[prop.name] = prop.value
    end for

    return self
end function

return TiledObject
