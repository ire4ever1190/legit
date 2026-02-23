import std/[tables, options]

type
  ValidationResultKind* = enum
    BadValue
    BadObject
    BadList

  ObjectValidation* = Table[string, ValidationResult]
    ## Fields in object that failed validation
  ListValidation* = Table[int, ValidationResult] ## Items in list that failed validation

  ValidationResult* = object ## What issues occured for a validation
    case kind: ValidationResultKind
    of BadValue:
      msg*: string ## Single value was tested and returned a message
    of BadObject:
      fields*: ObjectValidation
    of BadList:
      items*: ListValidation

  Validator*[T] = object ## Object that performs validation on a value
    validate*: proc(value: T): Option[ValidationResult]
      ## Validates that a value is correct

func initValidationResult*(msg: string): ValidationResult =
  ## Constructs a [BadValue] result
  return ValidationResult(kind: BadValue, msg: msg)

func initValidationResult*(fields: ObjectValidation): ValidationResult =
  ## Constructs a [BadObject] result
  return ValidationResult(kind: BadObject, fields: fields)

func initValidationResult*(items: ListValidation): ValidationResult =
  ## Constructs a [BadList] result
  return ValidationResult(kind: BadList, items: items)

proc valid*[T](validator: Validator[T], value: T): bool =
  ## Checks if a value passed is valid
  return validator.validate(value).isNone()
