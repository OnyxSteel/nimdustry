import common, polymorph, content, tables, math, random, strformat, world

const 
  zoom = 38.0
  tileSizePx = 8
  shadowColor = rgba(0, 0, 0, 0.2)
  layerFloor = 0
  layerShadow = 10
  layerWall = 20

iterator eachTile(): tuple[x, y: int, tile: Tile] =
  let 
    xrange = (fuse.cam.w / 2).ceil.int + 1
    yrange = (fuse.cam.h / 2).ceil.int + 1
    camx = fuse.cam.pos.x.ceil.int
    camy = fuse.cam.pos.y.ceil.int

  for cx in -xrange..xrange:
    for cy in -yrange..yrange:
      let 
        wcx = camx + cx
        wcy = camy + cy
      
      yield (wcx, wcy, tile(wcx, wcy))

#TODO (re)move
converter toFloat32(i: int): float32 {.inline.} = i.float32 

var shadows = newFramebuffer()

generateWorld(32, 32)

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

makeSystem("controlled", [Input, Pos, Vel]):
  all:
    let v = vec2(axis(keyA, keyD), axis(KeyCode.keyS, keyW)).lim(1) * 15 * fuse.delta
    item.vel.x += v.x
    item.vel.y += v.y

makeSystem("rotate", [Pos, Vel]):
  all:
    if len2(item.vel.x, item.vel.y) >= 0.01:
      item.vel.rot = item.vel.rot.aapproach(vec2(item.vel.x, item.vel.y).angle().radToDeg, 360.0 * fuse.delta)

makeSystem("moveSolid", [Pos, Vel, Solid]):
  all:
    let deltax = moveDelta(item.pos.x, item.pos.y, item.solid.size, item.solid.size, item.vel.x, 0, true, 2, proc(x, y: int): bool = solid(x, y)) #TODO
    item.pos.x += deltax.x
    item.pos.y += deltax.y
    let deltay = moveDelta(item.pos.x, item.pos.y, item.solid.size, item.solid.size, 0, item.vel.y, false, 2, proc(x, y: int): bool = solid(x, y))
    item.pos.x += deltay.x
    item.pos.y += deltay.y

    item.vel.x = 0
    item.vel.y = 0

makeSystem("followCam", [Pos, Input]):
  all:
    fuse.cam.pos = vec2(item.pos.x, item.pos.y)

makeSystem("main", [Main]):

  init:
    fuse.pixelScl = 1.0 / tileSizePx

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

    drawLayer(layerShadow, proc() = shadows.start(colorClear), proc() =
      shadows.stop()
      shadows.blit(color = shadowColor)
    )

    for x, y, t in eachTile():
      draw(t.floor.name, x, y, layerFloor)
      if t.wall.id != 0:
        draw("wallshadow", x, y, layerShadow)

        let reg: Patch = t.wall.name
        draw(reg, x, y, layerWall)

makeSystem("draw", [Draw, Pos, Vel]):
  all:
    draw("dagger", item.pos.x, item.pos.y, layerWall + 1, rotation = item.vel.rot - 90)

makeEcs()
commitSystems("run")

discard newEntityWith(Main())
discard newEntityWith(Input(), Pos(x: 16, y: 16), Vel(), Solid(size: 0.5), Draw())

initFuse(run, windowTitle = "Nimdustry")