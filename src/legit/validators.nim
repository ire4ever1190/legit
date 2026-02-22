## Built in validators

import std/[sugar, options, strformat, tables]

import ./[base, utils]

proc validator*[T](check: T -> bool, msg: T -> string): Validator[T] =
  ## Validator where `check` must hold true or `msg` is produced.
  ## The message producer is given the invalid object to add more context
  proc handler(value: T): Option[ValidationResult] =
    if not check(value): some(initValidationResult(msg(value)))
    else: none(ValidationResult)
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

  return validator[string](x => x.len >= len, x => fmt"Length must be atleast {len}, got {x.len}")

proc validators*[T: object](obj: typedesc[T], validators: tuple): Validator[T] =
  ## Add validation to an object. You specify a tuple containing each field to validate.
  runnableExamples:
    type
      Person = object
        name: string

    let valid = Person.validators((
      name: @[minLength(6)]
    ))

  proc validate(input: T): Option[ValidationResult] =
    var errors: Table[string, ValidationResult]
    for field, value in validators.fieldPairs:
      # Type check the validator
      let validators: seq[Validator[grabField(obj, field)]] = value
      for validator in validators:
        let res = validator.validate(grabField(input, field))
        if res.isSome:
          errors[field] = res.get()
          break # We only return the first error for a field

    if errors.len > 0:
      return some(initValidationResult(errors))
  return Validator[T](validate: validate)

export base
