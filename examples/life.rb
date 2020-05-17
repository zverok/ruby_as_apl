# https://aplwiki.com/wiki/John_Scholes%27_Conway%27s_Game_of_Life
# Life←{↑1 ⍵∨.∧3 4=+/,¯1 0 1∘.⊖¯1 0 1∘.⌽⊂⍵}

$LOAD_PATH.unshift 'lib'
require 'apl'

AA = APL::Ary

current_gen = AA[0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0].reshape(5, 5)
puts "Current:", current_gen

puts "Rotate:", current_gen.hrotate(1)

puts "Rotate 3 times:", current_gen.wrap.product(AA[-1, 0, 1], &:hrotate)

puts "Rotate 9 times:",
  current_gen.wrap.product(AA[-1, 0, 1], &:hrotate).product(AA[-1, 0, 1], &:vrotate)

puts "Rotate 9 times and sum:",
  current_gen.wrap
    .product(AA[-1, 0, 1], &:hrotate)
    .product(AA[-1, 0, 1], &:vrotate)
    .reduce(&:+).reduce(&:+)

puts "...then compare with 3 & 4",
  current_gen.wrap
    .product(AA[-1, 0, 1], &:hrotate)
    .product(AA[-1, 0, 1], &:vrotate)
    .flatten(1).reduce(&:+)
    .eq(AA[3, 4])

puts "...then AND with 1 and source",
  current_gen.wrap
    .product(AA[-1, 0, 1], &:hrotate)
    .product(AA[-1, 0, 1], &:vrotate)
    .flatten(1).reduce(&:+)
    .eq(AA[3, 4])
    .zip(AA[1, current_gen], &:&)

puts "...then OR both",
  current_gen.wrap
    .product(AA[-1, 0, 1], &:hrotate)
    .product(AA[-1, 0, 1], &:vrotate)
    .flatten(1).reduce(&:+)
    .eq(AA[3, 4])
    .zip(AA[1, current_gen], &:&)
    .reduce(&:|)

puts "...and unwrap",
  current_gen.wrap
    .product(AA[-1, 0, 1], &:hrotate)
    .product(AA[-1, 0, 1], &:vrotate)
    .flatten(1).reduce(&:+)
    .eq(AA[3, 4])
    .zip(AA[1, current_gen], &:&)
    .reduce(&:|)
    .unwrap

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

start = AA[0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0].reshape(5, 5)

require 'backports/latest' # Enumerator.produce

puts
puts '5 generations:', AA[*Enumerator.produce(start) { |cur| life(cur) }.take(5).map(&:wrap)]
