import content, tables, math, random, common

#general design:
#- all global types/state stored in common
#- all systems are stored in separate files
#

#pack sprites on launch
static:
  echo staticExec("fusepack -p:../assets-raw/sprites -o:../assets/atlas")

sys("controlled", [Input, Pos, Vel]):
  all:
    let v = vec2(axis(keyA, keyD).float32, axis(KeyCode.keyS, keyW).float32).lim(1) * 10 * fuse.delta
    item.vel.x += v.x
    item.vel.y += v.y

sys("rotate", [Pos, Vel]):
  all:
    if len2(item.vel.x, item.vel.y) >= 0.01:
      item.vel.rot = item.vel.rot.aapproach(vec2(item.vel.x, item.vel.y).angle().radToDeg, 360.0 * fuse.delta)

sys("moveSolid", [Pos, Vel, Solid]):
  all:
    let deltax = moveDelta(item.pos.x, item.pos.y, item.solid.size, item.solid.size, item.vel.x, 0, true, 2, proc(x, y: int): bool = solid(x, y)) #TODO
    item.pos.x += deltax.x
    item.pos.y += deltax.y
    let deltay = moveDelta(item.pos.x, item.pos.y, item.solid.size, item.solid.size, 0, item.vel.y, false, 2, proc(x, y: int): bool = solid(x, y))
    item.pos.x += deltay.x
    item.pos.y += deltay.y

    item.vel.x = 0
    item.vel.y = 0

sys("followCam", [Pos, Input]):
  all:
    fuse.cam.pos = vec2(item.pos.x, item.pos.y)

sys("main", [Main]):
  
  init:
    generateWorld(128, 128)

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

    draw(layerFloor, proc() =
      drawFloor()

      shadows.inside:
        drawShadows()
      shadows.blit(color = shadowColor)

      drawWalls()
    )

sys("draw", [Draw, Pos, Vel]):
  all:
    draw("dagger".patch, item.pos.x, item.pos.y, layerWall + 1, rotation = item.vel.rot - 90)

sys("drawConveyor", [Conveyor, Pos, Dir]):
  all:
    draw("conveyor".patch, item.pos.x, item.pos.y, layerWall + 1, rotation = item.dir.val.float32 * 90)

onEvent(WallChange): 
  updateMesh(event.x, event.y)

  let t = tile(event.x, event.y)

  if t.build != NoEntityRef:
    t.build.delete()
  
  if t.wall.building:
    discard


onEvent(FloorChange): updateMesh(event.x, event.y)
onEvent(OverlayChange): updateMesh(event.x, event.y)

onEvent(WorldCreate):
  echo "World created: " & $worldWidth & " x " & $worldHeight

launchFuse("Nimdustry"):
  include content, world, render
