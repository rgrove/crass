# encoding: utf-8

# Includes tests based on Simon Sapin's CSS parsing tests:
# https://github.com/SimonSapin/css-parsing-tests/

require_relative 'support/common'

describe 'Crass::Parser' do
  make_my_diffs_pretty!
  parallelize_me!

  describe '#parse_properties' do
    def parse(*args)
      CP.parse_properties(*args)
    end

    it 'should return an empty tree when given an empty string' do
      assert_equal([], parse(""))
    end

    # Note: The next two tests verify augmented behavior that isn't defined in
    # CSS Syntax Module Level 3.
    it 'should include semicolon and whitespace tokens' do
      assert_tokens(";; /**/ ; ;", parse(";; /**/ ; ;"))
    end

    it 'should include semicolon, whitespace, and comment tokens when :preserve_comments == true' do
      tree = parse(";; /**/ ; ;", :preserve_comments => true)
      assert_tokens(";; /**/ ; ;", tree, 0, :preserve_comments => true)
    end

    it 'should parse a list of declarations' do
      tree = parse("a:b; c:d 42!important;\n")
      assert_equal(4, tree.size)

      prop = tree[0]
      assert_equal(:property, prop[:node])
      assert_equal("a", prop[:name])
      assert_equal("b", prop[:value])
      assert_equal(false, prop[:important])
      assert_tokens("a:b;", prop[:tokens])

      assert_tokens(" ", tree[1], 4)

      prop = tree[2]
      assert_equal(:property, prop[:node])
      assert_equal("c", prop[:name])
      assert_equal("d 42", prop[:value])
      assert_equal(true, prop[:important])
      assert_tokens("c:d 42!important;", prop[:tokens], 5)

      assert_tokens("\n", tree[3], 22)
    end

    it 'should parse at-rules even though they may be invalid in the given context' do
      tree = parse("@import 'foo.css'; a:b; @import 'bar.css'")
      assert_equal(5, tree.size)

      rule = tree[0]
      assert_equal(:at_rule, rule[:node])
      assert_equal("import", rule[:name])
      assert_tokens(" 'foo.css'", rule[:prelude], 7)
      assert_tokens("@import 'foo.css';", rule[:tokens])

      assert_tokens(" ", tree[1], 18)

      prop = tree[2]
      assert_equal(:property, prop[:node])
      assert_equal("a", prop[:name])
      assert_equal("b", prop[:value])
      assert_equal(false, prop[:important])
      assert_tokens("a:b;", prop[:tokens], 19)

      assert_tokens(" ", tree[3], 23)

      rule = tree[4]
      assert_equal(:at_rule, rule[:node])
      assert_equal("import", rule[:name])
      assert_tokens(" 'bar.css'", rule[:prelude], 31)
      assert_tokens("@import 'bar.css'", rule[:tokens], 24)
    end

    it 'should not be fazed by extra semicolons or unclosed blocks' do
      tree = parse("@media screen { div{;}} a:b;; @media print{div{")
      assert_equal(6, tree.size)

      rule = tree[0]
      assert_equal(:at_rule, rule[:node])
      assert_equal("media", rule[:name])
      assert_tokens(" screen ", rule[:prelude], 6)
      assert_tokens("@media screen { div{;}}", rule[:tokens])

      block = rule[:block]
      assert_equal(:simple_block, block[:node])
      assert_equal("{", block[:start])
      assert_equal("}", block[:end])
      assert_tokens("{ div{;}}", block[:tokens], 14)

      value = block[:value]
      assert_equal(3, value.size)
      assert_tokens(" div", value[0..1], 15)

      block = value[2]
      assert_equal(:simple_block, block[:node])
      assert_equal("{", block[:start])
      assert_equal("}", block[:end])
      assert_tokens(";", block[:value], 20)
      assert_tokens("{;}", block[:tokens], 19)

      assert_tokens(" ", tree[1], 23)

      prop = tree[2]
      assert_equal(:property, prop[:node])
      assert_equal("a", prop[:name])
      assert_equal("b", prop[:value])
      assert_equal(false, prop[:important])
      assert_tokens("a:b;", prop[:tokens], 24)

      assert_tokens("; ", tree[3..4], 28)

      rule = tree[5]
      assert_equal(:at_rule, rule[:node])
      assert_equal("media", rule[:name])
      assert_tokens(" print", rule[:prelude], 36)
      assert_tokens("@media print{div{", rule[:tokens], 30)

      block = rule[:block]
      assert_equal(:simple_block, block[:node])
      assert_equal("{", block[:start])
      assert_equal("}", block[:end])
      assert_tokens("{div{", block[:tokens], 42)

      value = block[:value]
      assert_equal(2, value.size)
      assert_tokens("div", value[0], 43)

      block = value[1]
      assert_equal(:simple_block, block[:node])
      assert_equal("{", block[:start])
      assert_equal("}", block[:end])
      assert_equal([], block[:value])
      assert_tokens("{", block[:tokens], 46)
    end

    it 'should discard invalid nodes' do
      tree = parse("@ media screen { div{;}} a:b;; @media print{div{")
      assert_equal(3, tree.size)

      assert_tokens("; ", tree[0..1], 29)

      rule = tree[2]
      assert_equal(:at_rule, rule[:node])
      assert_equal("media", rule[:name])
      assert_tokens(" print", rule[:prelude], 37)
      assert_tokens("@media print{div{", rule[:tokens], 31)

      block = rule[:block]
      assert_equal(:simple_block, block[:node])
      assert_equal("{", block[:start])
      assert_equal("}", block[:end])
      assert_tokens("{div{", block[:tokens], 43)

      value = block[:value]
      assert_equal(2, value.size)
      assert_tokens("div", value[0], 44)

      block = value[1]
      assert_equal(:simple_block, block[:node])
      assert_equal("{", block[:start])
      assert_equal("}", block[:end])
      assert_equal([], block[:value])
      assert_tokens("{", block[:tokens], 47)
    end
  end
end
