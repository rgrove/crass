# encoding: utf-8

# Includes tests based on Simon Sapin's CSS parsing tests:
# https://github.com/SimonSapin/css-parsing-tests/

require_relative 'support/common'

describe 'Crass::Tokenizer' do
  make_my_diffs_pretty!
  parallelize_me!

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
    tokens = CT.tokenize("#red0 #-Red #--red #-\\-red #0red #-0red #_Red #.red #rêd #êrd #\\.red\\")

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
      {:node=>:hash, :pos=>57, :raw=>"#êrd", :type=>:id, :value=>"êrd"},
      {:node=>:whitespace, :pos=>61, :raw=>" "},
      {:node=>:hash, :pos=>62, :raw=>"#\\.red\\", :type=>:id, :value=>".red\uFFFD"}
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

  it 'should tokenize lots of bad escaped URLs' do
    tokens = CT.tokenize("url(\u0001) url(\u0002) url(\u0003) url(\u0004) url(\u0005) url(\u0006) url(\u0007) url(\u0008) url(\u000b) url(\u000e) url(\u000f) url(\u0010) url(\u0011) url(\u0012) url(\u0013) url(\u0014) url(\u0015) url(\u0016) url(\u0017) url(\u0018) url(\u0019) url(\u001a) url(\u001b) url(\u001c) url(\u001d) url(\u001e) url(\u001f) url(\u007f)")

    assert_equal([
      {:node=>:bad_url, :pos=>0, :raw=>"url(\u0001)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>6, :raw=>" "},
      {:node=>:bad_url, :pos=>7, :raw=>"url(\u0002)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>13, :raw=>" "},
      {:node=>:bad_url, :pos=>14, :raw=>"url(\u0003)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>20, :raw=>" "},
      {:node=>:bad_url, :pos=>21, :raw=>"url(\u0004)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>27, :raw=>" "},
      {:node=>:bad_url, :pos=>28, :raw=>"url(\u0005)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>34, :raw=>" "},
      {:node=>:bad_url, :pos=>35, :raw=>"url(\u0006)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>41, :raw=>" "},
      {:node=>:bad_url, :pos=>42, :raw=>"url(\a)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>48, :raw=>" "},
      {:node=>:bad_url, :pos=>49, :raw=>"url(\b)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>55, :raw=>" "},
      {:node=>:bad_url, :pos=>56, :raw=>"url(\v)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>62, :raw=>" "},
      {:node=>:bad_url, :pos=>63, :raw=>"url(\u000E)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>69, :raw=>" "},
      {:node=>:bad_url, :pos=>70, :raw=>"url(\u000F)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>76, :raw=>" "},
      {:node=>:bad_url, :pos=>77, :raw=>"url(\u0010)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>83, :raw=>" "},
      {:node=>:bad_url, :pos=>84, :raw=>"url(\u0011)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>90, :raw=>" "},
      {:node=>:bad_url, :pos=>91, :raw=>"url(\u0012)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>97, :raw=>" "},
      {:node=>:bad_url, :pos=>98, :raw=>"url(\u0013)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>104, :raw=>" "},
      {:node=>:bad_url, :pos=>105, :raw=>"url(\u0014)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>111, :raw=>" "},
      {:node=>:bad_url, :pos=>112, :raw=>"url(\u0015)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>118, :raw=>" "},
      {:node=>:bad_url, :pos=>119, :raw=>"url(\u0016)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>125, :raw=>" "},
      {:node=>:bad_url, :pos=>126, :raw=>"url(\u0017)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>132, :raw=>" "},
      {:node=>:bad_url, :pos=>133, :raw=>"url(\u0018)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>139, :raw=>" "},
      {:node=>:bad_url, :pos=>140, :raw=>"url(\u0019)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>146, :raw=>" "},
      {:node=>:bad_url, :pos=>147, :raw=>"url(\u001A)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>153, :raw=>" "},
      {:node=>:bad_url, :pos=>154, :raw=>"url(\e)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>160, :raw=>" "},
      {:node=>:bad_url, :pos=>161, :raw=>"url(\u001C)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>167, :raw=>" "},
      {:node=>:bad_url, :pos=>168, :raw=>"url(\u001D)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>174, :raw=>" "},
      {:node=>:bad_url, :pos=>175, :raw=>"url(\u001E)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>181, :raw=>" "},
      {:node=>:bad_url, :pos=>182, :raw=>"url(\u001F)", :error=>true, :value=>""},
      {:node=>:whitespace, :pos=>188, :raw=>" "},
      {:node=>:bad_url, :pos=>189, :raw=>"url(\u007F)", :error=>true, :value=>""}
    ], tokens)
  end

  it 'should tokenize numbers' do
    tokens = CT.tokenize("12 +34 -45 .67 +.89 -.01 2.3 +45.0 -0.67")

    assert_equal([
      {:node=>:number,
       :pos=>0,
       :raw=>"12",
       :repr=>"12",
       :type=>:integer,
       :value=>12},
      {:node=>:whitespace, :pos=>2, :raw=>" "},
      {:node=>:number,
       :pos=>3,
       :raw=>"+34",
       :repr=>"+34",
       :type=>:integer,
       :value=>34},
      {:node=>:whitespace, :pos=>6, :raw=>" "},
      {:node=>:number,
       :pos=>7,
       :raw=>"-45",
       :repr=>"-45",
       :type=>:integer,
       :value=>-45},
      {:node=>:whitespace, :pos=>10, :raw=>" "},
      {:node=>:number,
       :pos=>11,
       :raw=>".67",
       :repr=>".67",
       :type=>:number,
       :value=>0.67},
      {:node=>:whitespace, :pos=>14, :raw=>" "},
      {:node=>:number,
       :pos=>15,
       :raw=>"+.89",
       :repr=>"+.89",
       :type=>:number,
       :value=>0.89},
      {:node=>:whitespace, :pos=>19, :raw=>" "},
      {:node=>:number,
       :pos=>20,
       :raw=>"-.01",
       :repr=>"-.01",
       :type=>:number,
       :value=>-0.01},
      {:node=>:whitespace, :pos=>24, :raw=>" "},
      {:node=>:number,
       :pos=>25,
       :raw=>"2.3",
       :repr=>"2.3",
       :type=>:number,
       :value=>2.3},
      {:node=>:whitespace, :pos=>28, :raw=>" "},
      {:node=>:number,
       :pos=>29,
       :raw=>"+45.0",
       :repr=>"+45.0",
       :type=>:number,
       :value=>45},
      {:node=>:whitespace, :pos=>34, :raw=>" "},
      {:node=>:number,
       :pos=>35,
       :raw=>"-0.67",
       :repr=>"-0.67",
       :type=>:number,
       :value=>-0.67}
    ], tokens)
  end

  it 'should tokenize scientific notation' do
    tokens = CT.tokenize("12e2 +34e+1 -45E-0 .68e+3 +.79e-1 -.01E2 2.3E+1 +45.0e6 -0.67e0")

    assert_equal([
      {:node=>:number,
       :pos=>0,
       :raw=>"12e2",
       :repr=>"12e2",
       :type=>:number,
       :value=>1200},
      {:node=>:whitespace, :pos=>4, :raw=>" "},
      {:node=>:number,
       :pos=>5,
       :raw=>"+34e+1",
       :repr=>"+34e+1",
       :type=>:number,
       :value=>340},
      {:node=>:whitespace, :pos=>11, :raw=>" "},
      {:node=>:number,
       :pos=>12,
       :raw=>"-45E-0",
       :repr=>"-45E-0",
       :type=>:number,
       :value=>-45},
      {:node=>:whitespace, :pos=>18, :raw=>" "},
      {:node=>:number,
       :pos=>19,
       :raw=>".68e+3",
       :repr=>".68e+3",
       :type=>:number,
       :value=>680},
      {:node=>:whitespace, :pos=>25, :raw=>" "},
      {:node=>:number,
       :pos=>26,
       :raw=>"+.79e-1",
       :repr=>"+.79e-1",
       :type=>:number,
       :value=>0.079},
      {:node=>:whitespace, :pos=>33, :raw=>" "},
      {:node=>:number,
       :pos=>34,
       :raw=>"-.01E2",
       :repr=>"-.01E2",
       :type=>:number,
       :value=>-1},
      {:node=>:whitespace, :pos=>40, :raw=>" "},
      {:node=>:number,
       :pos=>41,
       :raw=>"2.3E+1",
       :repr=>"2.3E+1",
       :type=>:number,
       :value=>23},
      {:node=>:whitespace, :pos=>47, :raw=>" "},
      {:node=>:number,
       :pos=>48,
       :raw=>"+45.0e6",
       :repr=>"+45.0e6",
       :type=>:number,
       :value=>45000000},
      {:node=>:whitespace, :pos=>55, :raw=>" "},
      {:node=>:number,
       :pos=>56,
       :raw=>"-0.67e0",
       :repr=>"-0.67e0",
       :type=>:number,
       :value=>-0.67}
    ], tokens)
  end

  it 'should tokenize a decimal point with no following digits as a delim' do
    tokens = CT.tokenize("3. ")

    assert_equal([
      {:node=>:number, :pos=>0, :raw=>"3", :repr=>"3", :type=>:integer, :value=>3},
      {:node=>:delim, :pos=>1, :raw=>".", :value=>"."},
      {:node=>:whitespace, :pos=>2, :raw=>" "}
    ], tokens)
  end

  it 'should not allow a scientific notation "E" to be escaped' do
    tokens = CT.tokenize("3\\65-2 ")

    assert_equal([
      {:node=>:dimension,
       :pos=>0,
       :raw=>"3\\65-2",
       :repr=>"3",
       :type=>:integer,
       :unit=>"e-2",
       :value=>3},
      {:node=>:whitespace, :pos=>6, :raw=>" "}
    ], tokens)
  end

  it 'should only allow integer exponents in scientific notation' do
    tokens = CT.tokenize("3e-2.1 ")

    assert_equal([
      {:node=>:number,
       :pos=>0,
       :raw=>"3e-2",
       :repr=>"3e-2",
       :type=>:number,
       :value=>0.03},
      {:node=>:number,
       :pos=>4,
       :raw=>".1",
       :repr=>".1",
       :type=>:number,
       :value=>0.1},
      {:node=>:whitespace, :pos=>6, :raw=>" "}
    ], tokens)
  end

  it 'should tokenize percentages' do
    tokens = CT.tokenize("12% +34% -45% .67% +.89% -.01% 2.3% +45.0% -0.67%")

    assert_equal([
      {:node=>:percentage,
       :pos=>0,
       :raw=>"12%",
       :repr=>"12",
       :type=>:integer,
       :value=>12},
      {:node=>:whitespace, :pos=>3, :raw=>" "},
      {:node=>:percentage,
       :pos=>4,
       :raw=>"+34%",
       :repr=>"+34",
       :type=>:integer,
       :value=>34},
      {:node=>:whitespace, :pos=>8, :raw=>" "},
      {:node=>:percentage,
       :pos=>9,
       :raw=>"-45%",
       :repr=>"-45",
       :type=>:integer,
       :value=>-45},
      {:node=>:whitespace, :pos=>13, :raw=>" "},
      {:node=>:percentage,
       :pos=>14,
       :raw=>".67%",
       :repr=>".67",
       :type=>:number,
       :value=>0.67},
      {:node=>:whitespace, :pos=>18, :raw=>" "},
      {:node=>:percentage,
       :pos=>19,
       :raw=>"+.89%",
       :repr=>"+.89",
       :type=>:number,
       :value=>0.89},
      {:node=>:whitespace, :pos=>24, :raw=>" "},
      {:node=>:percentage,
       :pos=>25,
       :raw=>"-.01%",
       :repr=>"-.01",
       :type=>:number,
       :value=>-0.01},
      {:node=>:whitespace, :pos=>30, :raw=>" "},
      {:node=>:percentage,
       :pos=>31,
       :raw=>"2.3%",
       :repr=>"2.3",
       :type=>:number,
       :value=>2.3},
      {:node=>:whitespace, :pos=>35, :raw=>" "},
      {:node=>:percentage,
       :pos=>36,
       :raw=>"+45.0%",
       :repr=>"+45.0",
       :type=>:number,
       :value=>45},
      {:node=>:whitespace, :pos=>42, :raw=>" "},
      {:node=>:percentage,
       :pos=>43,
       :raw=>"-0.67%",
       :repr=>"-0.67",
       :type=>:number,
       :value=>-0.67}
    ], tokens)
  end

  it 'should tokenize percentages with scientific notation' do
    tokens = CT.tokenize("12e2% +34e+1% -45E-0% .68e+3% +.79e-1% -.01E2% 2.3E+1% +45.0e6% -0.67e0%")

    assert_equal([
      {:node=>:percentage,
       :pos=>0,
       :raw=>"12e2%",
       :repr=>"12e2",
       :type=>:number,
       :value=>1200},
      {:node=>:whitespace, :pos=>5, :raw=>" "},
      {:node=>:percentage,
       :pos=>6,
       :raw=>"+34e+1%",
       :repr=>"+34e+1",
       :type=>:number,
       :value=>340},
      {:node=>:whitespace, :pos=>13, :raw=>" "},
      {:node=>:percentage,
       :pos=>14,
       :raw=>"-45E-0%",
       :repr=>"-45E-0",
       :type=>:number,
       :value=>-45},
      {:node=>:whitespace, :pos=>21, :raw=>" "},
      {:node=>:percentage,
       :pos=>22,
       :raw=>".68e+3%",
       :repr=>".68e+3",
       :type=>:number,
       :value=>680},
      {:node=>:whitespace, :pos=>29, :raw=>" "},
      {:node=>:percentage,
       :pos=>30,
       :raw=>"+.79e-1%",
       :repr=>"+.79e-1",
       :type=>:number,
       :value=>0.079},
      {:node=>:whitespace, :pos=>38, :raw=>" "},
      {:node=>:percentage,
       :pos=>39,
       :raw=>"-.01E2%",
       :repr=>"-.01E2",
       :type=>:number,
       :value=>-1},
      {:node=>:whitespace, :pos=>46, :raw=>" "},
      {:node=>:percentage,
       :pos=>47,
       :raw=>"2.3E+1%",
       :repr=>"2.3E+1",
       :type=>:number,
       :value=>23},
      {:node=>:whitespace, :pos=>54, :raw=>" "},
      {:node=>:percentage,
       :pos=>55,
       :raw=>"+45.0e6%",
       :repr=>"+45.0e6",
       :type=>:number,
       :value=>45000000},
      {:node=>:whitespace, :pos=>63, :raw=>" "},
      {:node=>:percentage,
       :pos=>64,
       :raw=>"-0.67e0%",
       :repr=>"-0.67e0",
       :type=>:number,
       :value=>-0.67}
    ], tokens)
  end

  it 'should not tokenize an escaped percent sign' do
    tokens = CT.tokenize("12\\% ")

    assert_equal([
      {:node=>:dimension,
       :pos=>0,
       :raw=>"12\\%",
       :repr=>"12",
       :type=>:integer,
       :unit=>"%",
       :value=>12},
      {:node=>:whitespace, :pos=>4, :raw=>" "}
    ], tokens)
  end

  it 'should tokenize dimensions' do
    tokens = CT.tokenize("12px +34px -45px .67px +.89px -.01px 2.3px +45.0px -0.67px")

    assert_equal([
      {:node=>:dimension,
       :pos=>0,
       :raw=>"12px",
       :repr=>"12",
       :type=>:integer,
       :unit=>"px",
       :value=>12},
      {:node=>:whitespace, :pos=>4, :raw=>" "},
      {:node=>:dimension,
       :pos=>5,
       :raw=>"+34px",
       :repr=>"+34",
       :type=>:integer,
       :unit=>"px",
       :value=>34},
      {:node=>:whitespace, :pos=>10, :raw=>" "},
      {:node=>:dimension,
       :pos=>11,
       :raw=>"-45px",
       :repr=>"-45",
       :type=>:integer,
       :unit=>"px",
       :value=>-45},
      {:node=>:whitespace, :pos=>16, :raw=>" "},
      {:node=>:dimension,
       :pos=>17,
       :raw=>".67px",
       :repr=>".67",
       :type=>:number,
       :unit=>"px",
       :value=>0.67},
      {:node=>:whitespace, :pos=>22, :raw=>" "},
      {:node=>:dimension,
       :pos=>23,
       :raw=>"+.89px",
       :repr=>"+.89",
       :type=>:number,
       :unit=>"px",
       :value=>0.89},
      {:node=>:whitespace, :pos=>29, :raw=>" "},
      {:node=>:dimension,
       :pos=>30,
       :raw=>"-.01px",
       :repr=>"-.01",
       :type=>:number,
       :unit=>"px",
       :value=>-0.01},
      {:node=>:whitespace, :pos=>36, :raw=>" "},
      {:node=>:dimension,
       :pos=>37,
       :raw=>"2.3px",
       :repr=>"2.3",
       :type=>:number,
       :unit=>"px",
       :value=>2.3},
      {:node=>:whitespace, :pos=>42, :raw=>" "},
      {:node=>:dimension,
       :pos=>43,
       :raw=>"+45.0px",
       :repr=>"+45.0",
       :type=>:number,
       :unit=>"px",
       :value=>45},
      {:node=>:whitespace, :pos=>50, :raw=>" "},
      {:node=>:dimension,
       :pos=>51,
       :raw=>"-0.67px",
       :repr=>"-0.67",
       :type=>:number,
       :unit=>"px",
       :value=>-0.67}
    ], tokens)
  end

  it 'should tokenize dimensions with scientific notation' do
    tokens = CT.tokenize("12e2px +34e+1px -45E-0px .68e+3px +.79e-1px -.01E2px 2.3E+1px +45.0e6px -0.67e0px")

    assert_equal([
      {:node=>:dimension,
       :pos=>0,
       :raw=>"12e2px",
       :repr=>"12e2",
       :type=>:number,
       :unit=>"px",
       :value=>1200},
      {:node=>:whitespace, :pos=>6, :raw=>" "},
      {:node=>:dimension,
       :pos=>7,
       :raw=>"+34e+1px",
       :repr=>"+34e+1",
       :type=>:number,
       :unit=>"px",
       :value=>340},
      {:node=>:whitespace, :pos=>15, :raw=>" "},
      {:node=>:dimension,
       :pos=>16,
       :raw=>"-45E-0px",
       :repr=>"-45E-0",
       :type=>:number,
       :unit=>"px",
       :value=>-45},
      {:node=>:whitespace, :pos=>24, :raw=>" "},
      {:node=>:dimension,
       :pos=>25,
       :raw=>".68e+3px",
       :repr=>".68e+3",
       :type=>:number,
       :unit=>"px",
       :value=>680},
      {:node=>:whitespace, :pos=>33, :raw=>" "},
      {:node=>:dimension,
       :pos=>34,
       :raw=>"+.79e-1px",
       :repr=>"+.79e-1",
       :type=>:number,
       :unit=>"px",
       :value=>0.079},
      {:node=>:whitespace, :pos=>43, :raw=>" "},
      {:node=>:dimension,
       :pos=>44,
       :raw=>"-.01E2px",
       :repr=>"-.01E2",
       :type=>:number,
       :unit=>"px",
       :value=>-1},
      {:node=>:whitespace, :pos=>52, :raw=>" "},
      {:node=>:dimension,
       :pos=>53,
       :raw=>"2.3E+1px",
       :repr=>"2.3E+1",
       :type=>:number,
       :unit=>"px",
       :value=>23},
      {:node=>:whitespace, :pos=>61, :raw=>" "},
      {:node=>:dimension,
       :pos=>62,
       :raw=>"+45.0e6px",
       :repr=>"+45.0e6",
       :type=>:number,
       :unit=>"px",
       :value=>45000000},
      {:node=>:whitespace, :pos=>71, :raw=>" "},
      {:node=>:dimension,
       :pos=>72,
       :raw=>"-0.67e0px",
       :repr=>"-0.67e0",
       :type=>:number,
       :unit=>"px",
       :value=>-0.67}
    ], tokens)
  end

  it 'should tokenize a mix of dimensions and numbers' do
    tokens = CT.tokenize("12red0 12.0-red 12--red 12-\\-red 120red 12-0red 12\u0000red 12_Red 12.red 12rêd")

    assert_equal([
      {:node=>:dimension,
       :pos=>0,
       :raw=>"12red0",
       :repr=>"12",
       :type=>:integer,
       :unit=>"red0",
       :value=>12},
      {:node=>:whitespace, :pos=>6, :raw=>" "},
      {:node=>:dimension,
       :pos=>7,
       :raw=>"12.0-red",
       :repr=>"12.0",
       :type=>:number,
       :unit=>"-red",
       :value=>12},
      {:node=>:whitespace, :pos=>15, :raw=>" "},
      {:node=>:number,
       :pos=>16,
       :raw=>"12",
       :repr=>"12",
       :type=>:integer,
       :value=>12},
      {:node=>:delim, :pos=>18, :raw=>"-", :value=>"-"},
      {:node=>:ident, :pos=>19, :raw=>"-red", :value=>"-red"},
      {:node=>:whitespace, :pos=>23, :raw=>" "},
      {:node=>:dimension,
       :pos=>24,
       :raw=>"12-\\-red",
       :repr=>"12",
       :type=>:integer,
       :unit=>"--red",
       :value=>12},
      {:node=>:whitespace, :pos=>32, :raw=>" "},
      {:node=>:dimension,
       :pos=>33,
       :raw=>"120red",
       :repr=>"120",
       :type=>:integer,
       :unit=>"red",
       :value=>120},
      {:node=>:whitespace, :pos=>39, :raw=>" "},
      {:node=>:number,
       :pos=>40,
       :raw=>"12",
       :repr=>"12",
       :type=>:integer,
       :value=>12},
      {:node=>:dimension,
       :pos=>42,
       :raw=>"-0red",
       :repr=>"-0",
       :type=>:integer,
       :unit=>"red",
       :value=>0},
      {:node=>:whitespace, :pos=>47, :raw=>" "},
      {:node=>:dimension,
       :pos=>48,
       :raw=>"12\ufffdred",
       :repr=>"12",
       :type=>:integer,
       :unit=>"\ufffdred",
       :value=>12},
      {:node=>:whitespace, :pos=>54, :raw=>" "},
      {:node=>:dimension,
       :pos=>55,
       :raw=>"12_Red",
       :repr=>"12",
       :type=>:integer,
       :unit=>"_Red",
       :value=>12},
      {:node=>:whitespace, :pos=>61, :raw=>" "},
      {:node=>:number,
       :pos=>62,
       :raw=>"12",
       :repr=>"12",
       :type=>:integer,
       :value=>12},
      {:node=>:delim, :pos=>64, :raw=>".", :value=>"."},
      {:node=>:ident, :pos=>65, :raw=>"red", :value=>"red"},
      {:node=>:whitespace, :pos=>68, :raw=>" "},
      {:node=>:dimension,
       :pos=>69,
       :raw=>"12rêd",
       :repr=>"12",
       :type=>:integer,
       :unit=>"rêd",
       :value=>12}
    ], tokens)
  end

  it 'should tokenize unicode ranges' do
    tokens = CT.tokenize("u+1 U+10 U+100 U+1000 U+10000 U+100000 U+1000000")

    assert_equal([
      {:node=>:unicode_range, :pos=>0, :raw=>"u+1", :start=>1, :end=>1},
      {:node=>:whitespace, :pos=>3, :raw=>" "},
      {:node=>:unicode_range, :pos=>4, :raw=>"U+10", :start=>16, :end=>16},
      {:node=>:whitespace, :pos=>8, :raw=>" "},
      {:node=>:unicode_range, :pos=>9, :raw=>"U+100", :start=>256, :end=>256},
      {:node=>:whitespace, :pos=>14, :raw=>" "},
      {:node=>:unicode_range, :pos=>15, :raw=>"U+1000", :start=>4096, :end=>4096},
      {:node=>:whitespace, :pos=>21, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>22,
       :raw=>"U+10000",
       :start=>65536,
       :end=>65536},
      {:node=>:whitespace, :pos=>29, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>30,
       :raw=>"U+100000",
       :start=>1048576,
       :end=>1048576},
      {:node=>:whitespace, :pos=>38, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>39,
       :raw=>"U+100000",
       :start=>1048576,
       :end=>1048576},
      {:node=>:number, :pos=>47, :raw=>"0", :repr=>"0", :type=>:integer, :value=>0}
    ], tokens)
  end

  it 'should tokenize Unicode ranges with single wildcards' do
    tokens = CT.tokenize("u+? u+1? U+10? U+100? U+1000? U+10000? U+100000?")

    assert_equal([
      {:node=>:unicode_range, :pos=>0, :raw=>"u+?", :start=>0, :end=>15},
      {:node=>:whitespace, :pos=>3, :raw=>" "},
      {:node=>:unicode_range, :pos=>4, :raw=>"u+1?", :start=>16, :end=>31},
      {:node=>:whitespace, :pos=>8, :raw=>" "},
      {:node=>:unicode_range, :pos=>9, :raw=>"U+10?", :start=>256, :end=>271},
      {:node=>:whitespace, :pos=>14, :raw=>" "},
      {:node=>:unicode_range, :pos=>15, :raw=>"U+100?", :start=>4096, :end=>4111},
      {:node=>:whitespace, :pos=>21, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>22,
       :raw=>"U+1000?",
       :start=>65536,
       :end=>65551},
      {:node=>:whitespace, :pos=>29, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>30,
       :raw=>"U+10000?",
       :start=>1048576,
       :end=>1048591},
      {:node=>:whitespace, :pos=>38, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>39,
       :raw=>"U+100000",
       :start=>1048576,
       :end=>1048576},
      {:node=>:delim, :pos=>47, :raw=>"?", :value=>"?"}
    ], tokens)
  end

  it 'should tokenize Unicode ranges with two wildcards' do
    tokens = CT.tokenize("u+?? U+1?? U+10?? U+100?? U+1000?? U+10000??")

    assert_equal([
      {:node=>:unicode_range, :pos=>0, :raw=>"u+??", :start=>0, :end=>255},
      {:node=>:whitespace, :pos=>4, :raw=>" "},
      {:node=>:unicode_range, :pos=>5, :raw=>"U+1??", :start=>256, :end=>511},
      {:node=>:whitespace, :pos=>10, :raw=>" "},
      {:node=>:unicode_range, :pos=>11, :raw=>"U+10??", :start=>4096, :end=>4351},
      {:node=>:whitespace, :pos=>17, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>18,
       :raw=>"U+100??",
       :start=>65536,
       :end=>65791},
      {:node=>:whitespace, :pos=>25, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>26,
       :raw=>"U+1000??",
       :start=>1048576,
       :end=>1048831},
      {:node=>:whitespace, :pos=>34, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>35,
       :raw=>"U+10000?",
       :start=>1048576,
       :end=>1048591},
      {:node=>:delim, :pos=>43, :raw=>"?", :value=>"?"}
    ], tokens)
  end

  it 'should tokenize Unicode ranges with three wildcards' do
    tokens = CT.tokenize("u+??? U+1??? U+10??? U+100??? U+1000???")

    assert_equal([
      {:node=>:unicode_range, :pos=>0, :raw=>"u+???", :start=>0, :end=>4095},
      {:node=>:whitespace, :pos=>5, :raw=>" "},
      {:node=>:unicode_range, :pos=>6, :raw=>"U+1???", :start=>4096, :end=>8191},
      {:node=>:whitespace, :pos=>12, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>13,
       :raw=>"U+10???",
       :start=>65536,
       :end=>69631},
      {:node=>:whitespace, :pos=>20, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>21,
       :raw=>"U+100???",
       :start=>1048576,
       :end=>1052671},
      {:node=>:whitespace, :pos=>29, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>30,
       :raw=>"U+1000??",
       :start=>1048576,
       :end=>1048831},
      {:node=>:delim, :pos=>38, :raw=>"?", :value=>"?"}
    ], tokens)
  end

  it 'should tokenize Unicode ranges with four wildcards' do
    tokens = CT.tokenize("u+???? U+1???? U+10???? U+100????")

    assert_equal([
      {:node=>:unicode_range, :pos=>0, :raw=>"u+????", :start=>0, :end=>65535},
      {:node=>:whitespace, :pos=>6, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>7,
       :raw=>"U+1????",
       :start=>65536,
       :end=>131071},
      {:node=>:whitespace, :pos=>14, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>15,
       :raw=>"U+10????",
       :start=>1048576,
       :end=>1114111},
      {:node=>:whitespace, :pos=>23, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>24,
       :raw=>"U+100???",
       :start=>1048576,
       :end=>1052671},
      {:node=>:delim, :pos=>32, :raw=>"?", :value=>"?"}
    ], tokens)
  end

  it 'should tokenize Unicode ranges with five wildcards' do
    tokens = CT.tokenize("u+????? U+1????? U+10?????")

    assert_equal([
      {:node=>:unicode_range, :pos=>0, :raw=>"u+?????", :start=>0, :end=>1048575},
      {:node=>:whitespace, :pos=>7, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>8,
       :raw=>"U+1?????",
       :start=>1048576,
       :end=>2097151},
      {:node=>:whitespace, :pos=>16, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>17,
       :raw=>"U+10????",
       :start=>1048576,
       :end=>1114111},
      {:node=>:delim, :pos=>25, :raw=>"?", :value=>"?"}
    ], tokens)
  end

  it 'should tokenize Unicode ranges with six wildcards' do
    tokens = CT.tokenize("u+?????? U+1??????")

    assert_equal([
      {:node=>:unicode_range, :pos=>0, :raw=>"u+??????", :start=>0, :end=>16777215},
      {:node=>:whitespace, :pos=>8, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>9,
       :raw=>"U+1?????",
       :start=>1048576,
       :end=>2097151},
      {:node=>:delim, :pos=>17, :raw=>"?", :value=>"?"}
    ], tokens)
  end

  it 'should not get confused by an ambiguous number after a Unicode range' do
    tokens = CT.tokenize("u+1-2 U+100000-2 U+1000000-2 U+10-200000")

    assert_equal([
      {:node=>:unicode_range, :pos=>0, :raw=>"u+1-2", :start=>1, :end=>2},
      {:node=>:whitespace, :pos=>5, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>6,
       :raw=>"U+100000-2",
       :start=>1048576,
       :end=>2},
      {:node=>:whitespace, :pos=>16, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>17,
       :raw=>"U+100000",
       :start=>1048576,
       :end=>1048576},
      {:node=>:number, :pos=>25, :raw=>"0", :repr=>"0", :type=>:integer, :value=>0},
      {:node=>:number,
       :pos=>26,
       :raw=>"-2",
       :repr=>"-2",
       :type=>:integer,
       :value=>-2},
      {:node=>:whitespace, :pos=>28, :raw=>" "},
      {:node=>:unicode_range,
       :pos=>29,
       :raw=>"U+10-200000",
       :start=>16,
       :end=>2097152}
    ], tokens)
  end

  it 'should not get fooled by invalid Unicode range prefixes' do
    tokens = CT.tokenize("ù+12 Ü+12 u +12 U+ 12 U+12 - 20 U+1?2 U+1?-50")

    assert_equal([
      {:node=>:ident, :pos=>0, :raw=>"ù", :value=>"ù"},
      {:node=>:number,
       :pos=>1,
       :raw=>"+12",
       :repr=>"+12",
       :type=>:integer,
       :value=>12},
      {:node=>:whitespace, :pos=>4, :raw=>" "},
      {:node=>:ident, :pos=>5, :raw=>"Ü", :value=>"Ü"},
      {:node=>:number,
       :pos=>6,
       :raw=>"+12",
       :repr=>"+12",
       :type=>:integer,
       :value=>12},
      {:node=>:whitespace, :pos=>9, :raw=>" "},
      {:node=>:ident, :pos=>10, :raw=>"u", :value=>"u"},
      {:node=>:whitespace, :pos=>11, :raw=>" "},
      {:node=>:number,
       :pos=>12,
       :raw=>"+12",
       :repr=>"+12",
       :type=>:integer,
       :value=>12},
      {:node=>:whitespace, :pos=>15, :raw=>" "},
      {:node=>:ident, :pos=>16, :raw=>"U", :value=>"U"},
      {:node=>:delim, :pos=>17, :raw=>"+", :value=>"+"},
      {:node=>:whitespace, :pos=>18, :raw=>" "},
      {:node=>:number,
       :pos=>19,
       :raw=>"12",
       :repr=>"12",
       :type=>:integer,
       :value=>12},
      {:node=>:whitespace, :pos=>21, :raw=>" "},
      {:node=>:unicode_range, :pos=>22, :raw=>"U+12", :start=>18, :end=>18},
      {:node=>:whitespace, :pos=>26, :raw=>" "},
      {:node=>:delim, :pos=>27, :raw=>"-", :value=>"-"},
      {:node=>:whitespace, :pos=>28, :raw=>" "},
      {:node=>:number,
       :pos=>29,
       :raw=>"20",
       :repr=>"20",
       :type=>:integer,
       :value=>20},
      {:node=>:whitespace, :pos=>31, :raw=>" "},
      {:node=>:unicode_range, :pos=>32, :raw=>"U+1?", :start=>16, :end=>31},
      {:node=>:number, :pos=>36, :raw=>"2", :repr=>"2", :type=>:integer, :value=>2},
      {:node=>:whitespace, :pos=>37, :raw=>" "},
      {:node=>:unicode_range, :pos=>38, :raw=>"U+1?", :start=>16, :end=>31},
      {:node=>:number,
       :pos=>42,
       :raw=>"-50",
       :repr=>"-50",
       :type=>:integer,
       :value=>-50}
    ], tokens)
  end

  it 'should tokenize match operators and columns' do
    tokens = CT.tokenize("~=|=^=$=*=||<!------> |/**/| ~/**/=")

    assert_equal([
      {:node=>:include_match, :pos=>0, :raw=>"~="},
      {:node=>:dash_match, :pos=>2, :raw=>"|="},
      {:node=>:prefix_match, :pos=>4, :raw=>"^="},
      {:node=>:suffix_match, :pos=>6, :raw=>"$="},
      {:node=>:substring_match, :pos=>8, :raw=>"*="},
      {:node=>:column, :pos=>10, :raw=>"||"},
      {:node=>:cdo, :pos=>12, :raw=>"<!--"},
      {:node=>:delim, :pos=>16, :raw=>"-", :value=>"-"},
      {:node=>:delim, :pos=>17, :raw=>"-", :value=>"-"},
      {:node=>:cdc, :pos=>18, :raw=>"-->"},
      {:node=>:whitespace, :pos=>21, :raw=>" "},
      {:node=>:delim, :pos=>22, :raw=>"|", :value=>"|"},
      {:node=>:delim, :pos=>27, :raw=>"|", :value=>"|"},
      {:node=>:whitespace, :pos=>28, :raw=>" "},
      {:node=>:delim, :pos=>29, :raw=>"~", :value=>"~"},
      {:node=>:delim, :pos=>34, :raw=>"=", :value=>"="}
    ], tokens)
  end

  it 'should tokenize selector functions and rule blocks' do
    tokens = CT.tokenize("a:not([href^=http\\:],  [href ^=\t'https\\:'\n]) { color: rgba(0%, 100%, 50%); }")

    assert_equal([
      {:node=>:ident, :pos=>0, :raw=>"a", :value=>"a"},
      {:node=>:colon, :pos=>1, :raw=>":"},
      {:node=>:function, :pos=>2, :raw=>"not(", :value=>"not"},
      {:node=>:"[", :pos=>6, :raw=>"["},
      {:node=>:ident, :pos=>7, :raw=>"href", :value=>"href"},
      {:node=>:prefix_match, :pos=>11, :raw=>"^="},
      {:node=>:ident, :pos=>13, :raw=>"http\\:", :value=>"http:"},
      {:node=>:"]", :pos=>19, :raw=>"]"},
      {:node=>:comma, :pos=>20, :raw=>","},
      {:node=>:whitespace, :pos=>21, :raw=>"  "},
      {:node=>:"[", :pos=>23, :raw=>"["},
      {:node=>:ident, :pos=>24, :raw=>"href", :value=>"href"},
      {:node=>:whitespace, :pos=>28, :raw=>" "},
      {:node=>:prefix_match, :pos=>29, :raw=>"^="},
      {:node=>:whitespace, :pos=>31, :raw=>"\t"},
      {:node=>:string, :pos=>32, :raw=>"'https\\:'", :value=>"https:"},
      {:node=>:whitespace, :pos=>41, :raw=>"\n"},
      {:node=>:"]", :pos=>42, :raw=>"]"},
      {:node=>:")", :pos=>43, :raw=>")"},
      {:node=>:whitespace, :pos=>44, :raw=>" "},
      {:node=>:"{", :pos=>45, :raw=>"{"},
      {:node=>:whitespace, :pos=>46, :raw=>" "},
      {:node=>:ident, :pos=>47, :raw=>"color", :value=>"color"},
      {:node=>:colon, :pos=>52, :raw=>":"},
      {:node=>:whitespace, :pos=>53, :raw=>" "},
      {:node=>:function, :pos=>54, :raw=>"rgba(", :value=>"rgba"},
      {:node=>:percentage,
       :pos=>59,
       :raw=>"0%",
       :repr=>"0",
       :type=>:integer,
       :value=>0},
      {:node=>:comma, :pos=>61, :raw=>","},
      {:node=>:whitespace, :pos=>62, :raw=>" "},
      {:node=>:percentage,
       :pos=>63,
       :raw=>"100%",
       :repr=>"100",
       :type=>:integer,
       :value=>100},
      {:node=>:comma, :pos=>67, :raw=>","},
      {:node=>:whitespace, :pos=>68, :raw=>" "},
      {:node=>:percentage,
       :pos=>69,
       :raw=>"50%",
       :repr=>"50",
       :type=>:integer,
       :value=>50},
      {:node=>:")", :pos=>72, :raw=>")"},
      {:node=>:semicolon, :pos=>73, :raw=>";"},
      {:node=>:whitespace, :pos=>74, :raw=>" "},
      {:node=>:"}", :pos=>75, :raw=>"}"}
    ], tokens)
  end
end
