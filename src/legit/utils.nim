import std/macros

macro grabField*(typ: untyped, name: static[string]): untyped =
  return nnkDotExpr.newTree(typ, ident(name))
