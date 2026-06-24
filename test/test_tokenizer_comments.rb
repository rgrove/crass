# encoding: utf-8

# Regression tests ensuring that long runs of adjacent comments don't exhaust
# the Ruby stack (`SystemStackError`) when comments are discarded.

require_relative 'support/common'

describe 'Crass::Tokenizer adjacent comment handling' do
  make_my_diffs_pretty!
  parallelize_me!

  # Well above the empirically observed ~12,000-comment crash threshold.
  COMMENT_COUNT = 50_000

  describe 'with the default options (comments discarded)' do
    it 'should not raise SystemStackError on a long run of adjacent comments' do
      css = '/**/' * COMMENT_COUNT
      refute_nil(Crass.parse(css))
    end

    it 'should produce no tokens for a long run of adjacent comments' do
      css = '/**/' * COMMENT_COUNT
      assert_empty(Crass::Tokenizer.tokenize(css))
    end

    it 'should skip comments interleaved with real tokens' do
      tokens = Crass::Tokenizer.tokenize('/**/a/**/b')

      assert_equal([:ident, :ident], tokens.map { |t| t[:node] })
      assert_equal(%w[a b], tokens.map { |t| t[:value] })
    end
  end

  describe 'with :preserve_comments => true' do
    it 'should not raise SystemStackError and should preserve every comment' do
      css    = '/**/' * COMMENT_COUNT
      tokens = Crass::Tokenizer.tokenize(css, :preserve_comments => true)

      assert_equal(COMMENT_COUNT, tokens.length)
      assert(tokens.all? { |t| t[:node] == :comment })
    end
  end
end
