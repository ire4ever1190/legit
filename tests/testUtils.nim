import std/[unittest, options, tables, macros]

import legit/utils

import pkg/libdump/macros

suite "Object field extraction":
  macro getFields(obj: typedesc): seq[(string, string)] =
    ## Returns list of fields
    var values: seq[(string, string)]
    for field, typ in obj.getObjectDecl().get().extractFields():
      values &= (field, $typ.toStrLit())
    return newLit values

  type
    Person = object
      firstName, lastName: string
      age: int

    Variant = object
      case idk: bool
      of true:
        a: int
      of false:
        discard

  test "Normal object":
    check getFields(Person) ==
      @{"firstName": "string", "lastName": "string", "age": "int"}

  test "Variant object":
    check getFields(Variant) == @{"idk": "bool", "a": "int"}
