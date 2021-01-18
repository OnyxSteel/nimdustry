import tables, math, random, common, sequtils, world, render

#pack sprites on launch
static: echo staticExec("faupack -p:../assets-raw/sprites -o:../assets/atlas")

sys("init", [Main]):
  init:
    initContent()
    generateWorld(128, 128)

    makeUnit(unitDagger, worldWidth/2, worldHeight/2).addComponent Input()
    discard makeUnit(unitCrawler, worldWidth/2 - 4, worldHeight/2 - 2)
    fau.pixelScl = 1.0 / tileSizePx

sys("control", [Input, Pos, Vel]):
  all:
    let v = vec2(axis(keyA, keyD).float32, axis(KeyCode.keyS, keyW).float32).lim(1) * 10 * fau.delta
    item.vel.x += v.x
    item.vel.y += v.y

sys("rotate", [Pos, Vel]):
  all:
    if len2(item.vel.x, item.vel.y) >= 0.01:
      item.vel.rot = item.vel.rot.aapproach(vec2(item.vel.x, item.vel.y).angle().radToDeg, 360.0 * fau.delta)

sys("moveSolid", [Pos, Vel, Solid]):
  all:
    let delta = moveDelta(rectCenter(item.pos.x, item.pos.y, item.solid.size), item.vel.x, item.vel.y, proc(x, y: int): bool = solid(x, y))
    item.pos.x += delta.x
    item.pos.y += delta.y

    item.vel.x = 0
    item.vel.y = 0

sys("followCam", [Pos, Input]):
  all:
    fau.cam.pos = vec2(item.pos.x, item.pos.y)

sys("draw", [Main]):
  vars:
    shadows: Framebuffer
    dir: int
  
  init:
    sys.shadows = newFramebuffer()
    
    #load all block textures before rendering
    for b in blockList:
      var maxFound = 0
      for i in 1..10:
        if not fau.atlas.patches.hasKey(b.name & $i): break
        maxFound = i
      
      if maxFound == 0:
        if fau.atlas.patches.hasKey(b.name):
          b.patches = @[b.name.patch]
      else:
        b.patches = (1..maxFound).toSeq().mapIt((b.name & $it).patch)

  start:
    if keyEscape.tapped: quitApp()

    fau.cam.resize(fau.widthf / zoom, fau.heightf / zoom)
    fau.cam.use()

    let shadows = sys.shadows
    shadows.resize(fau.width, fau.height)
    if fau.scrollY != 0:
      sys.dir += sign(fau.scrollY).int
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

sys("drawUnits", [DrawUnit, Pos, Vel]):
  all:
    draw(item.drawUnit.unit.name.patch, item.pos.x, item.pos.y, layerWall + 2, rotation = item.vel.rot - 90)

sys("drawConveyor", [Conveyor, Pos, Dir]):
  all:
    draw(patch("conveyor-0-" & $((fau.time * 15.0).int mod 4)), item.pos.x, item.pos.y, layerWall + 1, rotation = item.dir.val.float32 * 90)

onWorldCreate:
  echo "World created: " & $worldWidth & " x " & $worldHeight

launchFau("Nimdustry")
