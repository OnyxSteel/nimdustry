import content, fuse/[simplex, common]

type Tile* = object
  floor*, wall*, overlay*: Block

var 
  worldWidth = 32
  worldHeight = 32
  tiles: seq[Tile]

proc inBounds(x, y: int): bool {.inline.} = x < worldWidth and y < worldHeight and x >= 0 and y >= 0

proc tile*(x, y: int): Tile =
  if not inBounds(x, y): Tile(floor: blockGrass, wall: blockStoneWall) else: tiles[x + y*worldWidth]

proc setWall*(x, y: int, b: Block) =
  if inBounds(x, y): tiles[x + y*worldWidth].wall = b

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