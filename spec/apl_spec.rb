require 'apl'

AA = APL::Ary

def S(val)
  APL::Scalar.new(val)
end

RSpec.describe APL::Scalar do
  describe '.coerce' do
    subject { ->(val) { described_class.coerce(val) } }

    its_call(5) { is_expected.to ret S(5) }
    its_call(S(5)) { is_expected.to ret S(5) }
    its_call('f') { is_expected.to ret S('f') }
    its_call(AA[1, 2, 3]) { is_expected.to ret S(AA[1, 2, 3]) }
    its_call([1, 2, 3]) { is_expected.to raise_error ArgumentError }
  end

  describe '#+' do
    subject { ->(val, other) { S(val) + other } }

    its_call(AA[1, 2], S(10)) { is_expected.to ret S(AA[11, 12]) }

    its_call(AA[[1, 2], [3, 4]], S(10)) {
      is_expected.to ret S(AA[[11, 12], [13, 14]])
    }
  end

  describe '#product' do
    subject { ->(val, other, op) { S(val).product(other, &op) } }

    its_call(AA[1, 2], AA[3, 4], :+) {
      is_expected.to ret AA[AA[4, 5], AA[5, 6]]
    }
  end
end

RSpec.describe APL::Ary do
  describe '.[]' do
    subject { described_class.method(:[]) }

    its_call(1) { is_expected.to ret AA.new([S(1)]) }
    its_call([1, 2], [3, 4]) {
      is_expected.to ret AA.new(
        [
          described_class.new([S(1), S(2)]),
          described_class.new([S(3), S(4)])
        ])
    }
    its_call(1, AA[2]) {
      is_expected.to ret AA.new(
        [
          S(1),
          S(AA.new([S(2)]))
        ]
      )
    }
  end

  describe '#to_s' do
    subject { ->(*ary) { AA[*ary].to_s } }

    its_call(1, 2, 3) { is_expected.to ret '1 2 3' }
    its_call([1, 2], [3, 4]) {
      is_expected.to ret <<~S.strip
        1 2
        3 4
      S
    }

    its_call([[1, 2], [3, 4]], [[5, 6], [7, 8]]) {
      is_expected.to ret <<~S.strip
        1 2  5 6
        3 4  7 8
      S
    }

    its_call(AA[[1, 2], [3, 4]], AA[[5, 6], [7, 8]]) {
      is_expected.to ret <<~S.strip
        ┌───┐ ┌───┐
        │1 2│ │5 6│
        │3 4│ │7 8│
        └───┘ └───┘
      S
    }
  end

  describe '#flatten' do
    subject { ->(ary, levels = nil) { described_class[*ary].flatten(levels) } }

    its_call([1, 2, 3]) { is_expected.to ret described_class[1, 2, 3] }
    its_call([1, 2, 3], 1) { is_expected.to ret described_class[1, 2, 3] }
    its_call([[1, 2], [3, 4]]) { is_expected.to ret described_class[1, 2, 3, 4] }
  end

  describe '#reshape' do
    subject { ->(ary, *dims) { described_class[*ary].reshape(*dims) } }

    its_call([1, 1, 1, 1, 0, 0, 0, 1, 0], 3, 3) {
      is_expected.to ret described_class[[1, 1, 1], [1, 0, 0], [0, 1, 0]]
    }

    its_call([1, 2, 3, 4], 3, 3) {
      is_expected.to ret described_class[[1, 2, 3], [4, 1, 2], [3, 4, 1]]
    }
  end

  describe '#hrotate' do
    subject { ->(ary, count = 1) { described_class[*ary].hrotate(count) } }

    its_call([[1, 0, 1], [1, 0, 0], [0, 1, 0]]) {
      is_expected.to ret described_class[[0, 1, 1], [0, 0, 1], [1, 0, 0]]
    }
  end

  describe '#vrotate' do
    subject { ->(ary, count = 1) { described_class[*ary].vrotate(count) } }

    its_call([[1, 0, 1],
              [1, 0, 0],
              [0, 1, 0]]) {
      is_expected.to ret described_class[
        [1, 0, 0],
        [0, 1, 0],
        [1, 0, 1]
      ]
    }
  end

  describe '#+' do
    subject { ->(ary, arg) { described_class[*ary] + arg } }

    context 'with scalar' do
      its_call([1, 2, 3], 10) { is_expected.to ret described_class[11, 12, 13] }
    end

    context 'with ary' do
      its_call([1, 2, 3], AA[10, 11, 12]) { is_expected.to ret described_class[11, 13, 15] }
    end

    context '2-dim with scalar' do
      its_call([[1, 2], [3, 4]], 10) { is_expected.to ret AA[[11, 12], [13, 14]] }
    end
  end

  describe '#&' do
    subject { ->(ary, arg) { described_class[*ary] & arg } }

    context 'with scalar' do
      its_call([0, 1, 0], 1) { is_expected.to ret described_class[0, 1, 0] }
      its_call([0, 1, 0], 0) { is_expected.to ret described_class[0, 0, 0] }
    end

    context 'with ary' do
      its_call([0, 1, 0], AA[0, 1, 1]) { is_expected.to ret described_class[0, 1, 0] }
    end
  end

  describe '#product' do
    subject { ->(ary, other, op) { described_class[*ary].product(other, &op) } }

    its_call([1, 2], AA[3, 4], :+) {
      is_expected.to ret described_class[[4, 5], [5, 6]]
    }

    its_call([AA[1, 2], AA[3, 4]], AA[10, 20], :+) {
      is_expected.to ret AA[
        [AA[11, 12], AA[13, 14]],
        [AA[21, 22], AA[23, 24]]
      ]
    }
  end

  describe '#reduce' do
    subject { ->(ary, op) { AA[*ary].reduce(&op) } }

    its_call([1, 2, 3], :+) { is_expected.to ret S(6) }
    its_call([[1, 2], [3, 4]], :+) { is_expected.to ret AA[4, 6] }

    its_call([AA[1, 2], AA[3, 4]], :+) { is_expected.to ret S(AA[4, 6]) }
  end

  describe '#zip' do
    subject { ->(ary, other, op) { AA[*ary].zip(AA[*other], &op) } }

    its_call([1, 2], [3, 4], :+) {
      is_expected.to ret AA[4, 6]
    }
  end
end
