import polymorph, content, fusecore, ecs, tables, sugar
export ecs

#contains all global types and variables
#should not contain any logic

exportAll:
  
  type
    Tile = object
      floor, wall, overlay: Block
      build: EntityRef

    Content = ref object of RootObj
      name: string
      id: uint32
    Block = ref object of Content
      solid: bool
      building: proc(): EntityRef
      patches: seq[Patch]
    Item* = ref object of Content
    Unit* = ref object of Content

  registerComponents(defaultComponentOptions):
    type
      Pos = object
        x, y: float32
      Vel = object
        x, y, rot: float32
      Solid = object
        size: float32
      Input = object
      Draw = object
      Main = object
      Dir = object
        val: range[0..3]
      Building = object
        #bottom-left corner in tile coordinates
        x: int
        y: int
      
      #buildings

      Conveyor = object

  event(WorldCreate)
  event(WallChange, x = int, y = int)
  event(FloorChange, x = int, y = int)
  event(OverlayChange, x = int, y = int)

  const
    zoom = 38.0
    tileSizePx = 8
    shadowColor = rgba(0, 0, 0, 0.2)
    layerFloor = 0'f32
    layerShadow = 10'f32
    layerWall = 20'f32

  var
    worldWidth = 32
    worldHeight = 32
    tiles: seq[Tile]
  
  #all content by ID
  var 
    contentList: seq[Content]
    blockList: seq[Block]
    itemList: seq[Item]
    unitList: seq[Unit]

makeContent:
  air = Block()
  grass = Block()
  ice = Block()
  iceWall = Block(solid: true)
  stoneWall = Block(solid: true)
  tungsten = Block()
  conveyor = Block(building: () => newEntityWith(Conveyor(), Dir()))

  dagger = Unit()

  tungsten = Item()