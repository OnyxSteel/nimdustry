import common, polymorph, content, tables, math, random, strformat, simplex

#pack sprites on launch
static:
  echo staticExec("fusepack -p:../assets-raw/sprites -o:../assets/atlas")

#fires a new event
template fireEvent[T](val: T) = discard newEntityWith(Event(), val)

#define system
template sys(isDef: static[bool], name: static[string], componentTypes: openarray[typedesc], body: untyped) =
  when isDef:
    defineSystem(name, componentTypes, defaultSystemOptions)
  else:
    makeSystemBody(name, body)

#create system that listens to an event
template onEvent(isDef: static[bool], T: typedesc, body: untyped) =
  isDef.sys(instantiationInfo().filename[0..^5] & $T & $instantiationInfo().line, [T]):
    added:
      #TODO inject event?
      #let event {.inject.} = item.worldCreate
      body

#TODO (re)move
converter toFloat32(i: int): float32 {.inline.} = i.float32

type Tile* = object
  floor*, wall*, overlay*: Block
  build*: EntityRef
  
registerComponents(defaultComponentOptions):
  type
    Pos* = object
      x, y: float32
    Vel* = object
      x, y, rot: float32
    Solid* = object
      size: float32
    Input* = object
    Draw* = object
    Main* = object
    Dir* = object
      val: range[0..3]
    Building* = object
      #bottom-left corner in tile coordinates
      x: int
      y: int
    
    #buildings

    Conveyor* = object

    #events

    Event* = object
    WorldCreate* = object

    WallChange* = object
      x, y: int
    FloorChange* = object
      x, y: int
    OverlayChange* = object
      x, y: int

const
  zoom = 38.0
  tileSizePx = 8
  shadowColor = rgba(0, 0, 0, 0.2)
  layerFloor = 0
  layerShadow = 10
  layerWall = 20

var 
  shadows = newFramebuffer()
  worldWidth* = 32
  worldHeight* = 32
  tiles*: seq[Tile]

template makeAllSystems(state: static[bool]) =

  #clear events at start of loop.
  state.sys("clearEvents", [Event]):
    all:
      item.entity.delete()

  state.sys("controlled", [Input, Pos, Vel]):
    all:
      let v = vec2(axis(keyA, keyD), axis(KeyCode.keyS, keyW)).lim(1) * 10 * fuse.delta
      item.vel.x += v.x
      item.vel.y += v.y

  state.sys("rotate", [Pos, Vel]):
    all:
      if len2(item.vel.x, item.vel.y) >= 0.01:
        item.vel.rot = item.vel.rot.aapproach(vec2(item.vel.x, item.vel.y).angle().radToDeg, 360.0 * fuse.delta)

  state.sys("moveSolid", [Pos, Vel, Solid]):
    all:
      let deltax = moveDelta(item.pos.x, item.pos.y, item.solid.size, item.solid.size, item.vel.x, 0, true, 2, proc(x, y: int): bool = solid(x, y)) #TODO
      item.pos.x += deltax.x
      item.pos.y += deltax.y
      let deltay = moveDelta(item.pos.x, item.pos.y, item.solid.size, item.solid.size, 0, item.vel.y, false, 2, proc(x, y: int): bool = solid(x, y))
      item.pos.x += deltay.x
      item.pos.y += deltay.y

      item.vel.x = 0
      item.vel.y = 0

  state.sys("followCam", [Pos, Input]):
    all:
      fuse.cam.pos = vec2(item.pos.x, item.pos.y)

  state.sys("main", [Main]):
    
    init:
      generateWorld(128, 128)
      fireEvent(WorldCreate())

      discard newEntityWith(Input(), Pos(x: worldWidth/2, y: worldHeight/2), Vel(), Solid(size: 0.5), Draw())

      fuse.pixelScl = 1.0 / tileSizePx
      #TODO move
      loadContent()

    start:
      if keyEscape.tapped: quitApp()

      fuse.cam.resize(fuse.widthf / zoom, fuse.heightf / zoom)
      fuse.cam.use()
      shadows.resize(fuse.width, fuse.height)

      if keyMouseLeft.down or keyMouseRight.down:
        let
          tx = mouseWorld().x.toTile
          ty = mouseWorld().y.toTile

        setWall(tx, ty, if keyMouseRight.down: blockAir else: blockStoneWall)
        tileChanged(tx, ty)

      draw(layerFloor, proc() =
        drawFloor()

        shadows.inside:
          drawShadows()
        shadows.blit(color = shadowColor)

        drawWalls()
      )

  state.sys("draw", [Draw, Pos, Vel]):
    all:
      draw("dagger".patch, item.pos.x, item.pos.y, layerWall + 1, rotation = item.vel.rot - 90)

  state.sys("drawConveyor", [Conveyor, Pos, Dir]):
    all:
      draw("conveyor".patch, item.pos.x, item.pos.y, layerWall + 1, rotation = item.dir.val * 90)

  state.onEvent(WorldCreate):
    echo "world loaded"

makeAllSystems(true)
makeEcs()

#TODO move?
proc inWorld*(x, y: int): bool {.inline.} = x < worldWidth and y < worldHeight and x >= 0 and y >= 0

proc tile*(x, y: int): Tile =
  if not inWorld(x, y): Tile(floor: blockGrass, wall: blockStoneWall, overlay: blockAir) else: tiles[x + y*worldWidth]

proc setWall*(x, y: int, b: Block) =
  if inWorld(x, y): 
    tiles[x + y*worldWidth].wall = b
    #fireEvent(WallChange(x, y))

proc toTile*(c: float32): int {.inline.} = (c + 0.5).int

proc solid*(x, y: int): bool = tile(x, y).wall.solid

import render
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

makeAllSystems(false)
commitSystems("run")
initFuse(run, windowTitle = "Nimdustry")
