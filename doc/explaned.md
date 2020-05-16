Well, the title says it all!

But let me explain. Last week, I stumbled upon a new [APL apology](https://www.sacrideo.us/is-apl-dead/) post. It striked some deep chort in me, and gave me an impulse to make another attempt to understand this beautifully [weird language](https://en.wikipedia.org/wiki/APL_(programming_language)#Examples).

What I (somewhat unexpectedly) find out, is that besides use of extensive character set and extreme terseness, APL has two main features that are not at all alien to Ruby: calculations through operation chaining, and extensive library of array operations, suitable for said chaining (in Ruby, they are reprsented by [Enumerable](https://ruby-doc.org/core-2.7.1/Enumerable.html) module).

At this point, I felt that _probably_ some of APL approaches and examples could be translated to Ruby pretty straightforwardly, and that would be an _idiomatic_ Ruby. To challenge this feeling, I experimented with translating the (in)famous [APL's one-line](https://aplwiki.com/wiki/John_Scholes%27_Conway%27s_Game_of_Life) [Conway's Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) implementation—**and succeeded** to implement GoL in exactly one Ruby statement.

Of course, the implementation required the notion of "mathematical array", matching that of APL, so technically it is "one statement plus supporting class", but I still prefer to think about it as "one-statement" one, as the class implemented is of generic use (somewhat like [Numo::NArray](https://github.com/ruby-numo/numo-narray)), and operations used are familiar to any Rubyist.

To look immediately at the final implementation you may jump [straight to the repo](https://github.com/zverok/ruby_as_apl). The rest of this article goes through the implementation process, closely following the explanations in [APL's version](https://aplwiki.com/wiki/John_Scholes%27_Conway%27s_Game_of_Life).

---

Before we start, some basic information about APL-style Arrays:

* In APL, **array** is a mathematical array: it is a _rectangular multidemensional matrix of scalars_. It is represented by `APL::Ary` in Ruby code, and shortened to `AA` in explanations below.

```ruby
require 'apl'
AA = APL::Ary
```

* **Scalar** is number, or character, or another array. This means one should not confuse _multidimensional_ arrays (matrices, with equal number of elements alongside some dimension), and _nested arrays_. Example:

```ruby
puts AA[1, 2, 3, 4].reshape(2, 2)
# 1 2
# 3 4
# -- two-dimensional matrix of numbers
puts AA[AA[1, 2], AA[3, 4]]
# ┌───┐ ┌───┐
# │1 2│ │3 4│
# └───┘ └───┘
# -- one-dimensional array of two one-dimensional arrays.
# Note the frames around nested arrays helping to understand the nesting
```

* Array might be easily turned into scalar containing this array (and back) with `#wrap`/`#unwrap`:

```ruby
a = AA[1, 2]
puts a
# 1 2
puts a.wrap
# ┌───┐
# │1 2│
# └───┘
puts a.wrap.unwrap
# 1 2
```

* As usual for mathematical arrays, mathematical operations could be performed with scalar (like "add 2 to every element") or another array of the same shape (like "add item of array A to item in similar position of array B")

That being said, let's begin with some first generation of our Game of Life:
```ruby
current_gen = AA[0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0].reshape(5, 5)
puts current_gen
# 0 0 0 0 0
# 0 0 1 1 0
# 0 1 1 0 0
# 0 0 1 0 0
# 0 0 0 0 0
```

So far, we've just created an array of 1s and 0s and "reshaped" it into 5×5 two-dimensional matrix.

The next step would be rotating it horizontally:

```ruby
puts current_gen.hrotate(1)
# 0 0 0 0 0
# 0 1 1 0 0
# 1 1 0 0 0
# 0 1 0 0 0
# 0 0 0 0 0
```
`#hrotate` is simply shifting values in each row to the left, cyclically, and resembles (1-dimensional only) [Array#rotate](https://ruby-doc.org/core-2.7.1/Array.html#method-i-rotate) of Ruby.

Now, let's produce 3 variants of the rotation: 1 to the left, none, and 1 to the right:
```ruby
current_gen.wrap.product(AA[-1, 0, 1], &:hrotate)
# ┌─────────┐ ┌─────────┐ ┌─────────┐
# │0 0 0 0 0│ │0 0 0 0 0│ │0 0 0 0 0│
# │0 0 0 1 1│ │0 0 1 1 0│ │0 1 1 0 0│
# │0 0 1 1 0│ │0 1 1 0 0│ │1 1 0 0 0│
# │0 0 0 1 0│ │0 0 1 0 0│ │0 1 0 0 0│
# │0 0 0 0 0│ │0 0 0 0 0│ │0 0 0 0 0│
# └─────────┘ └─────────┘ └─────────┘
```
It becames more peculiar at this point.

Let's start with `#product`: It is like Ruby's `Array#product` (make all possible combinations of two arrays), with one important difference: APL's "product", instead of just producing combinations, accepts also operation to immediately apply to them. So, in vanilla Ruby:

```ruby
[1, 2].product([3, 4]).map { |a, b| "#{a}+#{b}"}
# => ["1+3", "1+4", "2+3", "2+4"]
```
...but in APL-style `#product` it would be expressed (pseudo-code) as just
```ruby
[1, 2].product([3, 4]) { |a, b| "#{a}+#{b}"}
```

`#wrap` here is necessary so we will product just one entire array (as a scalar) per `-1`, `0` and `1`, not each-row-per-each-number.

With that in hands, let's produce some more rotations, shifting all numbers by -1, 0, and 1 _vertically_:

```ruby
puts current_gen.wrap.product(AA[-1, 0, 1], &:hrotate).product(AA[-1, 0, 1], &:vrotate)
# ┌─────────┐ ┌─────────┐ ┌─────────┐
# │0 0 0 0 0│ │0 0 0 0 0│ │0 0 0 1 1│
# │0 0 0 0 0│ │0 0 0 1 1│ │0 0 1 1 0│
# │0 0 0 1 1│ │0 0 1 1 0│ │0 0 0 1 0│
# │0 0 1 1 0│ │0 0 0 1 0│ │0 0 0 0 0│
# │0 0 0 1 0│ │0 0 0 0 0│ │0 0 0 0 0│
# └─────────┘ └─────────┘ └─────────┘
# ┌─────────┐ ┌─────────┐ ┌─────────┐
# │0 0 0 0 0│ │0 0 0 0 0│ │0 0 1 1 0│
# │0 0 0 0 0│ │0 0 1 1 0│ │0 1 1 0 0│
# │0 0 1 1 0│ │0 1 1 0 0│ │0 0 1 0 0│
# │0 1 1 0 0│ │0 0 1 0 0│ │0 0 0 0 0│
# │0 0 1 0 0│ │0 0 0 0 0│ │0 0 0 0 0│
# └─────────┘ └─────────┘ └─────────┘
# ┌─────────┐ ┌─────────┐ ┌─────────┐
# │0 0 0 0 0│ │0 0 0 0 0│ │0 1 1 0 0│
# │0 0 0 0 0│ │0 1 1 0 0│ │1 1 0 0 0│
# │0 1 1 0 0│ │1 1 0 0 0│ │0 1 0 0 0│
# │1 1 0 0 0│ │0 1 0 0 0│ │0 0 0 0 0│
# │0 1 0 0 0│ │0 0 0 0 0│ │0 0 0 0 0│
# └─────────┘ └─────────┘ └─────────┘
```

Note that what we currently see is a _2 dimensional matrix (3×3)_ of _2-dimensional matrices (5×5)_: inner metrices are wrapped in frames.

Now, let's sum them all up:

```ruby
puts current_gen.wrap
  .product(AA[-1, 0, 1], &:hrotate)
  .product(AA[-1, 0, 1], &:vrotate)
  .reduce(&:+).reduce(&:+)
# ┌─────────┐
# │0 1 2 2 1│
# │1 3 4 3 1│
# │1 4 5 4 1│
# │1 3 3 2 0│
# │0 1 1 1 0│
# └─────────┘
```

`#reduce` here is the same `Enumerable#reduce`. The important feature is that APL-style arrays are summing up element-wise, so now we have a sum of all 9 matrices, representing _how many alie neighbours_ (including itself) every cell had.

Now, it should be noticed, that only cells with 3 or 4 should be alive in the next generation:
* cell with 3 means "alive + 2 neighbours" (condition to live) or "empty with 3 neighbours" (condition to become alive)
* cell with 4 means "alive + 3 neighbours" (condition to live) or "empty with 4 neighbours" (**not** a condition to become alive)

To check "whether it is equal to something", we have `.eq` operator implemented. That's, probably, most "non-Rubyish" part of the solution: instead of producing `true`/`false`, it gives `1`/`0`. Unfortunately, it is important to algorithm to always stay as numbers.

So, comparing with each number separately will give us...

```ruby
puts current_gen.wrap
  .product(AA[-1, 0, 1], &:hrotate)
  .product(AA[-1, 0, 1], &:vrotate)
  .reduce(&:+).reduce(&:+)
  .eq(3)
# ┌─────────┐
# │0 0 0 0 0│
# │0 1 0 1 0│
# │0 0 0 0 0│
# │0 1 1 0 0│
# │0 0 0 0 0│
# └─────────┘

puts current_gen.wrap
  .product(AA[-1, 0, 1], &:hrotate)
  .product(AA[-1, 0, 1], &:vrotate)
  .reduce(&:+).reduce(&:+)
  .eq(4)
# ┌─────────┐
# │0 0 0 0 0│
# │0 0 1 0 0│
# │0 1 0 1 0│
# │0 0 0 0 0│
# │0 0 0 0 0│
# └─────────┘
```

But we also may apply both operations at once, producing array of two elements (ability to perform one operation several times is called _pervasion_ in APL):

```ruby
puts current_gen.wrap
  .product(AA[-1, 0, 1], &:hrotate)
  .product(AA[-1, 0, 1], &:vrotate)
  .reduce(&:+).reduce(&:+)
  .eq(AA[3, 4])
# ┌─────────┐ ┌─────────┐
# │0 0 0 0 0│ │0 0 0 0 0│
# │0 1 0 1 0│ │0 0 1 0 0│
# │0 0 0 0 0│ │0 1 0 1 0│
# │0 1 1 0 0│ │0 0 0 0 0│
# │0 0 0 0 0│ │0 0 0 0 0│
# └─────────┘ └─────────┘
```

Now, we need to add a condition of "whether it was alive" to the _second_ array. It is easy to perform with just `&`-ing with original array. To not break our chain of operations, we'll also `&` the first array with `1` (no-op):

```ruby
puts current_gen.wrap
  .product(AA[-1, 0, 1], &:hrotate)
  .product(AA[-1, 0, 1], &:vrotate)
  .reduce(&:+).reduce(&:+)
  .eq(AA[3, 4])
  .zip(AA[1, current_gen], &:&)
# ┌─────────┐ ┌─────────┐
# │0 0 0 0 0│ │0 0 0 0 0│
# │0 1 0 1 0│ │0 0 1 0 0│
# │0 0 0 0 0│ │0 1 0 0 0│
# │0 1 1 0 0│ │0 0 0 0 0│
# │0 0 0 0 0│ │0 0 0 0 0│
# └─────────┘ └─────────┘
```
`#zip` here, like `#product` above, is almost like the `Array#zip` of Ruby, but also applies provided operation to each pair.

...and then reduce them with `|`-ing both:
```ruby
puts current_gen.wrap
  .product(AA[-1, 0, 1], &:hrotate)
  .product(AA[-1, 0, 1], &:vrotate)
  .reduce(&:+).reduce(&:+)
  .eq(AA[3, 4])
  .zip(AA[1, current_gen], &:&)
  .reduce(&:|)
# ┌─────────┐
# │0 0 0 0 0│
# │0 1 1 1 0│
# │0 1 0 0 0│
# │0 1 1 0 0│
# │0 0 0 0 0│
# └─────────┘
```
...which is almost our final answer, but it is still a "scalar with array inside", and we need to unwrap it:
```ruby
puts current_gen.wrap
  .product(AA[-1, 0, 1], &:hrotate)
  .product(AA[-1, 0, 1], &:vrotate)
  .reduce(&:+).reduce(&:+)
  .eq(AA[3, 4])
  .zip(AA[1, current_gen], &:&)
  .reduce(&:|)
  .unwrap
# 0 0 0 0 0
# 0 1 1 1 0
# 0 1 0 0 0
# 0 1 1 0 0
# 0 0 0 0 0
```

So, here is the final solution:
```ruby
def life(current_gen)
  current_gen.wrap
    .product(AA[-1, 0, 1], &:hrotate)
    .product(AA[-1, 0, 1], &:vrotate)
    .reduce(&:+).reduce(&:+)
    .eq(AA[3, 4])
    .zip(AA[1, current_gen], &:&)
    .reduce(&:|)
    .unwrap
end
```

Here is APL's version:
```apl
Life←{↑1 ⍵∨.∧3 4=+/,¯1 0 1∘.⊖¯1 0 1∘.⌽⊂⍵}
```

For those interested, here is statement-by-statement equivalent¹
```ruby
def life(current_gen)                 # Life←{    -- function declaration
  current_gen                         # ⍵         -- function argument
    .wrap                             # ⊂         -- wrap to make it scalar
    .product(                         # ∘.        -- product
      AA[-1, 0, 1],                   # ¯1 0 1    --  -1, 0, 1 (yeah, ¯1 is -1)
      &:hrotate)                      # ⌽         -- hrotate
    .product(                         # ∘.        -- product
      AA[-1, 0, 1],                   # ¯1 0 1
      &:vrotate)                      # ⊖         -- vrotate
    .reduce(&:+).reduce(&:+)          # +/,       -- reduce twice¹
    .eq(                              # =
      AA[3, 4])                       # 3 4
    .zip(                             #           -- see below¹ about those 3 lines
      AA[1, current_gen],             # 1 ⍵
      &:&).reduce(&:|)                # ∨.∧
    .unwrap                           # ↑         -- unwrap
end                                   # }
```
¹I made two simplifications: abstained for implementing "reduce by 2 levels at once" (two reduces is short enough), and from quite complicated APL's "inner product" operator (which takes two functions and mades them into something that I represented in regular Ruby with zip+reduce).

That's it!
Now, for the fun example of usage

## Glider on the grid.

[Original APL's article](https://aplwiki.com/wiki/John_Scholes%27_Conway%27s_Game_of_Life) demonstrates the usage by moving Glider through 10×10 grid. Let's try this. But first, we want method to display those 0s and 1s a bit prettier. Again, borrowed from APL:

```ruby
def show(grid)
  # APL-style AA#values_at(aa) produces array of items from the first array, taken and shaped
  # using numbers from second array as indexes.
  puts AA[' ', '█'].values_at(grid)
end
```

Now:

```ruby
glider = AA[1, 1, 1, 1, 0, 0, 0, 1, 0].reshape(3, 3)
grid = glider.take(-10, -10)

show grid.wrap
# ┌──────────┐
# │          │
# │          │
# │          │
# │          │
# │          │
# │          │
# │          │
# │       ███│
# │       █  │
# │        █ │
# └──────────┘


generations = [grid]
9.times { generations << life(generations.last) }

show AA[*generations]

# or, simpler, with 2.7's Enumerator#produce:

generations = Enumerator.produce(grid) { |cur| life(cur) }.take(10).map(&:wrap)
show AA[*generations]
# ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
# │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │
# │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │
# │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │
# │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │
# │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │      █   │
# │          │ │          │ │          │ │          │ │          │ │       █  │ │      ██  │ │      ██  │ │     ███  │ │     ██   │
# │          │ │        █ │ │       ██ │ │       ██ │ │      ███ │ │      ██  │ │      █ █ │ │     ██   │ │     █    │ │     █ █  │
# │       ███│ │       ██ │ │       █ █│ │      ██  │ │      █   │ │      █ █ │ │      █   │ │       █  │ │      █   │ │          │
# │       █  │ │       █ █│ │       █  │ │        █ │ │       █  │ │          │ │          │ │          │ │          │ │          │
# │        █ │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │ │          │
# └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘
```

That's it!

**[GitHub repo](https://github.com/zverok/ruby_as_apl)**
