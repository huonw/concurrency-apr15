% tRustworthy concurrency

Huon Wilson

April, 2015

# Haiku (again)

> a systems language<br/>
> pursuing the trifecta<br/>
> safe, concurrent, fast

<div class="attribution"><a href="http://twitter.com/lindsey">@lindsey</a></div>

Being concurrent and safe is hard.

# But not too hard

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

# Keeping borrows under control

TODO slide is subpar


```rust
let outer;
{
    let inner = 1;
    outer = &inner;
}
```

<hr class="pause" />

```txt
... error: `inner` does not live long enough
    outer = &inner;
             ^~~~~
...  note: reference must be valid for the block suffix following statement 0 at 2:9...
let outer;
{
    let inner = 1;
    outer = &inner;
}
...  note: ...but borrowed value is only valid for the block suffix following statement 0 at 4:17
    let inner = 1;
    outer = &inner;
}
```

# `std` Cookbook

The standard library provides safe abstractions for a variety of basic
concurrency patterns.

**TODO: All slides are loose notes from here**

Consider looking at `Condvar::wait`: makes behaviour much clearer than
e.g. `pthread_cond_wait`.

# `std` Cookbook

## Start a thread with information from a parent

Closure captures


# `std` Cookbook

## Share immutable data

`Arc<...>`

Guaranteed that there's no mutation due to ownership ensuring no
sharing and `&` ensuring no mutation (except... `&` is "shared" not
"immutable". see the next slide)

# `std` Cookbook

## Share mutable data

`Arc<Mutex<...>>`, `Atomic...`

No way to access data without locking

# `std` Cookbook

## Pass messages

`std::sync::mpsc`

Data passed is not going to be accidentally shared (in a "bad" way).

# `std` Cookbook

## Point to/mutate another thread's stack

`std::thread::scoped`

Lifetimes ensure you're going to die before your parents



# Bigger cookbook

`threadpool`, `simple_parallel`: a whole world of possibilities, e.g. research like Cilk are probably productive routes (lvars, [differential dataflow](http://www.frankmcsherry.org/differential/dataflow/2015/04/07/differential.html) (TODO read more about this)).

# What Rust tackles

Data races, not race conditions

The `Send` trait and the guarantees of `&` and `&mut` are key.
