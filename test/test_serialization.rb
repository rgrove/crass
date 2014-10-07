# encoding: utf-8
require_relative 'support/common'

describe 'Serialization' do
  make_my_diffs_pretty!
  parallelize_me!

  # Parse a bunch of real-world CSS and make sure it's the same when we
  # serialize it.
  Dir[File.join(File.dirname(__FILE__), 'support/serialization/*.css')].each do |filepath|
    it "should parse and serialize #{filepath}" do
      input = File.read(filepath)

      tree = Crass.parse(input,
        :preserve_comments => true,
        :preserve_hacks => true)

      assert_equal(input, CP.stringify(tree))
    end
  end

  # -- Regression tests --------------------------------------------------------
  it "should not omit a trailing semicolon when serializing a `@charset` rule" do
    css  = '@charset "utf-8";'
    tree = Crass.parse(css)

    assert_equal(css, CP.stringify(tree))
  end
end
