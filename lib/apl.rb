module APL
  class Val
    def rank
      shape.size
    end

    def apply_at_rank(r, &block)
      case rank
      when r
        yield self
      when 0...r
        self
      else
        Ary.new(items.map { |i| i.apply_at_rank(r, &block)})
      end
    end

    def +(other)
      op(:+, other)
    end

    def &(other)
      op(:&, other)
    end

    def |(other)
      op(:|, other)
    end

    def eq(other)
      op(:eq, other)
    end

    def product(other, &op)
      Ary[*other.items.map { |o| map_ { |i| op.(i, o) } }]
    end

    def reduce(&op)
      Array(items).reduce(&op)
    end

    def zip(other, &op)
      other.shape == self.shape or
        fail ArgumentError, "Can't zip value of shape #{shape} with #{other.shape}"

      APL::Ary[*Array(items).zip(other.items).map { |i1, i2| op.(i1, i2) }]
    end

    private

    def op(symbol, other)
      case other
      when Scalar
        apply_at_rank(0) { |val| val.send(symbol, other.value) }
      when Ary
        shape == other.shape or fail ArgumentError, "Shape mismatch #{shape} vs #{other.shape}"
        Ary.new(items.zip(other.items).map { |i1, i2| i1.send(symbol, i2) })
      else
        op(symbol, Scalar.coerce(other))
      end
    end
  end

  class Scalar < Val
    def self.coerce(value)
      return value if value.is_a?(Scalar)
      new(value)
    end

    attr_reader :value

    def initialize(value)
      [String, Numeric, Ary].any? { |cls| value.is_a?(cls) } or
        raise ArgumentError, "Can't create scalar from #{value.inspect}"

      @value = value
    end

    def ==(other)
      other.is_a?(Scalar) && value == other.value
    end

    def items
      self
    end

    def map_
      yield self
    end

    def shape
      []
    end

    def inspect
      '<%s %p>' % [self.class, value]
    end

    def nested_inspect
      value.inspect
    end

    def to_s
      value.is_a?(Ary) ? APL::text_frame(value.to_s) : value.to_s
    end

    def map
      Scalar.new(yield value)
    end

    def flatten(*)
      self
    end

    %i[vrotate hrotate + & |].each do |meth|
      define_method(meth) { |other, &block|
        other = other.value if other.is_a?(Scalar)
        Scalar.coerce(value.send(meth, other, &block))
      }
    end

    def eq(what)
      if what.is_a?(Ary)
        Ary[*what.items.map { |v| eq(v) }]
      else
        Scalar.new(value.respond_to?(:eq) ? value.eq(what) : (value == what ? 1 : 0))
      end
    end

    def unwrap
      value
    end

    def take(*dims)
      return self if dims.empty?
      AA[self].reshape(*dims)
    end
  end

  class Ary < Val
    def self.[](*items)
      items.map { |i|
        case i
        when ::Array then self[*i]
        when Scalar  then i
        else         Scalar.coerce(i)
        end
      }.then(&method(:new))
    end

    attr_reader :items

    def initialize(items)
      items.all?(Val) or fail ArgumentError, "Array only can be created from APL vals, got #{items.map(&:class)}"
      @items = items
    end

    def inspect
      '#<%s[%s]>' % [self.class, items.map(&:nested_inspect).join(', ')]
    end

    def nested_inspect
      items.map(&:nested_inspect).join(', ').then { |str| "[#{str}]" }
    end

    def to_s
      spacing = (rank + 1) / 2
      # special case: in APL, string arrays == strings, so should be output without spacing
      spacing = 0 if rank == 1 && items.all? { |i| i.is_a?(Scalar) && i.value.is_a?(String) }
      items.map(&:to_s).then { |results|
        if rank.even?
          results.join("\n" * spacing)
        else
          results
            .map { |res| res.split("\n") }.transpose
            .map { |res| res.join(' ' * spacing) }.join("\n")
        end
      }
    end

    def map_(&block)
      items.map(&block)
    end

    def wrap
      Scalar.new(self)
    end

    def shape
      [items.count, *items.first.shape]
    end

    def ==(other)
      other.is_a?(Ary) && shape == other.shape && items == other.items
    end

    def reshape(*dims)
      source = flatten.items.then { |flat| flat * (dims.reduce(:*) / flat.size.to_f).ceil }
      Ary[*dims[1..]
        .reduce(source) { |res, dim| res.each_slice(dim).to_a }
        .first(dims.first)]

    end

    def flatten(levels = nil)
      return self if levels&.<=(0)
      Ary[*items.map { |i| i.flatten(levels&.- 1) }.flat_map(&:items)]
    end

    def hrotate(count = 1)
      apply_at_rank(1) { |row| Ary.new(row.items.rotate(count)) }
    end

    def vrotate(count = 1)
      apply_at_rank(2) { |row|
        Ary[*row.items.map(&:items).transpose.map { |c| c.rotate(count) }.transpose]
      }
    end

    def take(dim, *dims)
      new_items = dim > 0 ? items.values_at(0...dim) : items.reverse.values_at(0...-dim).reverse
      empty = dims.empty? ? Scalar.new(0) : Ary[0].reshape(*dims.map(&:abs))
      Ary.new(new_items.map { |i| i.nil? ? empty : i.take(*dims) })
    end

    def values_at(other)
      other.apply_at_rank(0) { |i|
        i.value.is_a?(Ary) ? Scalar.new(values_at(i.value)) : items[i.value]
      }
    end
  end

  module_function

  def text_frame(str)
    str.split("\n").then { |lines|
      size = lines.map(&:length).max
      [
        '┌' + '─' * size + '┐',
        *lines.map { |ln| "│#{ln}│" },
        '└' + '─' * size + '┘'
      ].join("\n")
    }
  end
end
