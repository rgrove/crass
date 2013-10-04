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

  it 'should tokenize functions and hashes' do
    tokens = CT.tokenize("rgba0() -rgba() --rgba() -\\-rgba() 0rgba() -0rgba() _rgba() .rgba() rgbâ() \\30rgba() rgba () @rgba() #rgba()")

    assert_equal([
      {:node=>:function, :pos=>0, :raw=>"rgba0(", :value=>"rgba0"},
      {:node=>:")", :pos=>6, :raw=>")"},
      {:node=>:whitespace, :pos=>7, :raw=>" "},
      {:node=>:function, :pos=>8, :raw=>"-rgba(", :value=>"-rgba"},
      {:node=>:")", :pos=>14, :raw=>")"},
      {:node=>:whitespace, :pos=>15, :raw=>" "},
      {:node=>:delim, :pos=>16, :raw=>"-", :value=>"-"},
      {:node=>:function, :pos=>17, :raw=>"-rgba(", :value=>"-rgba"},
      {:node=>:")", :pos=>23, :raw=>")"},
      {:node=>:whitespace, :pos=>24, :raw=>" "},
      {:node=>:function, :pos=>25, :raw=>"-\\-rgba(", :value=>"--rgba"},
      {:node=>:")", :pos=>33, :raw=>")"},
      {:node=>:whitespace, :pos=>34, :raw=>" "},
      {:node=>:dimension,
       :pos=>35,
       :raw=>"0rgba",
       :repr=>"0",
       :type=>:integer,
       :unit=>"rgba",
       :value=>0},
      {:node=>:"(", :pos=>40, :raw=>"("},
      {:node=>:")", :pos=>41, :raw=>")"},
      {:node=>:whitespace, :pos=>42, :raw=>" "},
      {:node=>:dimension,
       :pos=>43,
       :raw=>"-0rgba",
       :repr=>"-0",
       :type=>:integer,
       :unit=>"rgba",
       :value=>0},
      {:node=>:"(", :pos=>49, :raw=>"("},
      {:node=>:")", :pos=>50, :raw=>")"},
      {:node=>:whitespace, :pos=>51, :raw=>" "},
      {:node=>:function, :pos=>52, :raw=>"_rgba(", :value=>"_rgba"},
      {:node=>:")", :pos=>58, :raw=>")"},
      {:node=>:whitespace, :pos=>59, :raw=>" "},
      {:node=>:delim, :pos=>60, :raw=>".", :value=>"."},
      {:node=>:function, :pos=>61, :raw=>"rgba(", :value=>"rgba"},
      {:node=>:")", :pos=>66, :raw=>")"},
      {:node=>:whitespace, :pos=>67, :raw=>" "},
      {:node=>:function, :pos=>68, :raw=>"rgbâ(", :value=>"rgbâ"},
      {:node=>:")", :pos=>73, :raw=>")"},
      {:node=>:whitespace, :pos=>74, :raw=>" "},
      {:node=>:function, :pos=>75, :raw=>"\\30rgba(", :value=>"0rgba"},
      {:node=>:")", :pos=>83, :raw=>")"},
      {:node=>:whitespace, :pos=>84, :raw=>" "},
      {:node=>:ident, :pos=>85, :raw=>"rgba", :value=>"rgba"},
      {:node=>:whitespace, :pos=>89, :raw=>" "},
      {:node=>:"(", :pos=>90, :raw=>"("},
      {:node=>:")", :pos=>91, :raw=>")"},
      {:node=>:whitespace, :pos=>92, :raw=>" "},
      {:node=>:at_keyword, :pos=>93, :raw=>"@rgba", :value=>"rgba"},
      {:node=>:"(", :pos=>98, :raw=>"("},
      {:node=>:")", :pos=>99, :raw=>")"},
      {:node=>:whitespace, :pos=>100, :raw=>" "},
      {:node=>:hash,
       :pos=>101,
       :raw=>"#rgba",
       :type=>:id,
       :value=>"rgba"},
      {:node=>:"(", :pos=>106, :raw=>"("},
      {:node=>:")", :pos=>107, :raw=>")"}
    ], tokens)
  end

  it 'should tokenize at-rules' do
    tokens = CT.tokenize("@media0 @-Media @--media @-\\-media @0media @-0media @_media @.media @medİa @\\30 media\\")

    assert_equal([
      {:node=>:at_keyword, :pos=>0, :raw=>"@media0", :value=>"media0"},
      {:node=>:whitespace, :pos=>7, :raw=>" "},
      {:node=>:at_keyword, :pos=>8, :raw=>"@-Media", :value=>"-Media"},
      {:node=>:whitespace, :pos=>15, :raw=>" "},
      {:node=>:delim, :pos=>16, :raw=>"@", :value=>"@"},
      {:node=>:delim, :pos=>17, :raw=>"-", :value=>"-"},
      {:node=>:ident, :pos=>18, :raw=>"-media", :value=>"-media"},
      {:node=>:whitespace, :pos=>24, :raw=>" "},
      {:node=>:at_keyword, :pos=>25, :raw=>"@-\\-media", :value=>"--media"},
      {:node=>:whitespace, :pos=>34, :raw=>" "},
      {:node=>:delim, :pos=>35, :raw=>"@", :value=>"@"},
      {:node=>:dimension,
       :pos=>36,
       :raw=>"0media",
       :repr=>"0",
       :type=>:integer,
       :unit=>"media",
       :value=>0},
      {:node=>:whitespace, :pos=>42, :raw=>" "},
      {:node=>:delim, :pos=>43, :raw=>"@", :value=>"@"},
      {:node=>:dimension,
       :pos=>44,
       :raw=>"-0media",
       :repr=>"-0",
       :type=>:integer,
       :unit=>"media",
       :value=>0},
      {:node=>:whitespace, :pos=>51, :raw=>" "},
      {:node=>:at_keyword, :pos=>52, :raw=>"@_media", :value=>"_media"},
      {:node=>:whitespace, :pos=>59, :raw=>" "},
      {:node=>:delim, :pos=>60, :raw=>"@", :value=>"@"},
      {:node=>:delim, :pos=>61, :raw=>".", :value=>"."},
      {:node=>:ident, :pos=>62, :raw=>"media", :value=>"media"},
      {:node=>:whitespace, :pos=>67, :raw=>" "},
      {:node=>:at_keyword, :pos=>68, :raw=>"@medİa", :value=>"medİa"},
      {:node=>:whitespace, :pos=>74, :raw=>" "},
      {:node=>:at_keyword, :pos=>75, :raw=>"@\\30 media\\", :value=>"0media\uFFFD"}
    ], tokens)
  end

  it 'should tokenize hashes' do
    tokens = CT.tokenize("#red0 #-Red #--red #-\\-red #0red #-0red #_Red #.red #rêd #\\.red\\")

    assert_equal([
      {:node=>:hash, :pos=>0, :raw=>"#red0", :type=>:id, :value=>"red0"},
      {:node=>:whitespace, :pos=>5, :raw=>" "},
      {:node=>:hash, :pos=>6, :raw=>"#-Red", :type=>:id, :value=>"-Red"},
      {:node=>:whitespace, :pos=>11, :raw=>" "},
      {:node=>:hash,
       :pos=>12,
       :raw=>"#--red",
       :type=>:unrestricted,
       :value=>"--red"},
      {:node=>:whitespace, :pos=>18, :raw=>" "},
      {:node=>:hash, :pos=>19, :raw=>"#-\\-red", :type=>:id, :value=>"--red"},
      {:node=>:whitespace, :pos=>26, :raw=>" "},
      {:node=>:hash, :pos=>27, :raw=>"#0red", :type=>:unrestricted, :value=>"0red"},
      {:node=>:whitespace, :pos=>32, :raw=>" "},
      {:node=>:hash,
       :pos=>33,
       :raw=>"#-0red",
       :type=>:unrestricted,
       :value=>"-0red"},
      {:node=>:whitespace, :pos=>39, :raw=>" "},
      {:node=>:hash, :pos=>40, :raw=>"#_Red", :type=>:id, :value=>"_Red"},
      {:node=>:whitespace, :pos=>45, :raw=>" "},
      {:node=>:delim, :pos=>46, :raw=>"#", :value=>"#"},
      {:node=>:delim, :pos=>47, :raw=>".", :value=>"."},
      {:node=>:ident, :pos=>48, :raw=>"red", :value=>"red"},
      {:node=>:whitespace, :pos=>51, :raw=>" "},
      {:node=>:hash, :pos=>52, :raw=>"#rêd", :type=>:id, :value=>"rêd"},
      {:node=>:whitespace, :pos=>56, :raw=>" "},
      {:node=>:hash, :pos=>57, :raw=>"#\\.red\\", :type=>:id, :value=>".red\uFFFD"}
    ], tokens)
  end

  it 'should tokenize strings containing escaped newlines' do
    tokens = CT.tokenize("p[example=\"\\\nfoo(int x) {\\\n   this.x = x;\\\n}\\\n\"]")

    assert_equal([
      {:node=>:ident, :pos=>0, :raw=>"p", :value=>"p"},
      {:node=>:"[", :pos=>1, :raw=>"["},
      {:node=>:ident, :pos=>2, :raw=>"example", :value=>"example"},
      {:node=>:delim, :pos=>9, :raw=>"=", :value=>"="},
      {:node=>:string,
       :pos=>10,
       :raw=>"\"\\\nfoo(int x) {\\\n   this.x = x;\\\n}\\\n\"",
       :value=>"foo(int x) {   this.x = x;}"},
      {:node=>:"]", :pos=>47, :raw=>"]"}
    ], tokens)
  end

  it 'should not choke on bad single-quoted strings' do
    tokens = CT.tokenize("'' 'Lorem \"îpsum\"' 'a\\\nb' 'a\nb 'eof")

    assert_equal([
      {:node=>:string, :pos=>0, :raw=>"''", :value=>""},
      {:node=>:whitespace, :pos=>2, :raw=>" "},
      {:node=>:string,
       :pos=>3,
       :raw=>"'Lorem \"îpsum\"'",
       :value=>"Lorem \"îpsum\""},
      {:node=>:whitespace, :pos=>18, :raw=>" "},
      {:node=>:string, :pos=>19, :raw=>"'a\\\nb'", :value=>"ab"},
      {:node=>:whitespace, :pos=>25, :raw=>" "},
      {:node=>:bad_string, :pos=>26, :raw=>"'a", :error=>true, :value=>"a"},
      {:node=>:whitespace, :pos=>28, :raw=>"\n"},
      {:node=>:ident, :pos=>29, :raw=>"b", :value=>"b"},
      {:node=>:whitespace, :pos=>30, :raw=>" "},
      {:node=>:string, :pos=>31, :raw=>"'eof", :value=>"eof"}
    ], tokens)
  end

  it 'should not choke on bad double-quoted strings' do
    tokens = CT.tokenize("\"\" \"Lorem 'îpsum'\" \"a\\\nb\" \"a\nb \"eof")

    assert_equal([
      {:node=>:string, :pos=>0, :raw=>"\"\"", :value=>""},
      {:node=>:whitespace, :pos=>2, :raw=>" "},
      {:node=>:string, :pos=>3, :raw=>"\"Lorem 'îpsum'\"", :value=>"Lorem 'îpsum'"},
      {:node=>:whitespace, :pos=>18, :raw=>" "},
      {:node=>:string, :pos=>19, :raw=>"\"a\\\nb\"", :value=>"ab"},
      {:node=>:whitespace, :pos=>25, :raw=>" "},
      {:node=>:bad_string, :pos=>26, :raw=>"\"a", :error=>true, :value=>"a"},
      {:node=>:whitespace, :pos=>28, :raw=>"\n"},
      {:node=>:ident, :pos=>29, :raw=>"b", :value=>"b"},
      {:node=>:whitespace, :pos=>30, :raw=>" "},
      {:node=>:string, :pos=>31, :raw=>"\"eof", :value=>"eof"}
    ], tokens)
  end

  it 'should tokenize escapes within strings' do
    tokens = CT.tokenize("\"Lo\\rem \\130 ps\\u m\" '\\376\\37 6\\000376\\0000376\\")

    assert_equal([
      {:node=>:string,
       :pos=>0,
       :raw=>"\"Lo\\rem \\130 ps\\u m\"",
       :value=>"Lorem İpsu m"},
      {:node=>:whitespace, :pos=>20, :raw=>" "},
      {:node=>:string,
       :pos=>21,
       :raw=>"'\\376\\37 6\\000376\\0000376\\",
       :value=>"Ͷ76Ͷ76"}
    ], tokens)
  end

  it 'should tokenize URLs with single quotes' do
    tokens = CT.tokenize("url( '') url('Lorem \"îpsum\"'\n) url('a\\\nb' ) url('a\nb' \\){ ) url('eof")

    assert_equal([
      {:node=>:url, :pos=>0, :raw=>"url( '')", :value=>""},
      {:node=>:whitespace, :pos=>8, :raw=>" "},
      {:node=>:url,
       :pos=>9,
       :raw=>"url('Lorem \"îpsum\"'\n)",
       :value=>"Lorem \"îpsum\""},
      {:node=>:whitespace, :pos=>30, :raw=>" "},
      {:node=>:url, :pos=>31, :raw=>"url('a\\\nb' )", :value=>"ab"},
      {:node=>:whitespace, :pos=>43, :raw=>" "},
      {:node=>:bad_url, :pos=>44, :raw=>"url('a\nb' \\){ )", :value=>"a\nb' ){ "},
      {:node=>:whitespace, :pos=>59, :raw=>" "},
      {:node=>:url, :pos=>60, :raw=>"url('eof", :value=>"eof"}
    ], tokens)
  end

  it 'should tokenize an empty, unclosed URL' do
    tokens = CT.tokenize("url(")

    assert_equal([
      {:node=>:url, :pos=>0, :raw=>"url(", :value=>""}
    ], tokens)
  end

  it 'should tokenize an unclosed URL containing a tab' do
    tokens = CT.tokenize("url( \t")

    assert_equal([
      {:node=>:url, :pos=>0, :raw=>"url( \t", :value=>""}
    ], tokens)
  end

  it 'should tokenize URLs with double quotes' do
    tokens = CT.tokenize("url(\"\") url(\"Lorem 'îpsum'\"\n) url(\"a\\\nb\" ) url(\"a\nb\" \\){ ) url(\"eof")

    assert_equal([
      {:node=>:url, :pos=>0, :raw=>"url(\"\")", :value=>""},
      {:node=>:whitespace, :pos=>7, :raw=>" "},
      {:node=>:url,
       :pos=>8,
       :raw=>"url(\"Lorem 'îpsum'\"\n)",
       :value=>"Lorem 'îpsum'"},
      {:node=>:whitespace, :pos=>29, :raw=>" "},
      {:node=>:url, :pos=>30, :raw=>"url(\"a\\\nb\" )", :value=>"ab"},
      {:node=>:whitespace, :pos=>42, :raw=>" "},
      {:node=>:bad_url,
       :pos=>43,
       :raw=>"url(\"a\nb\" \\){ )",
       :value=>"a\nb\" ){ "},
      {:node=>:whitespace, :pos=>58, :raw=>" "},
      {:node=>:url, :pos=>59, :raw=>"url(\"eof", :value=>"eof"}
    ], tokens)
  end

  it 'should tokenize URLs containing escapes' do
    tokens = CT.tokenize("url(\"Lo\\rem \\130 ps\\u m\") url('\\376\\37 6\\000376\\0000376\\")

    assert_equal([
      {:node=>:url,
       :pos=>0,
       :raw=>"url(\"Lo\\rem \\130 ps\\u m\")",
       :value=>"Lorem İpsu m"},
      {:node=>:whitespace, :pos=>25, :raw=>" "},
      {:node=>:url,
       :pos=>26,
       :raw=>"url('\\376\\37 6\\000376\\0000376\\",
       :value=>"Ͷ76Ͷ76"}
    ], tokens)
  end

  it 'should tokenize unquoted URLs in a case-insensitive manner' do
    tokens = CT.tokenize("URL(foo) Url(foo) ûrl(foo) url (foo) url\\ (foo) url(\t 'foo' ")

    assert_equal([
      {:node=>:url, :pos=>0, :raw=>"URL(foo)", :value=>"foo"},
      {:node=>:whitespace, :pos=>8, :raw=>" "},
      {:node=>:url, :pos=>9, :raw=>"Url(foo)", :value=>"foo"},
      {:node=>:whitespace, :pos=>17, :raw=>" "},
      {:node=>:function, :pos=>18, :raw=>"ûrl(", :value=>"ûrl"},
      {:node=>:ident, :pos=>22, :raw=>"foo", :value=>"foo"},
      {:node=>:")", :pos=>25, :raw=>")"},
      {:node=>:whitespace, :pos=>26, :raw=>" "},
      {:node=>:ident, :pos=>27, :raw=>"url", :value=>"url"},
      {:node=>:whitespace, :pos=>30, :raw=>" "},
      {:node=>:"(", :pos=>31, :raw=>"("},
      {:node=>:ident, :pos=>32, :raw=>"foo", :value=>"foo"},
      {:node=>:")", :pos=>35, :raw=>")"},
      {:node=>:whitespace, :pos=>36, :raw=>" "},
      {:node=>:function, :pos=>37, :raw=>"url\\ (", :value=>"url "},
      {:node=>:ident, :pos=>43, :raw=>"foo", :value=>"foo"},
      {:node=>:")", :pos=>46, :raw=>")"},
      {:node=>:whitespace, :pos=>47, :raw=>" "},
      {:node=>:url, :pos=>48, :raw=>"url(\t 'foo' ", :value=>"foo"}
    ], tokens)
  end

  it 'should tokenize bad URLs with extra content after the quoted segment' do
    tokens = CT.tokenize("url('a' b) url('c' d)")

    assert_equal([
      {:node=>:bad_url, :pos=>0, :raw=>"url('a' b)", :value=>"ab"},
      {:node=>:whitespace, :pos=>10, :raw=>" "},
      {:node=>:bad_url, :pos=>11, :raw=>"url('c' d)", :value=>"cd"}
    ], tokens)
  end

  it 'should tokenize bad URLs with newlines in the quoted segment' do
    tokens = CT.tokenize("url('a\nb') url('c\n")

    assert_equal([
      {:node=>:bad_url, :pos=>0, :raw=>"url('a\nb')", :value=>"a\nb'"},
      {:node=>:whitespace, :pos=>10, :raw=>" "},
      {:node=>:bad_url, :pos=>11, :raw=>"url('c\n", :value=>"c\n"}
    ], tokens)
  end

  it 'should tokenize a mix of URLs with valid and invalid escapes' do
    tokens = CT.tokenize("url() url( \t) url( Foô\\030\n!\n) url(a b) url(a\\ b) url(a(b) url(a\\(b) url(a'b) url(a\\'b) url(a\"b) url(a\\\"b) url(a\nb) url(a\\\nb) url(a\\a b) url(a\\")

    assert_equal([
      {:node=>:url, :pos=>0, :raw=>"url()", :value=>""},
      {:node=>:whitespace, :pos=>5, :raw=>" "},
      {:node=>:url, :pos=>6, :raw=>"url( \t)", :value=>""},
      {:node=>:whitespace, :pos=>13, :raw=>" "},
      {:node=>:url, :pos=>14, :raw=>"url( Foô\\030\n!\n)", :value=>"Foô0!"},
      {:node=>:whitespace, :pos=>30, :raw=>" "},
      {:node=>:bad_url, :pos=>31, :raw=>"url(a b)", :value=>"ab"},
      {:node=>:whitespace, :pos=>39, :raw=>" "},
      {:node=>:url, :pos=>40, :raw=>"url(a\\ b)", :value=>"a b"},
      {:node=>:whitespace, :pos=>49, :raw=>" "},
      {:node=>:bad_url, :pos=>50, :raw=>"url(a(b)", :error=>true, :value=>"ab"},
      {:node=>:whitespace, :pos=>58, :raw=>" "},
      {:node=>:url, :pos=>59, :raw=>"url(a\\(b)", :value=>"a(b"},
      {:node=>:whitespace, :pos=>68, :raw=>" "},
      {:node=>:bad_url, :pos=>69, :raw=>"url(a'b)", :error=>true, :value=>"ab"},
      {:node=>:whitespace, :pos=>77, :raw=>" "},
      {:node=>:url, :pos=>78, :raw=>"url(a\\'b)", :value=>"a'b"},
      {:node=>:whitespace, :pos=>87, :raw=>" "},
      {:node=>:bad_url, :pos=>88, :raw=>"url(a\"b)", :error=>true, :value=>"ab"},
      {:node=>:whitespace, :pos=>96, :raw=>" "},
      {:node=>:url, :pos=>97, :raw=>"url(a\\\"b)", :value=>"a\"b"},
      {:node=>:whitespace, :pos=>106, :raw=>" "},
      {:node=>:bad_url, :pos=>107, :raw=>"url(a\nb)", :value=>"ab"},
      {:node=>:whitespace, :pos=>115, :raw=>" "},
      {:node=>:bad_url,
       :pos=>116,
       :raw=>"url(a\\\nb)",
       :error=>true,
       :value=>"a\nb"},
      {:node=>:whitespace, :pos=>125, :raw=>" "},
      {:node=>:url, :pos=>126, :raw=>"url(a\\a b)", :value=>"a\nb"},
      {:node=>:whitespace, :pos=>136, :raw=>" "},
      {:node=>:url, :pos=>137, :raw=>"url(a\\", :value=>"a\uFFFD"}
    ], tokens)
  end

  it 'should tokenize a longass unquoted, unclosed URL' do
    tokens = CT.tokenize("url(\u0000!\#$%&*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~\u0080\u0081\u009e\u009f\u00a0\u00a1\u00a2")

    assert_equal([
      {:node=>:url,
       :pos=>0,
       :raw=>
        "url(\uFFFD!\#$%&*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~\u0080\u0081\u009E\u009F ¡¢",
       :value=>
        "\uFFFD!\#$%&*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~\u0080\u0081\u009e\u009f\u00a0¡¢"}
    ], tokens)
  end
end

