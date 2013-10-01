# encoding: utf-8
gem 'minitest'
require 'minitest/autorun'

require_relative '../../lib/crass'

CP = Crass::Parser
CT = Crass::Tokenizer

# Hack shared test support into MiniTest.
MiniTest::Spec.class_eval do
  def self.shared_tests
    @shared_tests ||= {}
  end
end

module MiniTest::Spec::SharedTests
  def behaves_like(desc)
    self.instance_eval(&MiniTest::Spec.shared_tests[desc])
  end

  def shared_tests_for(desc, &block)
    MiniTest::Spec.shared_tests[desc] = block
  end
end

Object.class_eval { include MiniTest::Spec::SharedTests }

# Custom assertions and helpers.
def assert_tokens(input, actual, offset = 0, options = {})
  actual = [actual] unless actual.is_a?(Array)
  tokens = tokenize(input, offset, options)

  assert_equal tokens, actual
end

def reposition_tokens(tokens, offset)
  tokens.each {|token| token[:pos] += offset }
  tokens
end

def tokenize(input, offset = 0, options = {})
  tokens = CT.tokenize(input, options)
  reposition_tokens(tokens, offset) unless offset == 0
  tokens
end
