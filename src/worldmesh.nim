import math, common, world

const 
  chunkSize = 40
  layerSize = chunkSize * chunkSize * 4

type CMesh = Mesh[SVert2]

var 
  chunks: seq[CMesh]
  chunksX: int
  chunksY: int
  chunkShader: Shader

type ChunkLayer = enum
  clFloor
  clFloorBlend
  clOverlay
  clWall
  clWallShadow

proc initChunks*() =
  if chunkShader.isNil:
    chunkShader = newShader(
    """
    attribute vec4 a_pos;
    attribute vec2 a_uv;
    uniform mat4 u_proj;
    varying vec2 v_uv;
    void main(){
      v_uv = a_uv;
      gl_Position = u_proj * a_pos;
    }
    """,

    """
    varying vec2 v_uv;
    uniform sampler2D u_texture;
    void main(){
      gl_FragColor = texture2D(u_texture, v_uv);
    }
    """
    )
  
  chunksX = (worldWidth / chunkSize).ceil.int
  chunksY = (worldHeight / chunkSize).ceil.int

  chunks = newSeq[CMesh](chunksX * chunksY)

proc getMesh(cx, cy: int): CMesh = chunks[cx + cy * chunksX]

proc spriteRotTODO(mesh: CMesh, region: Patch, idx: int, x, y, width, height: float32, rotation = 0f) =
  let
    originX = width/2
    originY = height/2
    worldOriginX = x + originX
    worldOriginY = y + originY
    fx = -originX
    fy = -originY
    fx2 = width - originX
    fy2 = height - originY
    #rotate? or maybe don't, because it's inefficient!
    cos = cos(rotation.degToRad)
    sin = sin(rotation.degToRad)
    x1 = cos * fx - sin * fy + worldOriginX
    y1 = sin * fx + cos * fy + worldOriginY
    x2 = cos * fx - sin * fy2 + worldOriginX
    y2 = sin * fx + cos * fy2 + worldOriginY
    x3 = cos * fx2 - sin * fy2 + worldOriginX
    y3 = sin * fx2 + cos * fy2 + worldOriginY
    x4 = x1 + (x3 - x2)
    y4 = y3 - (y2 - y1)
    u = region.u
    v = region.v2
    u2 = region.u2
    v2 = region.v
    verts = addr mesh.vertices

  verts.minsert(idx, [svert2(x1, y1, u, v), svert2(x2, y2, u, v2), svert2(x3, y3, u2, v2), svert2(x4, y4, u2, v)])
  mesh.updateVertices(idx..<(idx+4))

proc sprite(mesh: CMesh, region: Patch, idx: int, x, y, width, height: float32) =
  let
    x2 = width + x
    y2 = height + y
    verts = addr mesh.vertices

  verts.minsert(idx, [svert2(x, y, region.u, region.v2), svert2(x, y2, region.u, region.v), svert2(x2, y2, region.u2, region.v), svert2(x2, y, region.u2, region.v2)])
  mesh.updateVertices(idx..<(idx+4))

proc clearSprite(mesh: CMesh, idx: int) =
  zeroMem(addr mesh.vertices[idx], SVert2.sizeOf * 4)
  mesh.updateVertices(idx..<(idx+4))

#TODO inline maybe
proc updateSprite(mesh: CMesh, tile: Tile, x, y, index: int) =
  let 
    floor = tile.floor
    over = tile.overlay
    wall = tile.wall
    r = hashInt(x + y * worldWidth)
  
  if floor.patches.len != 0:
    sprite(mesh, floor.patches[r mod floor.patches.len], index, x.float32 - 0.5f, y.float32 - 0.5f, 1.0, 1.0)

  if over.patches.len != 0:
    sprite(mesh, over.patches[r mod over.patches.len], index + layerSize * clOverlay.int, x.float32 - 0.5f, y.float32 - 0.5f, 1.0, 1.0)
  else:
    clearSprite(mesh, index + layerSize * clOverlay.int)
  
  if wall.patches.len != 0 or tile.build != NoEntityRef:
    sprite(mesh, "wallshadow".patch, index + layerSize * clWallShadow.int, x.float32 - 0.5f - 1.px, y.float32 - 0.5f - 1.px, 1.0 + 2.px, 1.0 + 2.px)
  else:
    clearSprite(mesh, index + layerSize * clWallShadow.int)

  if wall.patches.len != 0 and tile.build == NoEntityRef:
    sprite(mesh, wall.patches[r mod wall.patches.len], index + layerSize * clWall.int, x.float32 - 0.5f, y.float32 - 0.5f, 1.0, 1.0)
  else:
    clearSprite(mesh, index + layerSize * clWall.int)
    
proc updateMesh*(x, y: int) =
  if inWorld(x, y):
    let 
      mesh = getMesh(x div chunkSize, y div chunkSize)
      t = tile(x, y)

    if t.build != NoEntityRef: discard
      #t.build.deleted

    if not mesh.isNil:
      let 
        cx = x mod chunkSize
        cy = y mod chunkSize
      
      updateSprite(mesh, t, x, y, (cx + cy*chunkSize) * 4)

proc cacheChunk(cx, cy: int) =
  let
    size = chunkSize * chunkSize * (1 + ChunkLayer.high.int)
    len = size * 6
    wx = cx * chunkSize
    wy = cy * chunkSize
  var 
    j = 0
    i = 0

  var mesh = newMesh[SVert2](
    vertices = newSeq[SVert2](size * 4),
    indices = newSeq[Index](size * 6)
  )

  chunks[cx + cy*chunksX] = mesh

  let indices = addr mesh.indices
  
  while i < len:
    indices.minsert(i, [j.Index, (j+1).Index, (j+2).Index, (j+2).Index, (j+3).Index, (j).Index])
    i += 6
    j += 4
  
  for index in 0..<(chunkSize * chunkSize):
    let 
      x = index mod chunkSize + wx
      y = index div chunkSize + wy
      t = tile(x, y)

    if x < worldWidth and y < worldHeight:
      updateSprite(mesh, t, x, y, index * 4)

proc drawChunks(layerFrom, layerTo: ChunkLayer) =

  #flush any remaining things in the batch
  drawFlush()
  #bind main texture
  fau.atlas.texture.use()
  
  if chunks.len == 0:
    initChunks()

  chunkShader.use()
  chunkShader.setmat4("u_proj", fau.cam.mat)

  let 
    minx = ((fau.cam.pos.x - fau.cam.width/2) / chunkSize).floor.int
    miny = ((fau.cam.pos.y - fau.cam.height/2) / chunkSize).floor.int
    maxx = ((fau.cam.pos.x + fau.cam.width/2) / chunkSize).ceil.int
    maxy = ((fau.cam.pos.y + fau.cam.height/2) / chunkSize).ceil.int
  
  for cx in minx..maxx:
    for cy in miny..maxy:
      if cx < 0 or cy < 0 or cx >= chunksX or cy >= chunksY: continue

      if getMesh(cx, cy).isNil: cacheChunk(cx, cy)
      
      getMesh(cx, cy).render(chunkShader, layerFrom.int * chunkSize * chunkSize * 6, (layerTo.int - layerFrom.int + 1) * 6 * chunkSize * chunkSize)

proc drawFloor*() =
  drawChunks(clFloor, clOverlay)

proc drawShadows*() =
  drawChunks(clWallShadow, clWallShadow)

proc drawWalls*() =
  drawChunks(clWall, clWall)

onWallChange: updateMesh(event.x, event.y)
onFloorChange: updateMesh(event.x, event.y)
onOverlayChange: updateMesh(event.x, event.y)