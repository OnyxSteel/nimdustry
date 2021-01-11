import macros, strutils, tables, sequtils

#TODO remove this module..?

#macro that creates definition for a list of objects.
macro initContent*(body: untyped): untyped =
  result = newStmtList()
  
  var 
    letSec = newNimNode(nnkLetSection)
    id = 0
  
  result.add letSec

  for n in body:
    if n.kind == nnkAsgn:
      var 
        nameIdent = $n[0] #name of content
        consn = n[1] #object constructor call
        typeName = $consn[0] #e.g. "Block"
      
      #switch empty calls to constructors
      if consn.kind == nnkCall:
        consn = newNimNode(nnkObjConstr).add(ident(typeName))
      
      #assign ID
      consn.add(newNimNode(nnkExprColonExpr).add(ident("id")).add(newIntLitNode(id)))
      #assign name
      consn.add(newNimNode(nnkExprColonExpr).add(ident("name")).add(newStrLitNode(nameIdent)))
      #e.g. Block + ice = blockIce
      let resName = typeName.toLowerAscii & nameIdent.capitalizeAscii
      #declare the var
      letSec.add newIdentDefs(postfix(ident(resName), "*"), newEmptyNode(), consn)
      #add to list
      result.add newCall(newDotExpr(ident("contentList"), ident("add")), ident(resName))
      #add to other list
      result.add newCall(newDotExpr(ident(typeName.toLowerAscii & "List"), ident("add")), ident(resName))
      inc id

import common

proc loadContent*() =
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
