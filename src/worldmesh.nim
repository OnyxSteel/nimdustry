import math, common, world

const 
  chunkSize = 40
  spriteSize = (2 + 2) * 4 #pos + uv
  layerSize = chunkSize * chunkSize * spriteSize

var 
  chunks: seq[Mesh]
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
    attribute vec4 a_position;
    attribute vec2 a_texc;
    uniform mat4 u_proj;
    varying vec2 v_texc;
    void main(){
      v_texc = a_texc;
      gl_Position = u_proj * a_position;
    }
    """,

    """
    varying vec2 v_texc;
    uniform sampler2D u_texture;
    void main(){
      gl_FragColor = texture2D(u_texture, v_texc);
    }
    """
    )
  
  chunksX = (worldWidth / chunkSize).ceil.int
  chunksY = (worldHeight / chunkSize).ceil.int

  chunks = newSeq[Mesh](chunksX * chunksY)

proc getMesh(cx, cy: int): Mesh = chunks[cx + cy * chunksX]

proc spriteRotTODO(mesh: Mesh, region: Patch, idx: int, x, y, width, height: float32, rotation = 0f) =
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

  verts.minsert(idx, [x1, y1, u, v, x2, y2, u, v2, x3, y3, u2, v2, x4, y4, u2, v])
  mesh.updateVertices(idx..<(idx+spriteSize))

proc sprite(mesh: Mesh, region: Patch, idx: int, x, y, width, height: float32) =
  let
    x2 = width + x
    y2 = height + y
    verts = addr mesh.vertices

  verts.minsert(idx, [x, y, region.u, region.v2, x, y2, region.u, region.v, x2, y2, region.u2, region.v, x2, y, region.u2, region.v2])
  mesh.updateVertices(idx..<(idx+spriteSize))

proc clearSprite(mesh: Mesh, idx: int) =
  zeroMem(addr mesh.vertices[idx], spriteSize * 4)
  mesh.updateVertices(idx..<(idx+spriteSize))

#TODO inline maybe
proc updateSprite(mesh: Mesh, tile: Tile, x, y, index: int) =
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
      
      updateSprite(mesh, t, x, y, (cx + cy*chunkSize) * spriteSize)

proc cacheChunk(cx, cy: int) =
  let
    size = chunkSize * chunkSize * (1 + ChunkLayer.high.int)
    len = size * 6
    wx = cx * chunkSize
    wy = cy * chunkSize
  var 
    j = 0
    i = 0

  var mesh = newMesh(
    @[attribPos, attribTexCoords],
    vertices = newSeq[Glfloat](size * spriteSize),
    indices = newSeq[Glushort](size * 6)
  )

  chunks[cx + cy*chunksX] = mesh

  let indices = addr mesh.indices
  
  while i < len:
    indices.minsert(i, [j.GLushort, (j+1).GLushort, (j+2).GLushort, (j+2).GLushort, (j+3).GLushort, (j).GLushort])
    i += 6
    j += 4
  
  for index in 0..<(chunkSize * chunkSize):
    let 
      x = index mod chunkSize + wx
      y = index div chunkSize + wy
      t = tile(x, y)

    if x < worldWidth and y < worldHeight:
      updateSprite(mesh, t, x, y, index * spriteSize)

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