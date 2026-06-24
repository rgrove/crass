# encoding: utf-8
require_relative 'crass/parser'

# A CSS parser based on the CSS Syntax Module Level 3 spec.
module Crass

  # Parses _input_ as a CSS stylesheet and returns a parse tree.
  #
  # Options:
  #
  #   * **:maximum_depth** - Maximum nesting depth for simple blocks and
  #     functions. Constructs nested more deeply than this are discarded to
  #     prevent stack exhaustion. Defaults to {Parser::DEFAULT_MAXIMUM_DEPTH}.
  #
  #   * **:preserve_comments** - If `true`, comments will be preserved as
  #     `:comment` tokens.
  #
  #   * **:preserve_hacks** - If `true`, certain non-standard browser hacks
  #     such as the IE "*" hack will be preserved even though they violate
  #     CSS 3 syntax rules.
  #
  def self.parse(input, options = {})
    Parser.parse_stylesheet(input, options)
  end

  # Parses _input_ as a string of CSS properties (such as the contents of an
  # HTML element's `style` attribute) and returns a parse tree.
  #
  # See {Crass.parse} for _options_.
  def self.parse_properties(input, options = {})
    Parser.parse_properties(input, options)
  end

end
