# encoding: utf-8

# Includes tests based on Simon Sapin's CSS parsing tests:
# https://github.com/SimonSapin/css-parsing-tests/

require_relative 'support/common'
require 'pp'
describe 'Crass::Tokenizer' do
  make_my_diffs_pretty!
  # parallelize_me!

  it 'should tokenize an empty string' do
    assert_equal([], CT.tokenize(""))
  end

  it 'should tokenize comments' do
    tokens = CT.tokenize("/*/*///** /* **/*//* ")

    assert_equal([
      {:node=>:delim, :pos=>5, :raw=>"/", :value=>"/"},
      {:node=>:delim, :pos=>16, :raw=>"*", :value=>"*"},
      {:node=>:delim, :pos=>17, :raw=>"/", :value=>"/"}
    ], tokens)
  end

  it 'should tokenize comments when :preserve_comments == true' do
    tokens = CT.tokenize("/*/*///** /* **/*//* ",
      :preserve_comments => true)

    assert_equal([
      {:node=>:comment, :pos=>0, :raw=>"/*/*/", :value=>"/"},
      {:node=>:delim, :pos=>5, :raw=>"/", :value=>"/"},
      {:node=>:comment, :pos=>6, :raw=>"/** /* **/", :value=>"* /* *"},
      {:node=>:delim, :pos=>16, :raw=>"*", :value=>"*"},
      {:node=>:delim, :pos=>17, :raw=>"/", :value=>"/"},
      {:node=>:comment, :pos=>18, :raw=>"/* ", :value=>" "}
    ], tokens)
  end

  it 'should tokenize an identity' do
    tokens = CT.tokenize("red")

    assert_equal([
      {:node=>:ident, :pos=>0, :raw=>"red", :value=>"red"}
    ], tokens)
  end

  it 'should tokenize an identity preceded and followed by whitespace' do
    tokens = CT.tokenize("  \t\t\r\n\nRed ")

    assert_equal([
      {:node=>:whitespace, :pos=>0, :raw=>"  \t\t\n\n"},
      {:node=>:ident, :pos=>6, :raw=>"Red", :value=>"Red"},
      {:node=>:whitespace, :pos=>9, :raw=>" "}
    ], tokens)
  end

  it 'should tokenize a CDC' do
    tokens = CT.tokenize("red/* CDC */-->")

    assert_equal([
      {:node=>:ident, :pos=>0, :raw=>"red", :value=>"red"},
      {:node=>:cdc, :pos=>12, :raw=>"-->"}
    ], tokens)
  end

  it 'should not be fooled by an ident that appears to be a CDC' do
    tokens = CT.tokenize("red-->/* Not CDC */")

    assert_equal([
      {:node=>:ident, :pos=>0, :raw=>"red--", :value=>"red--"},
      {:node=>:delim, :pos=>5, :raw=>">", :value=>">"}
    ], tokens)
  end

  it 'should tokenize a mix of idents, delims, and dimensions' do
    tokens = CT.tokenize("red0 -red --red -\\-red\\ blue 0red -0red \u0000red _Red .red rêd r\\êd \u007F\u0080\u0081")

    assert_equal([
      {:node=>:ident, :pos=>0, :raw=>"red0", :value=>"red0"},
      {:node=>:whitespace, :pos=>4, :raw=>" "},
      {:node=>:ident, :pos=>5, :raw=>"-red", :value=>"-red"},
      {:node=>:whitespace, :pos=>9, :raw=>" "},
      {:node=>:delim, :pos=>10, :raw=>"-", :value=>"-"},
      {:node=>:ident, :pos=>11, :raw=>"-red", :value=>"-red"},
      {:node=>:whitespace, :pos=>15, :raw=>" "},
      {:node=>:ident, :pos=>16, :raw=>"-\\-red\\ blue", :value=>"--red blue"},
      {:node=>:whitespace, :pos=>28, :raw=>" "},
      {:node=>:dimension,
       :pos=>29,
       :raw=>"0red",
       :repr=>"0",
       :type=>:integer,
       :unit=>"red",
       :value=>0},
      {:node=>:whitespace, :pos=>33, :raw=>" "},
      {:node=>:dimension,
       :pos=>34,
       :raw=>"-0red",
       :repr=>"-0",
       :type=>:integer,
       :unit=>"red",
       :value=>0},
      {:node=>:whitespace, :pos=>39, :raw=>" "},
      {:node=>:ident, :pos=>40, :raw=>"\uFFFDred", :value=>"\uFFFDred"},
      {:node=>:whitespace, :pos=>44, :raw=>" "},
      {:node=>:ident, :pos=>45, :raw=>"_Red", :value=>"_Red"},
      {:node=>:whitespace, :pos=>49, :raw=>" "},
      {:node=>:delim, :pos=>50, :raw=>".", :value=>"."},
      {:node=>:ident, :pos=>51, :raw=>"red", :value=>"red"},
      {:node=>:whitespace, :pos=>54, :raw=>" "},
      {:node=>:ident, :pos=>55, :raw=>"rêd", :value=>"rêd"},
      {:node=>:whitespace, :pos=>58, :raw=>" "},
      {:node=>:ident, :pos=>59, :raw=>"r\\êd", :value=>"rêd"},
      {:node=>:whitespace, :pos=>63, :raw=>" "},
      {:node=>:delim, :pos=>64, :raw=>"\u007F", :value=>"\u007F"},
      {:node=>:ident, :pos=>65, :raw=>"\u0080\u0081", :value=>"\u0080\u0081"}
    ], tokens)
  end

  it 'should consume escape sequences' do
    tokens = CT.tokenize("\\30red \\00030 red \\30\r\nred \\0000000red \\1100000red \\red \\r ed \\.red \\ red \\\nred \\376\\37 6\\000376\\0000376\\")

    assert_equal([
      {:node=>:ident, :pos=>0, :raw=>"\\30red", :value=>"0red"},
      {:node=>:whitespace, :pos=>6, :raw=>" "},
      {:node=>:ident, :pos=>7, :raw=>"\\00030 red", :value=>"0red"},
      {:node=>:whitespace, :pos=>17, :raw=>" "},
      {:node=>:ident, :pos=>18, :raw=>"\\30\nred", :value=>"0red"},
      {:node=>:whitespace, :pos=>25, :raw=>" "},
      {:node=>:ident, :pos=>26, :raw=>"\\0000000red", :value=>"\uFFFD0red"},
      {:node=>:whitespace, :pos=>37, :raw=>" "},
      {:node=>:ident, :pos=>38, :raw=>"\\1100000red", :value=>"\uFFFD0red"},
      {:node=>:whitespace, :pos=>49, :raw=>" "},
      {:node=>:ident, :pos=>50, :raw=>"\\red", :value=>"red"},
      {:node=>:whitespace, :pos=>54, :raw=>" "},
      {:node=>:ident, :pos=>55, :raw=>"\\r", :value=>"r"},
      {:node=>:whitespace, :pos=>57, :raw=>" "},
      {:node=>:ident, :pos=>58, :raw=>"ed", :value=>"ed"},
      {:node=>:whitespace, :pos=>60, :raw=>" "},
      {:node=>:ident, :pos=>61, :raw=>"\\.red", :value=>".red"},
      {:node=>:whitespace, :pos=>66, :raw=>" "},
      {:node=>:ident, :pos=>67, :raw=>"\\ red", :value=>" red"},
      {:node=>:whitespace, :pos=>72, :raw=>" "},
      {:node=>:delim, :pos=>73, :raw=>"\\", :error=>true, :value=>"\\"},
      {:node=>:whitespace, :pos=>74, :raw=>"\n"},
      {:node=>:ident, :pos=>75, :raw=>"red", :value=>"red"},
      {:node=>:whitespace, :pos=>78, :raw=>" "},
      {:node=>:ident,
       :pos=>79,
       :raw=>"\\376\\37 6\\000376\\0000376\\",
       :value=>"Ͷ76Ͷ76\uFFFD"}
    ], tokens)
  end
end

