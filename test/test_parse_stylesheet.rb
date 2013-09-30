# encoding: utf-8

# Includes tests based on Simon Sapin's CSS parsing tests:
# https://github.com/SimonSapin/css-parsing-tests/

require_relative 'support/common'

describe 'Crass::Parser' do
  describe '#parse_stylesheet' do
    it 'should parse an empty stylesheet' do
      assert_equal [], CP.parse_stylesheet('')
      assert_equal [], CP.parse_stylesheet('foo')
      assert_equal [], CP.parse_stylesheet('foo 4')
    end

    describe 'should parse an at-rule' do
      describe 'without a block' do
        it 'without a prelude' do
          tree = CP.parse_stylesheet('@foo')
          rule = tree[0]

          assert_equal 1, tree.size
          assert_equal :at_rule, rule[:node]
          assert_equal "foo", rule[:name]
          assert_equal [], rule[:prelude]
          assert_tokens "@foo", rule[:tokens]
        end

        it 'with a prelude followed by a comment' do
          tree = CP.parse_stylesheet("@foo bar; \t/* comment */")
          rule = tree[0]

          assert_equal 2, tree.size
          assert_equal :at_rule, rule[:node]
          assert_equal "foo", rule[:name]
          assert_tokens " bar", rule[:prelude], 4
          assert_tokens "@foo bar;", rule[:tokens]
          assert_tokens " \t", tree[1], 9
        end

        it 'with a prelude followed by a comment, when :preserve_comments == true' do
          options = {:preserve_comments => true}
          tree    = CP.parse_stylesheet("@foo bar; \t/* comment */", options)
          rule    = tree[0]

          assert_equal 3, tree.size
          assert_equal :at_rule, rule[:node]
          assert_equal "foo", rule[:name]
          assert_tokens " bar", rule[:prelude], 4, options
          assert_tokens "@foo bar;", rule[:tokens], 0, options
          assert_tokens " \t", tree[1], 9, options
          assert_tokens "/* comment */", tree[2], 11, options
        end

        it 'with a prelude containing a simple block' do
          tree = CP.parse_stylesheet("@foo [ bar")
          rule = tree[0]

          assert_equal 1, tree.size
          assert_equal :at_rule, rule[:node]
          assert_equal "foo", rule[:name]
          assert_tokens "@foo [ bar", rule[:tokens]

          prelude = rule[:prelude]
          assert_equal 2, prelude.size
          assert_tokens " ", prelude[0], 4

          block = prelude[1]
          assert_equal :simple_block, block[:node]
          assert_equal "[", block[:start]
          assert_equal "]", block[:end]
          assert_tokens "[ bar", block[:tokens], 5
          assert_tokens " bar", block[:value], 6
        end
      end

      describe 'with a block' do
        it 'unclosed' do
          tree = CP.parse_stylesheet("@foo { bar")
          rule = tree[0]

          assert_equal 1, tree.size
          assert_equal :at_rule, rule[:node]
          assert_equal "foo", rule[:name]
          assert_tokens " ", rule[:prelude], 4
          assert_tokens "@foo { bar", rule[:tokens]

          block = rule[:block]
          assert_equal :simple_block, block[:node]
          assert_equal "{", block[:start]
          assert_equal "}", block[:end]
          assert_tokens "{ bar", block[:tokens], 5
          assert_tokens " bar", block[:value], 6
        end

        it 'unclosed, preceded by a comment' do
          tree = CP.parse_stylesheet(" /**/ @foo bar{[(4")
          rule = tree[2]

          assert_equal 3, tree.size
          assert_tokens " /**/ ", tree[0..1]
          assert_equal :at_rule, rule[:node]
          assert_equal "foo", rule[:name]
          assert_tokens " bar", rule[:prelude], 10
          assert_tokens "@foo bar{[(4", rule[:tokens], 6

          block = rule[:block]
          assert_equal :simple_block, block[:node]
          assert_equal "{", block[:start]
          assert_equal "}", block[:end]
          assert_tokens "{[(4", block[:tokens], 14
          assert_equal 1, block[:value].size

          block = block[:value].first
          assert_equal :simple_block, block[:node]
          assert_equal "[", block[:start]
          assert_equal "]", block[:end]
          assert_tokens "[(4", block[:tokens], 15
          assert_equal 1, block[:value].size

          block = block[:value].first
          assert_equal :simple_block, block[:node]
          assert_equal "(", block[:start]
          assert_equal ")", block[:end]
          assert_tokens "(4", block[:tokens], 16
          assert_tokens "4", block[:value], 17
        end

        it 'unclosed, preceded by a comment, when :preserve_comments == true' do
          options = {:preserve_comments => true}
          tree    = CP.parse_stylesheet(" /**/ @foo bar{[(4", options)
          rule    = tree[3]

          assert_equal 4, tree.size
          assert_tokens " /**/ ", tree[0..2], 0, options

          assert_equal :at_rule, rule[:node]
          assert_equal "foo", rule[:name]
          assert_tokens " bar", rule[:prelude], 10, options
          assert_tokens "@foo bar{[(4", rule[:tokens], 6, options

          block = rule[:block]
          assert_equal :simple_block, block[:node]
          assert_equal "{", block[:start]
          assert_equal "}", block[:end]
          assert_tokens "{[(4", block[:tokens], 14, options
          assert_equal 1, block[:value].size

          block = block[:value].first
          assert_equal :simple_block, block[:node]
          assert_equal "[", block[:start]
          assert_equal "]", block[:end]
          assert_tokens "[(4", block[:tokens], 15, options
          assert_equal 1, block[:value].size

          block = block[:value].first
          assert_equal :simple_block, block[:node]
          assert_equal "(", block[:start]
          assert_equal ")", block[:end]
          assert_tokens "(4", block[:tokens], 16, options
          assert_tokens "4", block[:value], 17, options
        end

      end
    end

    describe 'should parse a style rule' do
      it 'with preceding comment, selector, block, comment' do
        tree = CP.parse_stylesheet(" /**/ div > p { color: #aaa;  } /**/ ")

        assert_equal 5, tree.size
        assert_tokens " /**/ ", tree[0..1]
        assert_tokens " /**/ ", tree[3..4], 31

        rule = tree[2]
        assert_equal :style_rule, rule[:node]

        selector = rule[:selector]
        assert_equal :selector, selector[:node]
        assert_equal "div > p", selector[:value]
        assert_tokens "div > p ", selector[:tokens], 6

        children = rule[:children]
        assert_equal 3, children.size
        assert_tokens " ", children[0], 15
        assert_tokens "  ", children[2], 28

        property = children[1]
        assert_equal :property, property[:node]
        assert_equal "color", property[:name]
        assert_equal "#aaa", property[:value]
        assert_tokens "color: #aaa;", property[:tokens], 16
      end

      it 'with preceding comment, selector, block, comment, when :preserve_comments == true' do
        options = {:preserve_comments => true}
        tree    = CP.parse_stylesheet(" /**/ div > p { color: #aaa;  } /**/ ", options)

        assert_equal 7, tree.size
        assert_tokens " /**/ ", tree[0..2], 0, options
        assert_tokens " /**/ ", tree[4..6], 31, options

        rule = tree[3]
        assert_equal :style_rule, rule[:node]

        selector = rule[:selector]
        assert_equal :selector, selector[:node]
        assert_equal "div > p", selector[:value]
        assert_tokens "div > p ", selector[:tokens], 6, options

        children = rule[:children]
        assert_equal 3, children.size
        assert_tokens " ", children[0], 15, options
        assert_tokens "  ", children[2], 28, options

        property = children[1]
        assert_equal :property, property[:node]
        assert_equal "color", property[:name]
        assert_equal "#aaa", property[:value]
        assert_tokens "color: #aaa;", property[:tokens], 16, options
      end

      it 'unclosed, with preceding comment, no selector' do
        tree = CP.parse_stylesheet(" /**/ { color: #aaa  ")

        assert_equal 3, tree.size
        assert_tokens " /**/ ", tree[0..1]

        rule = tree[2]
        assert_equal :style_rule, rule[:node]

        selector = rule[:selector]
        assert_equal :selector, selector[:node]
        assert_equal "", selector[:value]
        assert_equal [], selector[:tokens]

        children = rule[:children]
        assert_equal 2, children.size
        assert_tokens " ", children[0], 7

        property = children[1]
        assert_equal :property, property[:node]
        assert_equal "color", property[:name]
        assert_equal "#aaa", property[:value]
        assert_tokens "color: #aaa  ", property[:tokens], 8
      end

      it 'unclosed, with preceding comment, no selector, when :preserve_comments == true' do
        options = {:preserve_comments => true}
        tree    = CP.parse_stylesheet(" /**/ { color: #aaa  ", options)

        assert_equal 4, tree.size
        assert_tokens " /**/ ", tree[0..2], 0, options

        rule = tree[3]
        assert_equal :style_rule, rule[:node]

        selector = rule[:selector]
        assert_equal :selector, selector[:node]
        assert_equal "", selector[:value]
        assert_equal [], selector[:tokens]

        children = rule[:children]
        assert_equal 2, children.size
        assert_tokens " ", children[0], 7, options

        property = children[1]
        assert_equal :property, property[:node]
        assert_equal "color", property[:name]
        assert_equal "#aaa", property[:value]
        assert_tokens "color: #aaa  ", property[:tokens], 8, options
      end

      it 'with CDO/CDC before rule' do
        tree = CP.parse_stylesheet(" <!-- --> {")

        assert_equal 4, tree.size

        tree[0..2].each do |node|
          assert_equal :whitespace, node[:node]
        end

        rule = tree[3]
        assert_equal :style_rule, rule[:node]
        assert_equal [], rule[:children]

        selector = rule[:selector]
        assert_equal :selector, selector[:node]
        assert_equal "", selector[:value]
        assert_equal [], selector[:tokens]
      end

      it 'followed by CDC' do
        tree = CP.parse_stylesheet("div {} -->")

        assert_equal 2, tree.size

        rule = tree[0]
        assert_equal :style_rule, rule[:node]
        assert_equal [], rule[:children]

        selector = rule[:selector]
        assert_equal :selector, selector[:node]
        assert_equal "div", selector[:value]
        assert_tokens "div ", selector[:tokens]

        assert_tokens " ", tree[1], 6
      end
    end

    it 'should parse multiple style rules' do
      tree = CP.parse_stylesheet("div { color: #aaa; } p{}")

      assert_equal 3, tree.size

      rule = tree[0]
      assert_equal :style_rule, rule[:node]

      selector = rule[:selector]
      assert_equal :selector, selector[:node]
      assert_equal "div", selector[:value]
      assert_tokens "div ", selector[:tokens]

      children = rule[:children]
      assert_equal 3, children.size
      assert_tokens " ", children[0], 5
      assert_tokens " ", children[2], 18

      prop = children[1]
      assert_equal :property, prop[:node]
      assert_equal "color", prop[:name]
      assert_equal "#aaa", prop[:value]
      assert_tokens "color: #aaa;", prop[:tokens], 6

      assert_tokens " ", tree[1], 20

      rule = tree[2]
      assert_equal :style_rule, rule[:node]

      selector = rule[:selector]
      assert_equal :selector, selector[:node]
      assert_equal "p", selector[:value]
      assert_tokens "p", selector[:tokens], 21
    end

    it 'should ignore a block-less selector following a selector-less style rule' do
      tree = CP.parse_stylesheet("{}a")
      assert_equal 1, tree.size

      rule = tree[0]
      assert_equal :style_rule, rule[:node]
      assert_equal [], rule[:children]

      selector = rule[:selector]
      assert_equal :selector, selector[:node]
      assert_equal "", selector[:value]
      assert_equal [], selector[:tokens]
    end

    it 'should handle an at-rule following a selector-less style rule' do
      tree = CP.parse_stylesheet("{}@a")
      assert_equal 2, tree.size

      rule = tree[0]
      assert_equal :style_rule, rule[:node]
      assert_equal [], rule[:children]

      selector = rule[:selector]
      assert_equal :selector, selector[:node]
      assert_equal "", selector[:value]
      assert_equal [], selector[:tokens]

      rule = tree[1]
      assert_equal :at_rule, rule[:node]
      assert_equal "a", rule[:name]
      assert_equal [], rule[:prelude]
      assert_tokens "@a", rule[:tokens], 2
    end
  end
end
