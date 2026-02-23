import ./legit/[validators, base]

export validators, base

## A validation library for Nim
## ==============================
##
## .. importdoc:: legit/validators.nim, legit/utils.nim, legit/base.nim
##
## A [Validator] is a type that validates values of type `T`. It contains a
## `validate` procedure that returns `None` if validation succeeds, or
## [ValidationResult] if validation fails with an error message.
##
### Creating Basic Validators
## ---------------------------
##
## You can create simple validators using the [validator] proc with a check
## function and error message:
##
runnableExamples:
  import std/sugar

  let alwaysFoo = validator[string](
    val => val == "foo", "Value must be 'foo'" # Message shown if validation fails
  )

  assert alwaysFoo.valid("foo")
  assert not alwaysFoo.valid("bar")

## The library provides multiple built-in validators in [validators](legit/validators.html) that can be chained together
## to form complex validators
runnableExamples:
  import std/sugar

  let nameValidator = chain(minLength(2), maxLength(50))

  assert not nameValidator.valid("A")
  assert nameValidator.valid("John")

## Object validators allow you to validate multiple fields within an object type.
##
### Creating an Object Validator
## ----------------------------
##
## Use the macro [validator] on an object type to create a validator builder:
runnableExamples:
  type Person = object
    name: string
    age: int

  let personValidator = Person.validator()(
      name = @[minLength(2), maxLength(50)], age = @[inRange(0 .. 120)]
    )

  assert not personValidator.valid Person(name: "A", age: 25)
  assert not personValidator.valid Person(name: "John", age: 150)
  assert personValidator.valid Person(name: "John", age: 25)

## Each field accepts a sequence of validators. If a sequence is empty (or omitted),
## that field is not validated.
##
## Use [valid] to check if validation passes. If you need detailed error messages then call the `validate` function:
runnableExamples:
  import std/options
  type Person = object
    name: string
    age: int

  let personValidator = Person.validator()(name = @[minLength(2)])

  let res = personValidator.validate(Person(name: "A", age: 25))

  if res.isSome:
    echo res

## Validators can be combined recursively for nested object structures:
runnableExamples:
  type Address = object
    street: string
    city: string

  type User = object
    name: string
    address: Address

  let addressValidator = Address.validator()(
    street = @[minLength(5)],
    city = @[minLength(2)]
  )

  let userValidator = User.validator()(
      name = @[minLength(2)],
      address = @[addressValidator]
    )
