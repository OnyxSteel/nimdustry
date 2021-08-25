import polymorph, simplex, common

template makeUnit*(un: Unit, px, py: float32): EntityRef =
  let result = un.create()
  if result != NoEntityRef:
    #add basic components, may be changed later for more flexibility
    result.add cl(
      Vel(),
      Pos(x: px, y: py),
      DrawUnit(unit: un)
    )

    #TODO max health
  result

proc inWorld*(x, y: int): bool {.inline.} = x < worldWidth and y < worldHeight and x >= 0 and y >= 0

proc tile*(x, y: int): Tile =
  if not inWorld(x, y): Tile(floor: blockGrass, wall: blockStoneWall, overlay: blockAir) else: tiles[x + y*worldWidth]

template tile*(idx: int): Tile = tiles[idx]

proc setWall*(x, y: int, b: Block) =
  if inWorld(x, y): 
    fire(WallSet(x: x, y: y, wall: b))

template clearBuild*(entity: EntityRef) =
  let t = entity.fetch(Building)
  for dx in 0..<t.kind.size:
    for dy in 0..<t.kind.size:
      let 
        x = dx + t.x
        y = dy + t.y
        idx = x + y*worldWidth
      
      idx.tile.wall = blockAir
      idx.tile.build = NoEntityRef
      fire(WallChange(x: x, y: y))
  
  entity.delete()
      
proc toTile*(c: float32): int {.inline.} = (c + 0.5).int

proc solid*(x, y: int): bool = tile(x, y).wall.solid
#proc toTile*(c: Vec2): Vec2 {.inline.} = vec2(c.x + 0.5, c.y + 0.5)

proc offset*(b: Block): float32 {.inline.} = (b.size.float32 - 1f) / 2f

proc generateWorld*(width, height: int) =
  worldWidth = width
  worldHeight = height
  tiles = newSeq[Tile](worldWidth * worldHeight)

  for index, tile in tiles.mpairs:
    tile.floor = blockGrass
    tile.overlay = blockAir
    tile.wall = blockAir

    let 
      x = index mod width
      y = index div width
      scl = 22

    if noise(x / scl, y / scl) > 0.72: tile.overlay = blockTungsten
  
  fire(WorldCreate())

#update wall entities when walls change
onWallSet:
  let base = tile(event.x, event.y)
  let build = event.wall.create()

  if build != NoEntityRef:
    build.add cl(
      Building(x: event.x, y: event.y, kind: event.wall), 
      Pos(x: event.x.float32 + (event.wall.size - 1)/2f, y: event.y.float32 + (event.wall.size - 1)/2f), 
      StaticClip(rect: rect(vec2(event.x, event.y) - 0.5f, event.wall.size, event.wall.size))
    )

  #phase 1: delete old buildings
  for dx in 0..<event.wall.size:
    for dy in 0..<event.wall.size:
      let 
        x = event.x + dx
        y = event.y + dy
        idx = x + y*worldWidth
        t = idx.tile

      #found a building, kill it
      if t.build != NoEntityRef:
        clearBuild(t.build)
      else:
        #otherwise, replace, but do not fire any extra events; they will be fired later
        idx.tile.wall = blockAir

  #phase 2: place everything necessary down
  for dx in 0..<event.wall.size:
    for dy in 0..<event.wall.size:
      let 
        x = event.x + dx
        y = event.y + dy
        idx = x + y*worldWidth
        t = idx.tile

      idx.tile.wall = event.wall
      idx.tile.build = build
      
      fire(WallChange(x: x, y: y))