import std/[macros, tables]

macro grabField*(typ: untyped, name: static[string]): untyped =
  return nnkDotExpr.newTree(typ, ident(name))

proc extractFieldsAux(node: NimNode, values: var OrderedTable[string, NimNode]) =
  case node.kind
  of nnkRecList:
    for child in node:
      child.extractFieldsAux(values)
  of nnkIdentDefs:
    values[node[0].strVal] = node[^2]
  of nnkRecCase:
    # Discriminat is also a field
    node[0].extractFieldsAux(values)

    for i in 1 ..< node.len:
      node[i][^1].extractFieldsAux(values)
  else:
    discard

proc extractFields*(obj: NimNode): OrderedTable[string, NimNode] =
  ## Extracts the fields -> types of an object.
  let recList = obj[2]
  obj[2].extractFieldsAux(result)
