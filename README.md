This repository contains implementation of [Conway's Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) in _one Ruby statement_.

It was inspired by (in)famous [APL's one-line](https://aplwiki.com/wiki/John_Scholes%27_Conway%27s_Game_of_Life) implementation and is a more-or-less straightforward port of it into idiomatic Ruby.

To port the algorithm, a small prototype library with APL-style Array were created—so, technically, it is not a one-statement implementation, but I still prefer to think about it as "one-statement" one, as the class implemented is of generic use (somewhat like [Numo::NArray](https://github.com/ruby-numo/numo-narray)), and operations used are familiar to any Rubyist.

You can read an [explanatory article](https://zverok.github.io/blog/2020-05-16-ruby-as-apl.html) in my blog, but here we'll just show an implementation:

```ruby
require 'apl'

AA = APL::Ary

def life(current_gen)
  current_gen.wrap
    .product(AA[-1, 0, 1], &:hrotate)
    .product(AA[-1, 0, 1], &:vrotate)
    .flatten(1).reduce(&:+)
    .eq(AA[3, 4])
    .zip(AA[1, current_gen], &:&)
    .reduce(&:|)
    .unwrap
end
```

...and its usage:

```ruby
def show(grid)
  # APL-style AA#values_at(aa) produces array of items from the first array, taken and shaped
  # using numbers from second array as indexes.
  puts AA[' ', '█'].values_at(grid)
end

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

