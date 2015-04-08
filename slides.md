% Concurrency without tears

Huon Wilson

April, 2015

# Haiku (again)

> a systems language<br/>
> pursuing the trifecta<br/>
> safe, **concurrent**, fast

<div class="attribution"><a href="http://twitter.com/lindsey">@lindsey</a></div>

What? Why? How?

# But first...

Rust's type system has two main tools:

- ownership
- borrowing

The concurrency story is built with them.

# Ownership &ndash; who's in control?

```rust
struct MyType { x: i32 }

let owner = MyType { x: 1 };

fn foo(value: MyType) { println!("{}", value.x); /* etc */ }

foo(owner);
let use_again = owner;
```

<hr class="pause" />


```txt
... error: use of moved value: `owner`
let use_again = owner;
    ^~~~~~~~~
... note: `owner` moved here because it has type `main::MyType`, which is non-copyable
show(owner);
     ^~~~~
```

# Borrowing &ndash; don't lose control!


```rust
struct MyType { x: i32 }

let owner = MyType { x: 1 };

fn foo(value: &MyType) { println!("{}", value.x); /* etc */ }

foo(&owner);
let use_again = owner;
```



# Cookbook

## Share immutable data

# Cookbook

## Share mutable data

# Cookbook

## Pass messages

# Cookbook

## Point into another thread's stack
