import common, polymorph, content, tables, math, random, strformat, world, render

const 
  zoom = 38.0
  tileSizePx = 8
  shadowColor = rgba(0, 0, 0, 0.2)
  layerFloor = 0
  layerShadow = 10
  layerWall = 20

#pack sprites on launch
static:
  echo staticExec("fusepack -p:../assets-raw/sprites -o:../assets/atlas")

#TODO (re)move
converter toFloat32(i: int): float32 {.inline.} = i.float32 

var shadows = newFramebuffer()

generateWorld(128, 128)

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
    Direction = object
      dir: range[0..3]

makeSystem("controlled", [Input, Pos, Vel]):
  all:
    let v = vec2(axis(keyA, keyD), axis(KeyCode.keyS, keyW)).lim(1) * 10 * fuse.delta
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
    var m = newScreenMesh()

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

      shadows.start(colorClear)
      drawShadows()
      shadows.stop()
      shadows.blit(color = shadowColor)

      drawWalls()
    )

makeSystem("draw", [Draw, Pos, Vel]):
  all:
    draw("dagger", item.pos.x, item.pos.y, layerWall + 1, rotation = item.vel.rot - 90)

makeEcs()
commitSystems("run")

discard newEntityWith(Main())
discard newEntityWith(Input(), Pos(x: worldWidth/2, y: worldHeight/2), Vel(), Solid(size: 0.5), Draw())

initFuse(run, windowTitle = "Nimdustry")