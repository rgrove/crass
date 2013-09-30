# encoding: utf-8
gem 'minitest'
require 'minitest/autorun'

require_relative '../../lib/crass'

CP = Crass::Parser
CT = Crass::Tokenizer

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
