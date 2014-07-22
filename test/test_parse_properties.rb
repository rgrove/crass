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

      assert_equal([
        {:node=>:ident, :pos=>2, :raw=>"b", :value=>"b"}
      ], prop[:children])

      assert_tokens(" ", tree[1], 4)

      prop = tree[2]
      assert_equal(:property, prop[:node])
      assert_equal("c", prop[:name])
      assert_equal("d 42", prop[:value])
      assert_equal(true, prop[:important])
      assert_tokens("c:d 42!important;", prop[:tokens], 5)

      assert_equal([
        {:node=>:ident, :pos=>7, :raw=>"d", :value=>"d"},
        {:node=>:whitespace, :pos=>8, :raw=>" "},
        {:node=>:number,
         :pos=>9,
         :raw=>"42",
         :repr=>"42",
         :type=>:integer,
         :value=>42}
      ], prop[:children])

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

      assert_equal([
        {:node=>:ident, :pos=>21, :raw=>"b", :value=>"b"}
      ], prop[:children])

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
      assert_equal([
        {:node=>:ident, :pos=>26, :raw=>"b", :value=>"b"}
      ], prop[:children])

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

    it 'should parse values containing functions' do
      tree = parse("content: attr(data-foo) \" \";")

      assert_equal([
        {:node=>:property,
         :name=>"content",
         :value=>"attr(data-foo) \" \"",
         :important=>false,
         :children=>
          [{:node=>:whitespace, :pos=>8, :raw=>" "},
           {:node=>:function, :pos=>9, :raw=>"attr(", :value=>"attr"},
           {:node=>:ident, :pos=>14, :raw=>"data-foo", :value=>"data-foo"},
           {:node=>:")", :pos=>22, :raw=>")"},
           {:node=>:whitespace, :pos=>23, :raw=>" "},
           {:node=>:string, :pos=>24, :raw=>"\" \"", :value=>" "}],
         :tokens=>
          [{:node=>:ident, :pos=>0, :raw=>"content", :value=>"content"},
           {:node=>:colon, :pos=>7, :raw=>":"},
           {:node=>:whitespace, :pos=>8, :raw=>" "},
           {:node=>:function, :pos=>9, :raw=>"attr(", :value=>"attr"},
           {:node=>:ident, :pos=>14, :raw=>"data-foo", :value=>"data-foo"},
           {:node=>:")", :pos=>22, :raw=>")"},
           {:node=>:whitespace, :pos=>23, :raw=>" "},
           {:node=>:string, :pos=>24, :raw=>"\" \"", :value=>" "},
           {:node=>:semicolon, :pos=>27, :raw=>";"}]}
        ], tree)
    end

    it 'should parse values containing nested functions' do
      tree = parse("width: expression(alert(1));")

      assert_equal([
        {:node=>:property,
         :name=>"width",
         :value=>"expression(alert(1))",
         :important=>false,
         :children=>
          [{:node=>:whitespace, :pos=>6, :raw=>" "},
           {:node=>:function, :pos=>7, :raw=>"expression(", :value=>"expression"},
           {:node=>:function, :pos=>18, :raw=>"alert(", :value=>"alert"},
           {:node=>:number,
            :pos=>24,
            :raw=>"1",
            :repr=>"1",
            :type=>:integer,
            :value=>1},
           {:node=>:")", :pos=>25, :raw=>")"},
           {:node=>:")", :pos=>26, :raw=>")"}],
         :tokens=>
          [{:node=>:ident, :pos=>0, :raw=>"width", :value=>"width"},
           {:node=>:colon, :pos=>5, :raw=>":"},
           {:node=>:whitespace, :pos=>6, :raw=>" "},
           {:node=>:function, :pos=>7, :raw=>"expression(", :value=>"expression"},
           {:node=>:function, :pos=>18, :raw=>"alert(", :value=>"alert"},
           {:node=>:number,
            :pos=>24,
            :raw=>"1",
            :repr=>"1",
            :type=>:integer,
            :value=>1},
           {:node=>:")", :pos=>25, :raw=>")"},
           {:node=>:")", :pos=>26, :raw=>")"},
           {:node=>:semicolon, :pos=>27, :raw=>";"}]}
        ], tree)
    end

    it 'should handle bad css without breaking' do
      tree = parse("font-family:")

      assert_equal([
       {:node=>:property,
        :name=>"font-family",
        :value=>"",
        :children=>[],
        :important=>false,
        :tokens=>
         [{:node=>:ident, :pos=>0, :raw=>"font-family", :value=>"font-family"},
          {:node=>:colon, :pos=>11, :raw=>":"}]}
      ], tree)
    end
  end
end
