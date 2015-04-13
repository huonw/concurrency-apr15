% tRustworthy concurrency

Huon Wilson

April, 2015

[![parallel rusty things](rusty-beams.jpg)](https://www.flickr.com/photos/browneyes/2469970749/)


[<span style="font-weight: normal;">huonw.github.io/concurrency-apr15</span>](http://huonw.github.io/concurrency-apr15)

# Haiku (again)

> a systems language<br/>
> pursuing the trifecta<br/>
> safe, concurrent, fast

<div class="attribution"><a href="http://twitter.com/lindsey">@lindsey</a></div>

Being concurrent/parallel and safe is hard.

# But not too hard

Rust's type system has two core tools:

- ownership
- borrowing

This story is built with them.

# Ownership: who's in control?

```rust
struct MyType { x: i32 }

let owner = MyType { x: 1 };

fn print_it(value: MyType) { println!("x = {}", value.x); }

print_it(owner);
let use_again = owner;
```

<hr class="pause" />


> ```error
... error: use of moved value: `owner`
let use_again = owner;
    ^~~~~~~~~
... note: `owner` moved here because it has type `main::MyType`, which is non-copyable
show(owner);
     ^~~~~
```

# Borrowing: don't lose control!

<div class="original">
```rust
struct MyType { x: i32 }

let owner = MyType { x: 1 };

fn print_it(value: &MyType) { println!("x = {}", value.x); }

print_it(&owner);
let use_again = owner;
```
</div>

<pre id='rust-example-rendered' class='rust '>
<span class='kw'>struct</span> <span class='ident'>MyType</span> { <span class='ident'>x</span>: <span class='ident'>i32</span> }

<span class='kw'>let</span> <span class='ident'>owner</span> <span class='op'>=</span> <span class='ident'>MyType</span> { <span class='ident'>x</span>: <span class='number'>1</span> };

<span class='kw'>fn</span> <span class='ident'>print_it</span>(<span class='ident'>value</span>: <span class='kw-2 introduced'>&amp;</span><span class='ident'>MyType</span>) { <span class='macro'>println</span><span class='macro'>!</span>(<span class='string'>&quot;x = {}&quot;</span>, <span class='ident'>value</span>.<span class='ident'>x</span>); }

<span class='ident'>print_it</span>(<span class='kw-2 introduced'>&amp;</span><span class='ident'>owner</span>);
<span class='kw'>let</span> <span class='ident'>use_again</span> <span class='op'>=</span> <span class='ident'>owner</span>;
</pre>

<hr class="pause" />

> ```txt
> x = 1
> ```

References are pointers that allow using a value without transferring
ownership.



# Lifetimes: borrow fearlessly

```rust
fn foo<'a>() -> &'a i32 {
    let x = 1;
    &x
}
```

<hr class="pause" />

> ```error
... error: `x` does not live long enough
    &x
     ^
```

# `std` Cookbook

The standard library provides safe abstractions for a variety of basic
concurrency patterns:

- threads, [`std::thread`](http://doc.rust-lang.org/std/thread/)
- sending messages, [`std::sync::mpsc`](http://doc.rust-lang.org/std/sync/mpsc/)
- sharing data, [`std::sync::Arc`](http://doc.rust-lang.org/std/sync/struct.Arc.html)
- mutating data, [`std::sync::Mutex`](http://doc.rust-lang.org/std/sync/struct.Mutex.html).

The APIs ensure that there's:

- no bad sharing,
- no access of unlocked data,
- no data races.

# `std` Cookbook: Threads

```rust
use std::thread;

let some_string = "foo".to_string();

thread::spawn(move || {
    println!("new thread: string is: {}", some_string);
});
```

<hr class="pause" />

> ```txt
> new thread: string is: foo
> ```

# `std` Cookbook: Messages


```rust
use std::thread;
use std::sync::mpsc;

let (tx, rx) = mpsc::channel();

thread::spawn(move || {
    let some_string = "foo".to_string();

    tx.send(some_string).unwrap();

});

let some_string = rx.recv().unwrap();
println!("main thread: the string is: {}", some_string);
```

<hr class="pause" />

> ```txt
> main thread: the string is: foo
> ```

# `std` Cookbook: Messages

<div class="original">
```rust
use std::thread;
use std::sync::mpsc;

let (tx, rx) = mpsc::channel();

thread::spawn(move || {
    let some_string = "foo".to_string();

    tx.send(some_string).unwrap();
    println!("new thread: the string is: {}", some_string);
});

let some_string = rx.recv().unwrap();
println!("main thread: the string is: {}", some_string);
```
</div>

<pre id='rust-example-rendered' class='rust '>
<span class='kw'>use</span> <span class='ident'>std</span>::<span class='ident'>thread</span>;
<span class='kw'>use</span> <span class='ident'>std</span>::<span class='ident'>sync</span>::<span class='ident'>mpsc</span>;

<span class='kw'>let</span> (<span class='ident'>tx</span>, <span class='ident'>rx</span>) <span class='op'>=</span> <span class='ident'>mpsc</span>::<span class='ident'>channel</span>();

<span class='ident'>thread</span>::<span class='ident'>spawn</span>(<span class='kw'>move</span> <span class='op'>||</span> {
    <span class='kw'>let</span> <span class='ident'>some_string</span> <span class='op'>=</span> <span class='string'>&quot;foo&quot;</span>.<span class='ident'>to_string</span>();

    <span class='ident'>tx</span>.<span class='ident'>send</span>(<span class='ident'>some_string</span>).<span class='ident'>unwrap</span>();
<div class="introduced">    <span class='macro'>println</span><span class='macro'>!</span>(<span class='string'>&quot;new thread: the string is: {}&quot;</span>, <span class='ident'>some_string</span>);</div>});

<span class='kw'>let</span> <span class='ident'>some_string</span> <span class='op'>=</span> <span class='ident'>rx</span>.<span class='ident'>recv</span>().<span class='ident'>unwrap</span>();
<span class='macro'>println</span><span class='macro'>!</span>(<span class='string'>&quot;main thread: the string is: {}&quot;</span>, <span class='ident'>some_string</span>);
</pre>

<hr class="pause" />

> ```error
... error: use of moved value: `some_string`
    println!("new thread: the string is: {}", some_string);
                                              ^~~~~~~~~~~
```


# `std` Cookbook: Sharing


```rust
use std::thread;


let some_string = "foo".to_string();


thread::spawn(move || {
    println!("new thread: the string is: {}", some_string);
});

println!("main thread: the string is: {}", some_string);
```

<hr class="pause" />

> ```error
... error: use of moved value: `some_string`
println!("main thread: the string is: {}", some_string);
                                           ^~~~~~~~~~~
```


# `std` Cookbook: Sharing

<div class="original">
```rust
use std::thread;
use std::sync::Arc;

let some_string = Arc::new("foo".to_string());
let some_string2 = some_string.clone(); // cheap

thread::spawn(move || {
    println!("new thread: the string is: {}", some_string2);
});

println!("main thread: the string is: {}", some_string);
```
</div>

<pre id='rust-example-rendered' class='rust '>
<span class='kw'>use</span> <span class='ident'>std</span>::<span class='ident'>thread</span>;
<div class="introduced"><span class='kw'>use</span> <span class='ident'>std</span>::<span class='ident'>sync</span>::<span class='ident'>Arc</span>;</div>
<span class='kw'>let</span> <span class='ident'>some_string</span> <span class='op'>=</span> <span class="introduced"><span class='ident'>Arc</span>::<span class='ident'>new</span>(</span><span class='string'>&quot;foo&quot;</span>.<span class='ident'>to_string</span>()<span class="introduced">)</span>;
<div class="introduced"><span class='kw'>let</span> <span class='ident'>some_string2</span> <span class='op'>=</span> <span class='ident'>some_string</span>.<span class='ident'>clone</span>(); <span class='comment'>// cheap</span></div>
<span class='ident'>thread</span>::<span class='ident'>spawn</span>(<span class='kw'>move</span> <span class='op'>||</span> {
    <span class='macro'>println</span><span class='macro'>!</span>(<span class='string'>&quot;new thread: the string is: {}&quot;</span>, <span class='ident introduced'>some_string2</span>);
});

<span class='macro'>println</span><span class='macro'>!</span>(<span class='string'>&quot;main thread: the string is: {}&quot;</span>, <span class='ident'>some_string</span>);
</pre>

<hr class="pause" />

> ```txt
> main thread: the string is: foo
> new thread: the string is: foo
> ```


# `std` Cookbook: Mutation

<div class="original">
```rust
use std::thread;
use std::sync::Arc;

let some_string = Arc::new("foo".to_string());
let some_string2 = some_string.clone(); // cheap

thread::spawn(move || {
    some_string2.push_str("bar");
});

thread::sleep_ms(100); // wait for mutation
println!("main thread: string is: {}",
         some_string);
```
</div>
<pre id='rust-example-rendered' class='rust '>
<span class='kw'>use</span> <span class='ident'>std</span>::<span class='ident'>thread</span>;
<span class='kw'>use</span> <span class='ident'>std</span>::<span class='ident'>sync</span>::<span class='ident'>Arc</span>;

<span class='kw'>let</span> <span class='ident'>some_string</span> <span class='op'>=</span> <span class='ident'>Arc</span>::<span class='ident'>new</span>(<span class='string'>&quot;foo&quot;</span>.<span class='ident'>to_string</span>());
<span class='kw'>let</span> <span class='ident'>some_string2</span> <span class='op'>=</span> <span class='ident'>some_string</span>.<span class='ident'>clone</span>(); <span class='comment'>// cheap</span>

<span class='ident'>thread</span>::<span class='ident'>spawn</span>(<span class='kw'>move</span> <span class='op'>||</span> {
<div class="introduced">    <span class='ident'>some_string2</span>.<span class='ident'>push_str</span>(<span class='string'>&quot;bar&quot;</span>);</div>});

<div class="introduced"><span class='ident'>thread</span>::<span class='ident'>sleep_ms</span>(<span class='number'>100</span>); <span class='comment'>// wait for mutation</span></div><span class='macro'>println</span><span class='macro'>!</span>(<span class='string'>&quot;main thread: string is: {}&quot;</span>,
         <span class='ident'>some_string</span>);
</pre>

<hr class="pause" />

> ```error
... error: cannot borrow immutable borrowed content as mutable
    some_string2.push_str("bar");
    ^~~~~~~~~~~~
```

# `std` Cookbook: Mutation

<div class="original">
```rust
use std::thread;
use std::sync::{Arc, Mutex};

let some_string = Arc::new(Mutex::new("foo".to_string()));
let some_string2 = some_string.clone(); // cheap

thread::spawn(move || {
    some_string2.lock().unwrap().push_str("bar");
});

thread::sleep_ms(100); // wait for mutation
println!("main thread: string is: {}",
         *some_string.lock().unwrap());
```
</div>
<pre id='rust-example-rendered' class='rust '>
<span class='kw'>use</span> <span class='ident'>std</span>::<span class='ident'>thread</span>;
<span class='kw'>use</span> <span class='ident'>std</span>::<span class='ident'>sync</span>::{<span class='ident'>Arc</span>, <span class='ident introduced'>Mutex</span>};

<span class='kw'>let</span> <span class='ident'>some_string</span> <span class='op'>=</span> <span class='ident'>Arc</span>::<span class='ident'>new</span>(<span class="introduced"><span class='ident'>Mutex</span>::<span class='ident'>new</span>(</span><span class='string'>&quot;foo&quot;</span>.<span class='ident'>to_string</span>()<span class="introduced">)</span>);
<span class='kw'>let</span> <span class='ident'>some_string2</span> <span class='op'>=</span> <span class='ident'>some_string</span>.<span class='ident'>clone</span>(); <span class='comment'>// cheap</span>

<span class='ident'>thread</span>::<span class='ident'>spawn</span>(<span class='kw'>move</span> <span class='op'>||</span> {
    <span class='ident'>some_string2</span><span class="introduced">.<span class='ident'>lock</span>().<span class='ident'>unwrap</span>()</span>.<span class='ident'>push_str</span>(<span class='string'>&quot;bar&quot;</span>);
});

<span class='ident'>thread</span>::<span class='ident'>sleep_ms</span>(<span class='number'>100</span>); <span class='comment'>// wait for mutation</span>
<span class='macro'>println</span><span class='macro'>!</span>(<span class='string'>&quot;main thread: string is: {}&quot;</span>,
         <span class='op introduced'>*</span><span class='ident'>some_string</span><span class="introduced">.<span class='ident'>lock</span>().<span class='ident'>unwrap</span>()</span>);
</pre>

<hr class="pause" />

> ```txt
> main thread: string is: foobar
> ```

# `std` Cookbook: Mutation

`Mutex<T>` stores data internally, access is only granted via
`lock`,

```rust
impl<T> Mutex<T> {
    fn lock<'r>(&'r self) -> LockResult<MutexGuard<'r, T>> {
        ...
    }
}
```

which returns a handle that unlocks the mutex on drop, and provides
access to the data,

```rust
impl<'mutex, T> DerefMut for MutexGuard<'mutex, T> {
    fn deref_mut<'a>(&'a mut self) -> &'a mut T {
        ...
    }
}
```

# `std` Cookbook: Stack Pointers


```rust
use std::thread;

let some_string = "foo".to_string();

thread::spawn(move || {
    println!("new thread: the string is: {}", some_string);
});

println!("main thread: the string is: {}", some_string);
```

> ```error
... error: use of moved value: `some_string`
println!("main thread: the string is: {}", some_string);
                                           ^~~~~~~~~~~
```

# `std` Cookbook: Stack Pointers

<div class="original">
```rust
use std::thread;

let some_string = "foo".to_string();

let _guard = thread::scoped(/* move */ || {
    println!("new thread: the string is: {}", some_string);
});

println!("main thread: the string is: {}", some_string);
```
</div>
<pre id='rust-example-rendered' class='rust '>
<span class='kw'>use</span> <span class='ident'>std</span>::<span class='ident'>thread</span>;

<span class='kw'>let</span> <span class='ident'>some_string</span> <span class='op'>=</span> <span class='string'>&quot;foo&quot;</span>.<span class='ident'>to_string</span>();

<span class="introduced"><span class='kw'>let</span> <span class='ident'>_guard</span> <span class='op'>=</span> </span><span class='ident'>thread</span>::<span class='ident introduced'>scoped</span>(<span class='comment'><span class="introduced">/*</span>move<span class="introduced">*/</span></span> <span class='op'>||</span> {
    <span class='macro'>println</span><span class='macro'>!</span>(<span class='string'>&quot;new thread: the string is: {}&quot;</span>, <span class='ident'>some_string</span>);
});

<span class='macro'>println</span><span class='macro'>!</span>(<span class='string'>&quot;main thread: the string is: {}&quot;</span>, <span class='ident'>some_string</span>);
</pre>

<hr class="pause" />

> ```txt
main thread: the string is: foo
new thread: the string is: foo
```

# `std` Cookbook: Stack Pointers

`thread::scoped` is like `Mutex::lock`, it returns a handle with a lifetime:

```rust
pub fn scoped<'a, T, F>(f: F) -> JoinGuard<'a, T>
    where T: Send + 'a,
          F: FnOnce() -> T,
          F: Send + 'a
```

`JoinGuard` joins the `scoped` thread when it goes out of scope. This
plus the lifetime ensures that nothing the thread accesses will
disappear until it is finished.



# Keep cooking

`std` gives the basics, external crates have the spice, e.g.:

- [`carboxyl`](https://crates.io/crates/carboxyl): functional reactive programming
- [`eventual`](https://crates.io/crates/eventual): future & stream abstractions
- [`simple_parallel`](https://crates.io/crates/simple_parallel): basic data-parallel operations
- [`syncbox`](https://crates.io/crates/syncbox): concurrent utilities
- [`taskpipe`](https://crates.io/crates/taskpipe): a multithreaded pipeline
- [`threadpool`](https://crates.io/crates/threadpool): two types of thread pools

Lots of ideas from research that may work well in Rust too.  Worlds of
possibilities!

# `simple_parallel`

```rust
use simple_parallel::Pool;

let mut pool = Pool::new(2);

let mut values = [1, 2, 3, 4];
pool.for_(&mut values, |x| {
    *x += 1
});

println!("{}", &values);
```

> ```txt
[2, 3, 4, 5]
```

# `eventual`

```rust
use eventual::*;

let future1 = Future::spawn(|| 42);
let future2 = Future::spawn(|| 18);

let res =
    join((future1.map(|x| x * 2),
          future2.map(|y| y + 5)))
        .and_then(|(v1, v2)| v1 - v2)
        .await().unwrap();

println!("the number is {}", res);
```

> ```txt
the number is 61
```

# Why data races?

Rust tackles data races specifically: race condition, dead locks, live
locks, ... are still possible.

Data races are undefined behaviour and code with data races may behave
very strangely due to optimisations and CPU behaviour.

## Technical details

The
[`std::marker::Send`](http://doc.rust-lang.org/std/marker/trait.Send.html)
and
[`std::marker::Sync`](http://doc.rust-lang.org/std/marker/trait.Sync.html)
traits are key. Used to ensure data race freedom by leveraging the
guarantees of ownership, `&mut` and `&`.

# Questions?

&nbsp;

## Links

- [Fearless Concurrency in Rust](http://blog.rust-lang.org/2015/04/10/Fearless-Concurrency.html)
- [Some notes on Send and Sync](http://huonw.github.io/blog/2015/02/some-notes-on-send-and-sync/)

<span style="font-size: 80%">These slides are available at </span>[<span style="font-size: 80%">huonw.github.io/concurrency-apr15</span>](http://huonw.github.io/concurrency-apr15)<span style="font-size: 80%">.</span>
