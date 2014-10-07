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

    it 'should parse at-rules even though they may be invalid in the given context' do
      tree = parse("@import 'foo.css'; a:b; @import 'bar.css'")

      assert_equal([
        {:node=>:at_rule,
          :name=>"import",
          :prelude=>
           [{:node=>:whitespace, :pos=>7, :raw=>" "},
            {:node=>:string, :pos=>8, :raw=>"'foo.css'", :value=>"foo.css"}],
          :tokens=>
           [{:node=>:at_keyword, :pos=>0, :raw=>"@import", :value=>"import"},
            {:node=>:whitespace, :pos=>7, :raw=>" "},
            {:node=>:string, :pos=>8, :raw=>"'foo.css'", :value=>"foo.css"},
            {:node=>:semicolon, :pos=>17, :raw=>";"}]},
         {:node=>:whitespace, :pos=>18, :raw=>" "},
         {:node=>:property,
          :name=>"a",
          :value=>"b",
          :children=>[{:node=>:ident, :pos=>21, :raw=>"b", :value=>"b"}],
          :important=>false,
          :tokens=>
           [{:node=>:ident, :pos=>19, :raw=>"a", :value=>"a"},
            {:node=>:colon, :pos=>20, :raw=>":"},
            {:node=>:ident, :pos=>21, :raw=>"b", :value=>"b"}]},
         {:node=>:semicolon, :pos=>22, :raw=>";"},
         {:node=>:whitespace, :pos=>23, :raw=>" "},
         {:node=>:at_rule,
          :name=>"import",
          :prelude=>
           [{:node=>:whitespace, :pos=>31, :raw=>" "},
            {:node=>:string, :pos=>32, :raw=>"'bar.css'", :value=>"bar.css"}],
          :tokens=>
           [{:node=>:at_keyword, :pos=>24, :raw=>"@import", :value=>"import"},
            {:node=>:whitespace, :pos=>31, :raw=>" "},
            {:node=>:string, :pos=>32, :raw=>"'bar.css'", :value=>"bar.css"}]}
      ], tree)
    end

    it 'should parse values containing functions' do
      tree = parse("content: attr(data-foo) \" \";")

      assert_equal([
        {:node=>:property,
          :name=>"content",
          :value=>"attr(data-foo) \" \"",
          :children=>
           [{:node=>:whitespace, :pos=>8, :raw=>" "},
            {:node=>:function,
             :name=>"attr",
             :value=>[{:node=>:ident, :pos=>14, :raw=>"data-foo", :value=>"data-foo"}],
             :tokens=>
              [{:node=>:function, :pos=>9, :raw=>"attr(", :value=>"attr"},
               {:node=>:ident, :pos=>14, :raw=>"data-foo", :value=>"data-foo"},
               {:node=>:")", :pos=>22, :raw=>")"}]},
            {:node=>:whitespace, :pos=>23, :raw=>" "},
            {:node=>:string, :pos=>24, :raw=>"\" \"", :value=>" "}],
          :important=>false,
          :tokens=>
           [{:node=>:ident, :pos=>0, :raw=>"content", :value=>"content"},
            {:node=>:colon, :pos=>7, :raw=>":"},
            {:node=>:whitespace, :pos=>8, :raw=>" "},
            {:node=>:function,
             :name=>"attr",
             :value=>[{:node=>:ident, :pos=>14, :raw=>"data-foo", :value=>"data-foo"}],
             :tokens=>
              [{:node=>:function, :pos=>9, :raw=>"attr(", :value=>"attr"},
               {:node=>:ident, :pos=>14, :raw=>"data-foo", :value=>"data-foo"},
               {:node=>:")", :pos=>22, :raw=>")"}]},
            {:node=>:whitespace, :pos=>23, :raw=>" "},
            {:node=>:string, :pos=>24, :raw=>"\" \"", :value=>" "}]},
         {:node=>:semicolon, :pos=>27, :raw=>";"}
      ], tree)
    end

    it 'should parse values containing nested functions' do
      tree = parse("width: expression(alert(1));")

      assert_equal([
        {:node=>:property,
          :name=>"width",
          :value=>"expression(alert(1))",
          :children=>
           [{:node=>:whitespace, :pos=>6, :raw=>" "},
            {:node=>:function,
             :name=>"expression",
             :value=>
              [{:node=>:function,
                :name=>"alert",
                :value=>
                 [{:node=>:number,
                   :pos=>24,
                   :raw=>"1",
                   :repr=>"1",
                   :type=>:integer,
                   :value=>1}],
                :tokens=>
                 [{:node=>:function, :pos=>18, :raw=>"alert(", :value=>"alert"},
                  {:node=>:number,
                   :pos=>24,
                   :raw=>"1",
                   :repr=>"1",
                   :type=>:integer,
                   :value=>1},
                  {:node=>:")", :pos=>25, :raw=>")"}]}],
             :tokens=>
              [{:node=>:function, :pos=>7, :raw=>"expression(", :value=>"expression"},
               {:node=>:function, :pos=>18, :raw=>"alert(", :value=>"alert"},
               {:node=>:number,
                :pos=>24,
                :raw=>"1",
                :repr=>"1",
                :type=>:integer,
                :value=>1},
               {:node=>:")", :pos=>25, :raw=>")"},
               {:node=>:")", :pos=>26, :raw=>")"}]}],
          :important=>false,
          :tokens=>
           [{:node=>:ident, :pos=>0, :raw=>"width", :value=>"width"},
            {:node=>:colon, :pos=>5, :raw=>":"},
            {:node=>:whitespace, :pos=>6, :raw=>" "},
            {:node=>:function,
             :name=>"expression",
             :value=>
              [{:node=>:function,
                :name=>"alert",
                :value=>
                 [{:node=>:number,
                   :pos=>24,
                   :raw=>"1",
                   :repr=>"1",
                   :type=>:integer,
                   :value=>1}],
                :tokens=>
                 [{:node=>:function, :pos=>18, :raw=>"alert(", :value=>"alert"},
                  {:node=>:number,
                   :pos=>24,
                   :raw=>"1",
                   :repr=>"1",
                   :type=>:integer,
                   :value=>1},
                  {:node=>:")", :pos=>25, :raw=>")"}]}],
             :tokens=>
              [{:node=>:function, :pos=>7, :raw=>"expression(", :value=>"expression"},
               {:node=>:function, :pos=>18, :raw=>"alert(", :value=>"alert"},
               {:node=>:number,
                :pos=>24,
                :raw=>"1",
                :repr=>"1",
                :type=>:integer,
                :value=>1},
               {:node=>:")", :pos=>25, :raw=>")"},
               {:node=>:")", :pos=>26, :raw=>")"}]}]},
         {:node=>:semicolon, :pos=>27, :raw=>";"}
      ], tree)
    end

    it 'should not choke on a missing property value' do
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
