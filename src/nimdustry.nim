import tables, math, random, common, sequtils, world, render

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

sys("draw", [Main]):
  vars:
    shadows: Framebuffer
    dir: int
  
  init:
    #load all content
    initContent()

    #TODO move initialization out of draw system, it's not relevant
    generateWorld(128, 128)
    discard newEntityWith(Input(), Pos(x: worldWidth/2, y: worldHeight/2), Vel(), Solid(size: 0.5), Draw())

    sys.shadows = newFramebuffer()
    fuse.pixelScl = 1.0 / tileSizePx
    
    #load all block textures before rendering
    for b in blockList:
      var maxFound = 0
      for i in 1..10:
        if not fuse.atlas.patches.hasKey(b.name & $i): break
        maxFound = i
      
      if maxFound == 0:
        if fuse.atlas.patches.hasKey(b.name):
          b.patches = @[b.name.patch]
      else:
        b.patches = (1..maxFound).toSeq().mapIt((b.name & $it).patch)

  start:
    if keyEscape.tapped: quitApp()

    fuse.cam.resize(fuse.widthf / zoom, fuse.heightf / zoom)
    fuse.cam.use()

    let shadows = sys.shadows
    shadows.resize(fuse.width, fuse.height)
    if fuse.scrollY != 0:
      sys.dir += sign(fuse.scrollY).int
      sys.dir = sys.dir.emod(4)

    if keyMouseLeft.down or keyMouseRight.down:
      let
        tx = mouseWorld().x.toTile
        ty = mouseWorld().y.toTile

      setWall(tx, ty, if keyMouseRight.down: blockAir else: blockConveyor)
      let t = tile(tx, ty)
      if t.wall == blockConveyor:
        var dir = t.build.fetchComponent Dir
        dir.val = sys.dir

    draw(layerFloor, proc() =
      drawFloor()

      shadows.inside:
        drawShadows()
      shadows.blit(color = shadowColor)

      drawWalls()
    )

sys("drawDagger", [Draw, Pos, Vel]):
  all:
    draw("dagger".patch, item.pos.x, item.pos.y, layerWall + 2, rotation = item.vel.rot - 90)

sys("drawConveyor", [Conveyor, Pos, Dir]):
  all:
    draw(patch("conveyor-0-" & $((fuse.time * 15.0).int mod 4)), item.pos.x, item.pos.y, layerWall + 1, rotation = item.dir.val.float32 * 90)

onWallChange: 
  updateMesh(event.x, event.y)

  let t = tile(event.x, event.y)

  if t.build != NoEntityRef:
    t.build.delete()
    setBuild(event.x, event.y, NoEntityRef)
  
  if not t.wall.building.isNil:
    let build = t.wall.building()
    build.addComponent Building(x: event.x, y: event.y)
    build.addComponent Pos(x: event.x.float32, y: event.y.float32)
    setBuild(event.x, event.y, build)

onFloorChange: updateMesh(event.x, event.y)
onOverlayChange: updateMesh(event.x, event.y)

onWorldCreate:
  echo "World created: " & $worldWidth & " x " & $worldHeight

launchFuse("Nimdustry")
