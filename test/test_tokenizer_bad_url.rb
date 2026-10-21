# encoding: utf-8

# Regression tests ensuring that a bad URL token terminates at the same place a
# spec-compliant browser would terminate it. If Crass consumes more of a bad URL
# than a browser does, then CSS sanitizers built on Crass can be tricked into
# passing through declarations, rules, or at-rules that a browser will apply.
#
# Backslashes are built from `bs` rather than written as string escapes to keep
# it unambiguous how many literal backslashes each input contains.

require_relative 'support/common'

describe 'Crass::Tokenizer bad URL handling' do
  make_my_diffs_pretty!
  parallelize_me!

  let(:bs) { '\\' }

  # Literal transcription of css-syntax-3 "consume the remnants of a bad url".
  # Returns the number of code points of _input_ that would be consumed.
  def spec_remnants_length(input)
    i = 0

    while i < input.length
      char = input[i]
      i += 1

      return i if char == ')'
      next unless char == bs && input[i] != "\n"

      # Consume an escaped code point.
      next if i >= input.length

      if input[i] =~ /\h/
        count = 0

        while count < 6 && i < input.length && input[i] =~ /\h/
          i += 1
          count += 1
        end

        i += 1 if i < input.length && input[i] =~ /[ \t\n]/
      else
        i += 1
      end
    end

    i
  end

  def tokens(css)
    Crass::Tokenizer.tokenize(css).map { |t| [t[:node], t[:raw]] }
  end

  it 'should terminate at ) after an escaped backslash' do
    assert_equal(
      [[:bad_url, "url(x\"#{bs * 2})"], [:ident, 'after']],
      tokens("url(x\"#{bs * 2})after"))
  end

  it 'should terminate at ) after an even run of backslashes' do
    assert_equal(
      [[:bad_url, "url(x\"#{bs * 4})"], [:ident, 'after']],
      tokens("url(x\"#{bs * 4})after"))
  end

  it 'should not terminate at an escaped )' do
    assert_equal(
      [[:bad_url, "url(x\"#{bs})after"]],
      tokens("url(x\"#{bs})after"))

    assert_equal(
      [[:bad_url, "url(x\"#{bs * 3})after"]],
      tokens("url(x\"#{bs * 3})after"))
  end

  it 'should terminate at ) after a hex escape' do
    assert_equal(
      [[:bad_url, "url(x\"#{bs}5c)"], [:ident, 'after']],
      tokens("url(x\"#{bs}5c)after"))
  end

  # A hex escape can't consume a `)`, so these check the decoded value rather
  # than where the token ends.
  it 'should decode hex escapes of at most six digits plus one whitespace' do
    {
      "00005c5)"  => "x#{bs}5",
      "00005c\t)" => "x#{bs}",
      "5c\t)"     => "x#{bs}",
      "5c )"      => "x#{bs}",
      "5c\n)"     => "x#{bs}",
    }.each do |escape, value|
      token = Crass::Tokenizer.tokenize("url(x\"#{bs}#{escape}").first

      assert_equal(:bad_url, token[:node])
      assert_equal(value, token[:value], "escape #{escape.inspect}")
    end
  end

  it 'should terminate at ) after an escaped backslash regardless of what caused the bad URL' do
    ["\"", "'", '(', " b", "\u0001", "#{bs}\n"].each do |trigger|
      prefix = "url(a#{trigger}#{bs * 2})"

      assert_equal(
        [[:bad_url, prefix], [:ident, 'after']],
        tokens("#{prefix}after"),
        "bad URL triggered by #{trigger.inspect}")
    end
  end

  it 'should not swallow the rest of a declaration list' do
    tree = Crass.parse_properties("color:[url(x\"#{bs * 2})]; position:fixed")
    properties = tree.select { |node| node[:node] == :property }

    assert_equal(%w[color position], properties.map { |node| node[:name] })
  end

  it 'should not swallow subsequent rules in a stylesheet' do
    tree  = Crass.parse("a url(x\"#{bs * 2}){} b{color:red}")
    rules = tree.select { |node| node[:node] == :style_rule }

    assert_equal(["a url(x\"#{bs * 2})", 'b'], rules.map { |node| node[:selector][:value] })
  end

  it 'should round-trip affected input unchanged when stringified' do
    [
      "color:[url(x\"#{bs * 2})]; position:fixed",
      "width:calc(url(x\"#{bs * 2})); position:fixed; x:))",
    ].each do |css|
      assert_equal(css, Crass::Parser.stringify(Crass.parse_properties(css)))
    end

    css = "a url(x\"#{bs * 2}){} @import url(https://example.com/x.css); b){color:red}"
    assert_equal(css, Crass::Parser.stringify(Crass.parse(css)))
  end

  it 'should terminate exactly where the spec says for all short inputs' do
    alphabet   = [bs, ')', 'a', "\n", '5', ' ', 'c']
    prefix     = 'url(x"'
    mismatches = []

    (0..5).each do |length|
      alphabet.repeated_permutation(length) do |chars|
        remnants = chars.join
        actual   = Crass::Tokenizer.tokenize(prefix + remnants).first[:raw]
        expected = prefix + remnants[0, spec_remnants_length(remnants)]

        mismatches << remnants unless actual == expected
      end
    end

    assert_empty(mismatches.first(10), "#{mismatches.size} inputs mismatched")
  end
end
