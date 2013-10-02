# encoding: utf-8

# Includes tests based on Simon Sapin's CSS parsing tests:
# https://github.com/SimonSapin/css-parsing-tests/

require_relative 'support/common'
require_relative 'shared/parse_rules'

describe 'Crass::Parser' do
  make_my_diffs_pretty!
  parallelize_me!

  describe '#parse_stylesheet' do
    def parse(*args)
      CP.parse_stylesheet(*args)
    end

    behaves_like 'parsing a list of rules'

    it 'with CDO/CDC before rule' do
      tree = parse(" <!-- --> {")

      assert_equal(4, tree.size)

      tree[0..2].each do |node|
        assert_equal(:whitespace, node[:node])
      end

      rule = tree[3]
      assert_equal(:style_rule, rule[:node])
      assert_equal([], rule[:children])

      selector = rule[:selector]
      assert_equal(:selector, selector[:node])
      assert_equal("", selector[:value])
      assert_equal([], selector[:tokens])
    end

    it 'followed by CDC' do
      tree = parse("div {} -->")

      assert_equal(2, tree.size)

      rule = tree[0]
      assert_equal(:style_rule, rule[:node])
      assert_equal([], rule[:children])

      selector = rule[:selector]
      assert_equal(:selector, selector[:node])
      assert_equal("div", selector[:value])
      assert_tokens("div ", selector[:tokens])

      assert_tokens(" ", tree[1], 6)
    end
  end
end
