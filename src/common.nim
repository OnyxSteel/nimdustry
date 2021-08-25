import polymorph, fcore, ecs, tables, sugar, presets/[basic, effects, content]
export ecs, basic, effects, content

#contains all global types and variables
#should not contain any logic

exportAll:

  defineContentTypes:
    type
      Block = ref object of Content
        solid: bool
        create: proc(): EntityRef = () => NoEntityRef
        #TODO (re)move rendering code?
        patches: seq[Patch]
        size: int = 1
      Item* = ref object of Content
      Unit* = ref object of Content
        create: proc(): EntityRef = () => NoEntityRef
  
  type
    Tile = object
      floor, wall, overlay: Block
      build: EntityRef
    Team = distinct uint8
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
        val: float32
      Draw = object
      Dir = object
        val: range[0..3]
      DrawUnit = object
        unit: Unit
      DrawPatch = object
        patch: Patch
        rotOffset: float32
      DrawDrill = object
      Building = object
        #bottom-left corner in tile coordinates
        x, y: int
        kind: Block

      ## statically clipped in a quadtree, used for buildings
      StaticClip = object
        rect: Rect
      
      ## flag for objects that are clipped onscreen
      Onscreen = object
        frame: int64
      
      #buildings

      Conveyor = object
      Drill = object
  
  event(WorldCreate)
  event(WallSet, x = int, y = int, wall = Block)
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

    teamDerelict = 0.Team
    teamSharded = 1.Team
    teamCrux = 2.Team

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

  conveyor = Block(create: () => newEntityWith(Conveyor(), Dir()))
  mechanicalDrill = Block(size: 2, solid: true, create: () => newEntityWith(DrawDrill(), Drill()))

  #newEntityWith(Pos(x: px, y: py), Vel(), Health(max: un.health, val: un.health), Solid(size: un.size), DrawUnit(unit: un))
  dagger = Unit(create: () => newEntityWith(Health(val: 100), Solid(size: 0.5)))
  crawler = Unit(create: () => newEntityWith(Health(val: 50), Solid(size: 0.4)))

  none = Item()
  tungsten = Item()