import polymorph, simplex, common

#TODO move?
proc inWorld*(x, y: int): bool {.inline.} = x < worldWidth and y < worldHeight and x >= 0 and y >= 0

proc tile*(x, y: int): Tile =
  if not inWorld(x, y): Tile(floor: blockGrass, wall: blockStoneWall, overlay: blockAir) else: tiles[x + y*worldWidth]

proc setWall*(x, y: int, b: Block) =
  if inWorld(x, y): 
    tiles[x + y*worldWidth].wall = b
    fire(WallChange(x: x, y: y))

proc setBuild*(x, y: int, b: EntityRef) =
  if inWorld(x, y): 
    tiles[x + y*worldWidth].build = b

proc toTile*(c: float32): int {.inline.} = (c + 0.5).int

proc solid*(x, y: int): bool = tile(x, y).wall.solid
#proc toTile*(c: Vec2): Vec2 {.inline.} = vec2(c.x + 0.5, c.y + 0.5)

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
