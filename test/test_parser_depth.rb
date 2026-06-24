# encoding: utf-8

# Regression tests for the nesting-depth guard that prevents deeply nested
# simple blocks and functions from exhausting the Ruby stack
# (`SystemStackError`).

require_relative 'support/common'

describe 'Crass::Parser nesting depth guard' do
  make_my_diffs_pretty!
  parallelize_me!

  # Recursively searches a parse tree for the first node matching the given
  # node type and returns it, or `nil`.
  def find_node(tree, type)
    tree.each do |node|
      next unless node.is_a?(Hash)
      return node if node[:node] == type

      [:value, :children, :prelude, :block, :tokens].each do |key|
        child = node[key]
        next unless child.is_a?(Array)
        found = find_node(child, type)
        return found if found
      end
    end

    nil
  end

  # Recursively sums the lengths of every `:tokens` array in the parse tree.
  # This is a deterministic proxy for the amount of serialization metadata the
  # parser retains, which is what the nesting-depth limit bounds.
  def count_token_slots(tree)
    total = 0

    tree.each do |node|
      next unless node.is_a?(Hash)

      [:value, :children, :prelude, :block, :tokens].each do |key|
        child = node[key]
        next unless child.is_a?(Array)
        total += child.size if key == :tokens
        total += count_token_slots(child)
      end
    end

    total
  end

  describe 'with the default maximum depth' do
    it 'should not raise SystemStackError on a deeply nested property value' do
      depth = 3_000
      css   = "color: #{'(' * depth}red#{')' * depth}"

      tree = Crass.parse_properties(css)
      refute_nil(tree)
    end

    it 'should not raise SystemStackError on a deeply nested stylesheet' do
      depth = 3_000
      css   = "a { color: #{'(' * depth}red#{')' * depth} }"

      tree = Crass.parse(css)
      refute_nil(tree)
    end

    it 'should not raise SystemStackError on a deeply nested function value' do
      depth = 3_000
      css   = "width: #{'a(' * depth}#{')' * depth}"

      tree = Crass.parse_properties(css)
      refute_nil(tree)
    end
  end

  describe 'with a low configured maximum depth' do
    options = {:maximum_depth => 5}

    [['(', ')'], ['[', ']'], ['{', '}']].each do |open_char, close_char|
      it "should discard `#{open_char}` blocks nested just above the limit" do
        depth = 6 # one deeper than :maximum_depth
        css   = "color: #{open_char * depth}red#{close_char * depth}"

        tree  = Crass.parse_properties(css, options)

        error = find_node(tree, :error)
        refute_nil(error, 'expected an :error node for the over-nested block')
        assert_equal('maximum-depth-exceeded', error[:value])
      end
    end

    it 'should discard functions nested just above the limit' do
      depth = 6
      css   = "width: #{'a(' * depth}#{')' * depth}"

      tree  = Crass.parse_properties(css, options)

      error = find_node(tree, :error)
      refute_nil(error, 'expected an :error node for the over-nested function')
      assert_equal('maximum-depth-exceeded', error[:value])
    end

    it 'should discard over-nested blocks reached via parse_component_value' do
      depth  = 6
      css    = "#{'(' * depth}red#{')' * depth}"
      parser = Crass::Parser.new(css, options)

      value = parser.parse_component_value

      error = find_node([value], :error)
      refute_nil(error, 'expected an :error node for the over-nested block')
      assert_equal('maximum-depth-exceeded', error[:value])
    end

    it 'should discard over-nested blocks reached via parse_rules' do
      depth = 6
      css   = "a { color: #{'(' * depth}red#{')' * depth} }"

      tree  = Crass::Parser.parse_rules(css, options)

      error = find_node(tree, :error)
      refute_nil(error, 'expected an :error node for the over-nested block')
      assert_equal('maximum-depth-exceeded', error[:value])
    end

    it 'should still parse nesting at or below the limit normally' do
      depth = 5 # exactly :maximum_depth
      css   = "color: #{'(' * depth}red#{')' * depth}"

      tree     = Crass.parse_properties(css, options)
      property = find_node(tree, :property)

      refute_nil(property)
      assert_nil(find_node(tree, :error))
      refute_nil(find_node(tree, :simple_block))
    end

    it 'should reset the depth counter between sibling constructs' do
      depth = 6
      css   = "color: #{'(' * depth}red#{')' * depth} blue"

      tree  = Crass.parse_properties(css, options)
      error = find_node(tree, :error)

      # The over-nested block becomes an error node, but the sibling `blue`
      # ident that follows it must still be parsed normally, proving the depth
      # counter was decremented after the discarded block.
      refute_nil(error)
      assert_equal('maximum-depth-exceeded', error[:value])
      refute_nil(find_node(tree, :ident))
    end
  end

  describe 'with the default maximum depth value' do
    it 'should default to a depth of 25' do
      assert_equal(25, Crass::Parser::DEFAULT_MAXIMUM_DEPTH)
    end

    it 'should parse nesting at the default limit normally' do
      depth = Crass::Parser::DEFAULT_MAXIMUM_DEPTH
      css   = "color: #{'(' * depth}red#{')' * depth}"

      tree = Crass.parse_properties(css)

      assert_nil(find_node(tree, :error))
      refute_nil(find_node(tree, :simple_block))
    end

    it 'should discard nesting just above the default limit' do
      depth = Crass::Parser::DEFAULT_MAXIMUM_DEPTH + 1
      css   = "color: #{'(' * depth}red#{')' * depth}"

      tree  = Crass.parse_properties(css)
      error = find_node(tree, :error)

      refute_nil(error, 'expected an :error node for the over-nested block')
      assert_equal('maximum-depth-exceeded', error[:value])
    end

    it 'should bound retained serialization tokens for deeply nested input' do
      # Without the depth limit, every one of the deeply nested ancestor blocks
      # would retain a `:tokens` array spanning the full inner token stream,
      # making the retained metadata grow roughly quadratically. With the limit,
      # the over-nested blocks are discarded, so the retained metadata stays
      # bounded regardless of how deep the input claims to nest.
      depth = 500
      inner = 2_000
      css   = "a{x:#{'(' * depth}#{';' * inner}#{')' * depth}}"

      tree   = Crass.parse(css)
      slots  = count_token_slots(tree)

      # At depth 500 the retained tokens would be on the order of depth * inner
      # (~1,000,000). With the default limit of 25 it stays an order of
      # magnitude below that.
      assert_operator(slots, :<, 300_000,
        "retained token slots (#{slots}) should be bounded by the depth limit")
    end
  end
end

