# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import legit

test "Min string length":
  let validator = minLength(5)
  check validator.valid("Hello")
  check not validator.valid("Hi")

test "Object validation":
  type Person = object
    name: string

  let validator = Person.validator()(name = minLength(5))

  check validator.valid(Person(name: "Hello"))
