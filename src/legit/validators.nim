## Built in validators

import std/[sugar, options, strformat, tables, macros, typetraits]

import ./[base, utils]

import pkg/libdump/macros

proc validator*[T](check: T -> bool, msg: T -> string): Validator[T] =
  ## Validator where `check` must hold true or `msg` is produced.
  ## The message producer is given the invalid object to add more context
  runnableExamples:
    import std/[sugar, strformat]
    let alwaysFoo = validator[string](val => val == "foo", val => fmt"Expected 'foo', got '{val}'")

    assert alwaysFoo.valid("foo")
    assert not alwaysFoo.valid("bar")

  proc handler(value: T): Option[ValidationResult] =
    if not check(value):
      some(initValidationResult(msg(value)))
    else:
      none(ValidationResult)

  return Validator[T](validate: handler)

proc validator*[T](check: T -> bool, msg: string): Validator[T] =
  ## Validator wher `check` must hold true or `msg` is returned.
  runnableExamples:
    import std/sugar
    let neverFoo = validator[string](x => x != "foo", "Value can't be 'foo'")

    assert neverFoo.valid("bar")
    assert not neverFoo.valid("foo")

  return validator(check, x => msg)

proc chain*[T](validators: varargs[Validator[T]]): Validator[T] =
  ## Joins multiple validators together. Exits when the first validation fails
  let validators = @validators
  proc handler(value: T): Option[ValidationResult] =
    for validator in validators:
      let res = validator.validate(value)
      if res.isSome():
        return res

  return Validator[T](validate: handler)

proc minLength*(len: int): Validator[string] =
  ## Checks that a string is of minimum length
  runnableExamples:
    let validator = minLength(5)
    assert validator.valid("Hello")
    assert not validator.valid("Hi")

  return validator[string](
    x => x.len >= len, x => fmt"Length must be atleast {len}, got {x.len}"
  )

proc inRange*[T](rng: Slice[T]): Validator[T] =
  ## Checks that a number is within a certain range
  runnableExamples:
    let validator = inRange(1 .. 10)
    assert validator.valid(5)
    assert not validator.valid(0)

  return validator[T](n => n in rng, n => fmt"{n} is not in the range {rng}")

proc objValidatorImpl[T: object](obj: typedesc[T], fields: tuple): Validator[T] =
  ## Implementation of the object validator which takes in a named tuple
  assert type(fields).isNamedTuple(), "Passed in tuple must contain named fields"

  proc validate(input: T): Option[ValidationResult] =
    var errors: ObjectValidation

    for field, value in fields.fieldPairs:
      # Type check here so we don't get strange errors
      let validators: seq[Validator[grabField(obj, field)]] = value

      for validator in validators:
        let res = validator.validate(grabField(input, field))
        if res.isSome:
          errors[field] = res.get()
          break # We only want the first error to be returned

    if errors.len > 0:
      return some(initValidationResult(errors))

  return Validator[T](validate: validate)

macro validator*(obj: typedesc): proc =
  ## Creates a validator object for an object. You can then construct this type
  ## to add per form
  runnableExamples:
    type Person = object
      name: string

    # You creat ethe validator
    let validator = Person.validator()(name = @[minLength(6)])

    assert not validator.valid Person(name: "")
    assert validator.valid Person(name: "John Smith")

  # Have mapping of every field and its type
  var fields = obj.getObjectDecl().get().extractFields()

  # For each parameter, we pass them into a named tuple
  let tupleConstr = nnkTupleConstr.newTree()

  # Take that mapping, and generate a proc which all those fields as parameters
  # except mapped to Validator[T] and defaulting to `nil`
  let
    body = newStmtList()
    params = nnkFormalParams.newTree(nnkBracketExpr.newTree(ident"Validator", obj))
    prc = nnkProcDef.newTree(
      newEmptyNode(),
      newEmptyNode(),
      newEmptyNode(),
      params,
      newEmptyNode(),
      newEmptyNode(),
      body,
    )
  for name, typ in fields:
    let paramIdent = nskParam.genSym(name)
    params &=
      nnkIdentDefs.newTree(
        paramIdent,
        # We take in a list instead of a single validator (and making user use chain)
        # so that we have a valid 0 value to handle empty fields
        nnkBracketExpr.newTree(
          ident"seq", nnkBracketExpr.newTree(ident"Validator", typ)
        ),
        nnkPrefix.newTree(ident"@", nnkBracket.newTree()),
      )
    tupleConstr &= nnkExprColonExpr.newTree(ident(name), paramIdent)

  body &= newCall(bindSym"objValidatorImpl", obj, tupleConstr)

  # Body of the proc will just pass the values as a tuple to `objValidatorImpl`
  return prc

export base
