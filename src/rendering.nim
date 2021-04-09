import tables, math, random, common, sequtils, world, worldmesh

#prevent nil patch
DrawPatch.onAdd:
  if curComponent.patch.texture.isNil:
    curComponent.patch = "error".patch

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
        t.build.fetch(Dir).val = sys.dir

    draw(layerFloor, proc() =
      drawFloor()

      shadows.inside:
        drawShadows()
      shadows.blit(color = shadowColor)

      drawWalls()
    )

sys("drawUnits", [DrawUnit, Pos, Vel]):
  all:
    draw(item.drawUnit.unit.name.patch, item.pos.x, item.pos.y, layerWall + 2, rotation = item.vel.rot - 90.rad)

sys("drawConveyor", [Conveyor, Pos, Dir]):
  all:
    draw(patch("conveyor-0-" & $((fau.time * 15.0).int mod 4)), item.pos.x, item.pos.y, layerWall + 1, rotation = item.dir.val.float32 * 90.rad)

sys("drawPatch", [DrawPatch, Pos, Vel]):
  all:
    draw(item.drawPatch.patch, item.pos.x, item.pos.y, rotation = item.vel.rot)

