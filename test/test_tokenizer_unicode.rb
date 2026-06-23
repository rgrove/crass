# encoding: utf-8

# Tests covering tokenization of multi-byte (non-ASCII) input, including a
# performance regression test ensuring that non-ASCII token streams don't cause
# superlinear CPU consumption.
#
# Crass tracks scanner positions as character offsets for its public `:pos`
# contract, but extracts token text using byte offsets internally. Slicing the
# original UTF-8 string by character offset is O(n) on multi-byte input, which
# previously made tokenizing non-ASCII CSS superlinear.

require_relative 'support/common'

describe 'Crass::Tokenizer multi-byte input' do
  make_my_diffs_pretty!
  parallelize_me!

  # Representative multi-byte characters of each UTF-8 width.
  TWO_BYTE   = "\u00e9"    # é   (2 bytes)
  THREE_BYTE = "\u20ac"    # €   (3 bytes)
  FOUR_BYTE  = "\u{1f600}" # 😀  (4 bytes)

  describe 'token text (:raw and :value)' do
    it 'should preserve multi-byte identifiers' do
      [TWO_BYTE, THREE_BYTE, FOUR_BYTE].each do |char|
        ident  = "#{char}#{char}"
        tokens = CT.tokenize(ident)

        assert_equal([:ident], tokens.map { |t| t[:node] })
        assert_equal(ident, tokens[0][:raw])
        assert_equal(ident, tokens[0][:value])
      end
    end

    it 'should preserve multi-byte string contents' do
      [TWO_BYTE, THREE_BYTE, FOUR_BYTE].each do |char|
        css    = "'#{char}#{char}'"
        tokens = CT.tokenize(css)

        assert_equal([:string], tokens.map { |t| t[:node] })
        assert_equal(css, tokens[0][:raw])
        assert_equal("#{char}#{char}", tokens[0][:value])
      end
    end

    it 'should preserve multi-byte property names and values' do
      css    = "#{FOUR_BYTE}:#{FOUR_BYTE}"
      tokens = CT.tokenize(css)

      assert_equal([:ident, :colon, :ident], tokens.map { |t| t[:node] })
      assert_equal([FOUR_BYTE, ':', FOUR_BYTE], tokens.map { |t| t[:raw] })
    end
  end

  describe 'character positions (:pos)' do
    # `:pos` must remain a character offset (not a byte offset) even for
    # multi-byte input, since the public API and existing tests rely on it.
    it 'should report character offsets, not byte offsets' do
      tokens = CT.tokenize("#{TWO_BYTE}:#{THREE_BYTE}")

      assert_equal([:ident, :colon, :ident], tokens.map { |t| t[:node] })
      assert_equal([0, 1, 2], tokens.map { |t| t[:pos] })
    end

    it 'should report character offsets for four-byte characters' do
      tokens = CT.tokenize("#{FOUR_BYTE} #{FOUR_BYTE}")

      assert_equal([:ident, :whitespace, :ident], tokens.map { |t| t[:node] })
      assert_equal([0, 1, 2], tokens.map { |t| t[:pos] })
    end
  end

  describe 'lookahead across multi-byte boundaries' do
    # These exercise the 2-3 character lookahead (`peek`) immediately adjacent
    # to multi-byte characters, which is where byte-vs-character slicing matters.
    it 'should treat a leading hyphen plus multi-byte char as an identifier' do
      tokens = CT.tokenize("-#{FOUR_BYTE}")

      assert_equal([:ident], tokens.map { |t| t[:node] })
      assert_equal("-#{FOUR_BYTE}", tokens[0][:raw])
      assert_equal("-#{FOUR_BYTE}", tokens[0][:value])
    end

    it 'should unescape a multi-byte escaped code point' do
      tokens = CT.tokenize("\\#{FOUR_BYTE}")

      assert_equal([:ident], tokens.map { |t| t[:node] })
      assert_equal("\\#{FOUR_BYTE}", tokens[0][:raw])
      assert_equal(FOUR_BYTE, tokens[0][:value])
    end

    it 'should not mistake a multi-byte char for a CDO' do
      tokens = CT.tokenize("<#{FOUR_BYTE}")

      assert_equal([:delim, :ident], tokens.map { |t| t[:node] })
      assert_equal(['<', FOUR_BYTE], tokens.map { |t| t[:raw] })
    end
  end

  describe 'round-trip fidelity' do
    it 'should reconstruct multi-byte input by joining token :raw values' do
      css = ".#{TWO_BYTE} { content: '#{THREE_BYTE}#{FOUR_BYTE}'; width: 10%; }"

      assert_equal(css, CT.tokenize(css).map { |t| t[:raw] }.join)
    end
  end
end

describe 'Crass::Tokenizer non-ASCII performance' do
  parallelize_me!

  # Returns the fastest wall-clock time (in seconds) to run _block_, after a
  # warmup run, taking the minimum of several runs to reduce noise.
  def best_time(runs = 3)
    yield # warmup (e.g. JIT, allocations)

    (1..runs).map do
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    end.min
  end

  it 'should tokenize non-ASCII input in time comparable to ASCII input' do
    n = 10_000

    # Identical token structure and character counts; only the byte width of
    # the identifiers differs. Without byte-based slicing, the non-ASCII variant
    # is many times slower (superlinear) than the ASCII variant.
    ascii = 'a:b;' * n
    utf8  = "\u{1f600}:\u{1f600};" * n

    ascii_time = best_time { CP.parse_properties(ascii) }
    utf8_time  = best_time { CP.parse_properties(utf8) }

    # The non-ASCII payload should not take dramatically longer than the ASCII
    # one. On unpatched code this ratio is ~15-20x; with byte-based slicing it
    # is close to 1x. A generous 5x bound reliably distinguishes the two while
    # tolerating machine and scheduling noise.
    assert_operator utf8_time, :<=, ascii_time * 5,
      "non-ASCII tokenizing was #{(utf8_time / ascii_time).round(1)}x slower " \
      "than ASCII (ascii=#{ascii_time.round(4)}s, utf8=#{utf8_time.round(4)}s)"
  end
end
