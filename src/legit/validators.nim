## Built in validators

import std/[sugar, options, strformat, tables, macros, typetraits]

import ./[base, utils]

import pkg/libdump/macros

proc validator*[T](check: T -> bool, msg: T -> string): Validator[T] =
  ## Validator where `check` must hold true or `msg` is produced.
  ## The message producer is given the invalid object to add more context
  proc handler(value: T): Option[ValidationResult] =
    if not check(value):
      some(initValidationResult(msg(value)))
    else:
      none(ValidationResult)

  return Validator[T](validate: handler)

proc validator*[T](check: T -> bool, msg: string): Validator[T] =
  ## Validator wher `check` must hold true or `msg` is returned.
  return validator(check, x => msg)

proc minLength*(len: int): Validator[string] =
  ## Checks that a string is of minimum length
  runnableExamples:
    let validator = minLength(5)
    assert validator.valid("Hello")
    assert validator.valid("Hi")

  return validator[string](
    x => x.len >= len, x => fmt"Length must be atleast {len}, got {x.len}"
  )

proc objValidatorImpl*[T: object](obj: typedesc[T], fields: tuple): Validator[T] =
  ## Implementation of the object validator which takes in a named tuple
  assert type(fields).isNamedTuple(), "Passed in tuple must contain named fields"

  proc validate(input: T): Option[ValidationResult] =
    var errors: ObjectValidation

    for field, value in validator.fieldPairs:
      # Type check here so we don't get strange errors
      let validators: seq[Validator[grabField(obj, field)]] = value

      for validator in validators:
        let res = validator.validate(grabField(input, field))
        if res.isSome:
          errors[field] = res.get()
          break # We only want the first error to be returned

    if errors.len > 0:
      return some(initValidationResult(errors))

  return validate

macro validator*(obj: typedesc): proc =
  ## Creates a validator object for an object. You can then construct this type
  ## to add per form
  runnableExamples:
    type Person = object
      name: string

    Person.validator()(name = minLength(6))
    let valid = Person.validators((name: @[minLength(6)]))
  # Have mapping of every field and its type
  var fields: Table[string, NimNode]

  echo obj.getObjectDecl().get().treeRepr

  # Take that mapping, and generate a proc which all those fields as parameters
  # except mapped to Validator[T] and defaulting to `nil`

  # Body of the proc will just pass the values as a tuple to `objValidatorImpl`
  return newLit(1)

export base
