import macros, strutils

#TODO remove this module..?

#macro that creates definition for a list of objects.
macro makeContent*(body: untyped): untyped =
  result = newStmtList()
  
  var 
    letSec = newNimNode(nnkVarSection)
    id = 0
    initProc = quote do:
      template initContent*() =
        discard
    initBody = initProc[6]

  result.add letSec
  result.add initProc

  for n in body:
    if n.kind == nnkAsgn:
      var 
        nameIdent = $n[0] #name of content
        consn = n[1] #object constructor call
        typet = consn[0]
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
      letSec.add newIdentDefs(postfix(ident(resName), "*"), typet, newEmptyNode())
      #construct var
      initBody.add(newAssignment(ident(resName), consn))
      #add to list
      initBody.add newCall(newDotExpr(ident("contentList"), ident("add")), ident(resName))
      #add to other list
      initBody.add newCall(newDotExpr(ident(typeName.toLowerAscii & "List"), ident("add")), ident(resName))
      inc id
