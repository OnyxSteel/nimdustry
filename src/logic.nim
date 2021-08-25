import tables, math, random, common, sequtils, world, worldmesh

sys("init", [Main]):
  init:
    #TODO this is bad design
    initContent()

    generateWorld(128, 128)

    makeUnit(unitDagger, worldWidth/2, worldHeight/2).add Input()
    discard makeUnit(unitCrawler, worldWidth/2 - 4, worldHeight/2 - 2)
    fau.pixelScl = 1.0 / tileSizePx


sys("control", [Input, Pos, Vel]):
  fields:
    dir: int
    curBlock: Block

  init:
    sys.curBlock = blockMechanicalDrill

  all:
    let v = vec2(axis(keyA, keyD).float32, axis(KeyCode.keyS, keyW).float32).lim(1) * 10 * fau.delta
    item.vel.x += v.x
    item.vel.y += v.y

    if fau.scroll.y != 0:
      sys.dir += sign(fau.scroll.y).int
      sys.dir = sys.dir.emod(4)
    
    #delete
    if keyMouseRight.tapped:
      let pos = mouseWorld().toTile

      #TODO canBreak
      if tile(pos).wall != blockAir:
        setWall(pos, blockAir)
        effectBlockPlace(pos.x, pos.y, rot = 1f, col = palRemove)

    #place
    if keyMouseLeft.tapped:
      let pos = toTile(mouseWorld() - sys.curBlock.offset.vec2)

      if canPlace(pos, sys.curBlock):
        setWall(pos, sys.curBlock)

        let t = tile(pos)
        if t.build != NoEntityRef and t.build.has(Dir):
          t.build.fetch(Dir).val = sys.dir
        
        if t.build != NoEntityRef:
          let pos = t.build.fetch(Pos)
          effectBlockPlace(pos.x, pos.y, rot = 1f, col = palAccent)

sys("rotate", [Pos, Vel]):
  all:
    if item.vel.vec2.len2 >= 0.01:
      item.vel.rot = item.vel.rot.aapproach(vec2(item.vel.x, item.vel.y).angle, 360.0.rad * fau.delta)

sys("moveSolid", [Pos, Vel, Solid]):
  all:
    let delta = moveDelta(rectCenter(item.pos.x, item.pos.y, item.solid.size), item.vel.x, item.vel.y, proc(x, y: int): bool = solid(x, y))
    item.pos.x += delta.x
    item.pos.y += delta.y

    item.vel.x = 0
    item.vel.y = 0

sys("input", [Main]):
  start:
     if keyEscape.tapped: quitApp()

makeTimedSystem()

onWorldCreate:
  echo "World created: " & $worldWidth & " x " & $worldHeight