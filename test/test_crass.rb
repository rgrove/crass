# encoding: utf-8
require_relative 'support/common'

describe 'Crass.parse' do
  it 'should call Crass::Parser.parse_stylesheet with input and options' do
    assert_equal(
      CP.parse_stylesheet(" /**/ .foo {} #bar {}"),
      Crass.parse(" /**/ .foo {} #bar {}")
    )

    assert_equal(
      CP.parse_stylesheet(" /**/ .foo {} #bar {}", :preserve_comments => true),
      Crass.parse(" /**/ .foo {} #bar {}", :preserve_comments => true)
    )
  end
end
