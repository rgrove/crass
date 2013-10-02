# encoding: utf-8
require_relative 'support/common'

describe 'Serialization' do
  parallelize_me!

  Dir[File.join(File.dirname(__FILE__), 'support/serialization/*.css')].each do |filepath|
    it "should parse and serialize #{filepath}" do
      input  = File.read(filepath)

      tree = Crass.parse(input,
        :preserve_comments => true,
        :preserve_hacks => true)

      output = CP.stringify(tree)

      assert_equal(input, output)
    end
  end
end
