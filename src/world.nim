import content, simplex, common, random

type Tile* = object
  floor*, wall*, overlay*: Block

var 
  worldWidth* = 32
  worldHeight* = 32
  tiles*: seq[Tile]

iterator everyTile(): tuple[x, y: int, tile: Tile] =
  for (index, tile) in tiles.pairs:
    yield (index mod worldWidth, index div worldWidth, tile)

proc inWorld*(x, y: int): bool {.inline.} = x < worldWidth and y < worldHeight and x >= 0 and y >= 0

proc tile*(x, y: int): Tile =
  if not inWorld(x, y): Tile(floor: blockGrass, wall: blockStoneWall, overlay: blockAir) else: tiles[x + y*worldWidth]

proc setWall*(x, y: int, b: Block) =
  if inWorld(x, y): tiles[x + y*worldWidth].wall = b

proc toTile*(c: float32): int {.inline.} = (c + 0.5).int

proc solid*(x, y: int): bool = tile(x, y).wall.solid

#proc toTile*(c: Vec2): Vec2 {.inline.} = vec2(c.x + 0.5, c.y + 0.5)

proc generateWorld*(width, height: int) =
  worldWidth = width
  worldHeight = height
  tiles = newSeq[Tile](worldWidth * worldHeight)

  for tile in tiles.mitems:
    tile.floor = blockGrass
    tile.overlay = blockAir
    tile.wall = blockAir

    if rand(20) <= 1: tile.overlay = blockTungsten