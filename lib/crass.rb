# encoding: utf-8
require_relative 'crass/parser'

# A CSS parser based on the CSS Syntax Module Level 3 draft.
module Crass

  # Parses _input_ as a CSS stylesheet and returns a parse tree.
  #
  # See {Tokenizer#initialize} for _options_.
  def self.parse(input, options = {})
    Parser.parse_stylesheet(input, options)
  end

end
