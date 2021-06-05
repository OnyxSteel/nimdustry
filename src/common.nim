import polymorph, fcore, ecs, tables, sugar, presets/[basic, effects, content]
export ecs, basic, effects, content

#contains all global types and variables
#should not contain any logic

exportAll:
  
  type
    Tile = object
      floor, wall, overlay: Block
      build: EntityRef
    Team = distinct uint8

    Block = ref object of Content
      solid: bool
      building: proc(): EntityRef
      #TODO (re)move rendering code?
      patches: seq[Patch]
    Item* = ref object of Content
    Unit* = ref object of Content
      health: float32
      size: float32

    #inventory for things
    Items = object
      items: seq[int32]

    #data for each team type
    TeamData = object
      items: Items

      
  registerComponents(defaultComponentOptions):
    type
      Vel = object
        x, y, rot: float32
      Solid = object
        size: float32
      Input = object
      Health = object
        val, max: float32
      Draw = object
      Dir = object
        val: range[0..3]
      DrawUnit = object
        unit: Unit
      DrawPatch = object
        patch: Patch
        rotOffset: float32
      Building = object
        #bottom-left corner in tile coordinates
        x: int
        y: int

      StaticClip = object
        rect: Rect
      
      #buildings

      Conveyor = object
  
  event(WorldCreate)
  event(WallChange, x = int, y = int)
  event(FloorChange, x = int, y = int)
  event(OverlayChange, x = int, y = int)

  const
    zoom = 40f
    tileSizePx = 8
    pixelation = (zoom / tileSizePx).int
    shadowColor = rgba(0, 0, 0, 0.2)
    layerFloor = 0f
    layerShadow = 10f
    layerWall = 20f
    layerEffect = 40f
    palAccent = %"ffd37f"
    palRemove = %"e55454"

  var
    worldWidth = 32
    worldHeight = 32
    tiles: seq[Tile]
    #team data by team index
    teams: array[Team, TeamData]

makeContent:
  air = Block()
  grass = Block()
  ice = Block()
  iceWall = Block(solid: true)
  stoneWall = Block(solid: true)
  tungsten = Block()
  conveyor = Block(building: () => newEntityWith(Conveyor(), Dir()))

  dagger = Unit(health: 100, size: 0.5)
  crawler = Unit(health: 50, size: 0.4)

  none = Item()
  tungsten = Item()