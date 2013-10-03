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

