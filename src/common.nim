import polymorph, content, fusecore, ecs
export ecs

exportAll:
  
  type

    Tile = object
      floor, wall, overlay: Block
      build: EntityRef

    Content* = ref object of RootObj
      name*: string
      id*: uint32
    Block* = ref object of Content
      solid*: bool
      building*: bool
      patches*: seq[Patch]
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

      #events

      WorldCreate = object

      WallChange = object
        x, y: int
      FloorChange = object
        x, y: int
      OverlayChange = object
        x, y: int

  const
    zoom = 38.0
    tileSizePx = 8
    shadowColor = rgba(0, 0, 0, 0.2)
    layerFloor = 0'f32
    layerShadow = 10'f32
    layerWall = 20'f32

  var   
    shadows = newFramebuffer()
    worldWidth = 32
    worldHeight = 32
    tiles: seq[Tile]
  
  #all content by ID
  var 
    contentList: seq[Content]
    blockList: seq[Block]
    itemList: seq[Item]
    unitList: seq[Unit]

initContent:
  air = Block()
  grass = Block()
  ice = Block()
  iceWall = Block(solid: true)
  stoneWall = Block(solid: true)
  tungsten = Block()
  conveyor = Block(building: true)

  dagger = Unit()

  tungsten = Item()