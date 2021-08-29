import tables, math, random, common, sequtils, world, worldmesh, quadtree

defineEffects:
  blockPlace(lifetime = 0.1f):
    lineSquare(e.pos, e.rotation/2f + 4.px * e.fin, stroke = 2f.px * e.fout, color = e.color, z = layerEffect)

#prevent nil patch
DrawPatch.onAdd:
  if curComponent.patch.texture.isNil:
    curComponent.patch = "error".patch

type QuadRef = object
  entity: EntityRef
  bounds: Rect

proc boundingBox(r: QuadRef): Rect {.inline.} = r.bounds

sysMake("staticClip", [StaticClip]):
  fields:
    tree: Quadtree[QuadRef]
    cseq: seq[QuadRef]
  init:
    #TODO resize on world resize!
    sys.tree = newQuadtree[QuadRef](rect(-0.5f, -0.5f, 128, 128))
  added:
    sys.tree.insert(QuadRef(bounds: item.staticClip.rect, entity: item.entity))
  removed:
    sys.tree.remove(QuadRef(bounds: item.staticClip.rect, entity: item.entity))
  start:
    sys.cseq.setLen 0
    sys.tree.intersect(fau.cam.viewport, sys.cseq)
    for child in sys.cseq:
      child.entity.addOrUpdate Onscreen(frame: fau.frameId)

onWorldCreate:
  sysStaticClip.tree = newQuadtree[QuadRef](rect(-1f, -1f, worldWidth + 2, worldHeight + 2))

#remove entities that are no longer on-screen
sysMake("checkOnscreen", [Onscreen]):
  all: #TODO considering streaming
    if item.onscreen.frame != fau.frameId:
      item.entity.remove Onscreen

sys("followCam", [Pos, Input]):
  all:
    fau.cam.pos = vec2(item.pos.x, item.pos.y)
    fau.cam.pos += vec2((fau.widthf mod pixelation) / pixelation, (fau.heightf mod pixelation) / pixelation) * fau.pixelScl

sys("draw", [Main]):
  fields:
    shadows: Framebuffer
    buffer: Framebuffer
  
  init:
    sys.shadows = newFramebuffer()
    sys.buffer = newFramebuffer()
    
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

    let
      shadows = sys.shadows
      buffer = sys.buffer
      bw = fau.width div pixelation
      bh = fau.height div pixelation
    shadows.resize(bw, bh)
    buffer.resize(bw, bh)

    buffer.push(colorClear)

    draw(1000, proc() =
      buffer.pop()
      buffer.blit()
    )

    draw(layerFloor, proc() =
      drawFloor()

      shadows.inside(colorClear):
        drawShadows()
      shadows.blit(color = shadowColor)

      drawWalls()
    )

sys("drawUnits", [DrawUnit, Pos, Vel]):
  all:
    draw(item.drawUnit.unit.name.patch, item.pos.vec2, z = layerWall + 2, rotation = item.vel.rot - 90.rad)

sys("drawConveyor", [Conveyor, Pos, Dir, Onscreen]):
  all:
    draw(patch("conveyor-0-" & $((fau.time * 15.0).int mod 4)), item.pos.vec2, z = layerWall + 1, rotation = item.dir.val.float32 * 90.rad)

sys("drawDrill", [DrawDrill, Pos, Onscreen, Building]):
  all:
    let name = item.building.kind.name
    draw(name.patch, item.pos.vec2, z = layerWall + 1)
    draw((name & "Rotator").patch, item.pos.vec2, rotation = fau.time * 2f, z = layerWall + 1)
    draw((name & "Top").patch, item.pos.vec2, z = layerWall + 1)

sys("drawPatch", [DrawPatch, Pos, Vel, Onscreen]):
  all:
    draw(item.drawPatch.patch, item.pos.vec2, rotation = item.vel.rot)

makeEffectsSystem()
