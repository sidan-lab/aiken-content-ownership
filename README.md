# aiken-content-ownership

This is the implementation of on-chain content ownership with below features:
1. User can create content and leverage Cardano blockchain to record ownership
2. The content owner can update the content anytime
3. The content owner can transfer content ownership to others
4. Forward compatible: Incentive mechanism expansion
5. Scalable: Up to 10,000 users, each with 10,000 piece of content
6. User can use any native asset on Cardano to represent ownership identity

## Building

```sh
aiken build
```

## Testing

You can write tests in any module using the `test` keyword. For example:

```gleam
test foo() {
  1 + 1 == 2
}
```

To run all tests, simply do:

```sh
aiken check
```

To run only tests matching the string `foo`, do:

```sh
aiken check -m foo
```

## Documentation

If you're writing a library, you might want to generate an HTML documentation for it.

Use:

```sh
aiken docs
```

## Resources

Find more on the [Aiken's user manual](https://aiken-lang.org).
