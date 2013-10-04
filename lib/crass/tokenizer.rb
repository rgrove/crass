# encoding: utf-8
require_relative 'scanner'

module Crass

  # Tokenizes a CSS string.
  #
  # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#tokenization
  class Tokenizer
    RE_COMMENT_CLOSE   = /\*\//
    RE_DIGIT           = /[0-9]+/
    RE_ESCAPE          = /\\[^\n]/
    RE_HEX             = /[0-9A-Fa-f]{1,6}/
    RE_NAME            = /[0-9A-Za-z_\u0080-\u{10ffff}-]+/
    RE_NAME_START      = /[A-Za-z_\u0080-\u{10ffff}]+/
    RE_NON_PRINTABLE   = /[\u0000-\u0008\u000b\u000e-\u001f\u007f]+/
    RE_NUMBER_DECIMAL  = /\.[0-9]+/
    RE_NUMBER_EXPONENT = /[Ee][+-]?[0-9]+/
    RE_NUMBER_SIGN     = /[+-]/

    RE_NUMBER_STR = /\A
      (?<sign> [+-]?)
      (?<integer> [0-9]*)
      (?:\.
        (?<fractional> [0-9]*)
      )?
      (?:[Ee]
        (?<exponent_sign> [+-]?)
        (?<exponent> [0-9]*)
      )?
    \z/x

    RE_UNICODE_RANGE_START = /\+(?:[0-9A-Fa-f]|\?)/
    RE_UNICODE_RANGE_END   = /-[0-9A-Fa-f]/
    RE_WHITESPACE          = /[\n\u0009\u0020]+/

    # -- Class Methods ---------------------------------------------------------

    # Tokenizes the given _input_ as a CSS string and returns an array of
    # tokens.
    #
    # See {#initialize} for _options_.
    def self.tokenize(input, options = {})
      Tokenizer.new(input, options).tokenize
    end

    # -- Instance Methods ------------------------------------------------------

    # Initializes a new Tokenizer.
    #
    # Options:
    #
    #   * **:preserve_comments** - If `true`, comments will be preserved as
    #     `:comment` tokens.
    #
    #   * **:preserve_hacks** - If `true`, certain non-standard browser hacks
    #     such as the IE "*" hack will be preserved even though they violate
    #     CSS 3 syntax rules.
    #
    def initialize(input, options = {})
      @s       = Scanner.new(preprocess(input))
      @options = options
    end

    # Consumes a token and returns the token that was consumed.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-token0
    def consume
      return nil if @s.eos?

      @s.mark
      return create_token(:whitespace) if @s.scan(RE_WHITESPACE)

      char = @s.consume

      case char.to_sym
      when :'"'
        consume_string('"')

      when :'#'
        if @s.peek =~ RE_NAME || valid_escape?
          create_token(:hash,
            :type  => start_identifier? ? :id : :unrestricted,
            :value => consume_name)
        else
          create_token(:delim, :value => char)
        end

      when :'$'
        if @s.peek == '='
          @s.consume
          create_token(:suffix_match)
        else
          create_token(:delim, :value => char)
        end

      when :"'"
        consume_string("'")

      when :'('
        create_token(:'(')

      when :')'
        create_token(:')')

      when :*
        if @s.peek == '='
          @s.consume
          create_token(:substring_match)

        elsif @options[:preserve_hacks] && @s.peek =~ RE_NAME_START
          # NON-STANDARD: IE * hack
          @s.reconsume
          consume_ident

        else
          create_token(:delim, :value => char)
        end

      when :+
        if start_number?(char + @s.peek(2))
          @s.reconsume
          consume_numeric
        else
          create_token(:delim, :value => char)
        end

      when :','
        create_token(:comma)

      when :-
        if start_number?(char + @s.peek(2))
          @s.reconsume
          consume_numeric
        elsif start_identifier?(char + @s.peek(2))
          @s.reconsume
          consume_ident
        elsif @s.peek(2) == '->'
          @s.consume
          @s.consume
          create_token(:cdc)
        else
          create_token(:delim, :value => char)
        end

      when :'.'
        if start_number?(char + @s.peek(2))
          @s.reconsume
          consume_numeric
        else
          create_token(:delim, :value => char)
        end

      when :/
        if @s.peek == '*'
          @s.consume

          if text = @s.scan_until(RE_COMMENT_CLOSE)
            text.slice!(-2, 2)
          else
            text = @s.consume_rest
          end

          if @options[:preserve_comments]
            create_token(:comment, :value => text)
          else
            consume
          end
        else
          create_token(:delim, :value => char)
        end

      when :':'
        create_token(:colon)

      when :';'
        create_token(:semicolon)

      when :<
        if @s.peek(3) == '!--'
          @s.consume
          @s.consume
          @s.consume

          create_token(:cdo)
        else
          create_token(:delim, :value => char)
        end

      when :'@'
        if start_identifier?
          create_token(:at_keyword, :value => consume_name)
        else
          create_token(:delim, :value => char)
        end

      when :'['
        create_token(:'[')

      when :'\\'
        if valid_escape?(char + @s.peek)
          @s.reconsume
          consume_ident
        else
          create_token(:delim,
            :error => true,
            :value => char)
        end

      when :']'
        create_token(:']')

      when :'^'
        if @s.peek == '='
          @s.consume
          create_token(:prefix_match)
        else
          create_token(:delim, :value => char)
        end

      when :'{'
        create_token(:'{')

      when :'}'
        create_token(:'}')

      when :U, :u
        if @s.peek(2) =~ RE_UNICODE_RANGE_START
          @s.consume
          consume_unicode_range
        else
          @s.reconsume
          consume_ident
        end

      when :|
        case @s.peek
        when '='
          @s.consume
          create_token(:dash_match)

        when '|'
          @s.consume
          create_token(:column)

        else
          create_token(:delim, :value => char)
        end

      when :~
        if @s.peek == '='
          @s.consume
          create_token(:include_match)
        else
          create_token(:delim, :value => char)
        end

      else
        case char
        when RE_DIGIT
          @s.reconsume
          consume_numeric

        when RE_NAME_START
          @s.reconsume
          consume_ident

        else
          create_token(:delim, :value => char)
        end
      end
    end

    # Consumes the remnants of a bad URL and returns the consumed text.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-the-remnants-of-a-bad-url
    def consume_bad_url
      text = ''

      until @s.eos?
        if valid_escape?(@s.current + @s.peek)
          text << consume_escaped
        elsif valid_escape?
          @s.consume
          text << consume_escaped
        else
          char = @s.consume

          if char == ')'
            break
          else
            text << char
          end
        end
      end

      text
    end

    # Consumes an escaped code point and returns its unescaped value.
    #
    # This method assumes that the `\` has already been consumed, and that the
    # next character in the input has already been verified not to be a newline
    # or EOF.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-an-escaped-code-point0
    def consume_escaped
      case
      when @s.eos?
        "\ufffd"

      when hex_str = @s.scan(RE_HEX)
        @s.consume if @s.peek =~ RE_WHITESPACE

        codepoint = hex_str.hex

        if codepoint == 0 ||
            codepoint.between?(0xD800, 0xDFFF) ||
            codepoint > 0x10FFFF

          "\ufffd"
        else
          codepoint.chr(Encoding::UTF_8)
        end

      else
        @s.consume
      end
    end

    # Consumes an ident-like token and returns it.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-an-ident-like-token
    def consume_ident
      value = consume_name

      if @s.peek == '('
        @s.consume

        if value.downcase == 'url'
          consume_url
        else
          create_token(:function, :value => value)
        end
      else
        create_token(:ident, :value => value)
      end
    end

    # Consumes a name and returns it.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-name
    def consume_name
      result = ''

      while true
        if match = @s.scan(RE_NAME)
          result << match
          next
        end

        char = @s.peek

        if char == '\\' && valid_escape?
          @s.consume
          result << consume_escaped

        # NON-STANDARD: IE * hack
        elsif @options[:preserve_hacks] && char == '*'
          result << @s.consume

        else
          return result
        end
      end
    end

    # Consumes a number and returns a 3-element array containing the number's
    # original representation, its numeric value, and its type (either
    # `:integer` or `:number`).
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-number0
    def consume_number
      repr = ''
      type = :integer

      repr << @s.consume if @s.peek =~ RE_NUMBER_SIGN
      repr << (@s.scan(RE_DIGIT) || '')

      if match = @s.scan(RE_NUMBER_DECIMAL)
        repr << match
        type = :number
      end

      if match = @s.scan(RE_NUMBER_EXPONENT)
        repr << match
        type = :number
      end

      [repr, convert_string_to_number(repr), type]
    end

    # Consumes a numeric token and returns it.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-numeric-token
    def consume_numeric
      number = consume_number

      if start_identifier?
        create_token(:dimension,
          :repr  => number[0],
          :type  => number[2],
          :unit  => consume_name,
          :value => number[1])

      elsif @s.peek == '%'
        @s.consume

        create_token(:percentage,
          :repr  => number[0],
          :type  => number[2],
          :value => number[1])

      else
        create_token(:number,
          :repr  => number[0],
          :type  => number[2],
          :value => number[1])
      end
    end

    # Consumes a string token that ends at the given character, and returns the
    # token.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-string-token
    def consume_string(ending)
      value = ''

      until @s.eos?
        case char = @s.consume
        when ending
          break

        when "\n"
          @s.reconsume
          return create_token(:bad_string,
            :error => true,
            :value => value)

        when '\\'
          case @s.peek
          when ''
            # End of the input, so do nothing.
            next

          when "\n"
            @s.consume

          else
            value << consume_escaped
          end

        else
          value << char
        end
      end

      create_token(:string, :value => value)
    end

    # Consumes a Unicode range token and returns it. Assumes the initial "u+" or
    # "U+" has already been consumed.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-unicode-range-token
    def consume_unicode_range
      value = @s.scan(RE_HEX) || ''

      while value.length < 6
        break unless @s.peek == '?'
        value << @s.consume
      end

      range = {}

      if value.include?('?')
        range[:start] = value.gsub('?', '0').hex
        range[:end]   = value.gsub('?', 'F').hex
        return create_token(:unicode_range, range)
      end

      range[:start] = value.hex

      if @s.peek(2) =~ RE_UNICODE_RANGE_END
        @s.consume
        range[:end] = (@s.scan(RE_HEX) || '').hex
      else
        range[:end] = range[:start]
      end

      create_token(:unicode_range, range)
    end

    # Consumes a URL token and returns it. Assumes the original "url(" has
    # already been consumed.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-url-token
    def consume_url
      value = ''

      @s.scan(RE_WHITESPACE)

      if @s.eos?
        return create_token(:url, :value => value)
      end

      # Quoted URL.
      next_char = @s.peek

      if next_char == "'" || next_char == '"'
        string = consume_string(@s.consume)

        if string[:node] == :bad_string
          return create_token(:bad_url,
            :value => string[:value] + consume_bad_url)
        end

        value = string[:value]
        @s.scan(RE_WHITESPACE)

        if @s.eos? || @s.peek == ')'
          @s.consume
          return create_token(:url, :value => value)
        else
          return create_token(:bad_url, :value => value + consume_bad_url)
        end
      end

      # Unquoted URL.
      until @s.eos?
        case char = @s.consume
        when ')'
          break

        when RE_WHITESPACE
          @s.scan(RE_WHITESPACE)

          if @s.eos? || @s.peek == ')'
            @s.consume
            break
          else
            return create_token(:bad_url, :value => value + consume_bad_url)
          end

        when '"', "'", '(', RE_NON_PRINTABLE
          return create_token(:bad_url,
            :error => true,
            :value => value + consume_bad_url)

        when '\\'
          if valid_escape?(char + @s.peek)
            value << consume_escaped
          else
            return create_token(:bad_url,
              :error => true,
              :value => value + consume_bad_url
            )
          end

        else
          value << char
        end
      end

      create_token(:url, :value => value)
    end

    # Converts a valid CSS number string into a number and returns the number.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#convert-a-string-to-a-number0
    def convert_string_to_number(str)
      matches = RE_NUMBER_STR.match(str)

      s = matches[:sign] == '-' ? -1 : 1
      i = matches[:integer].to_i
      f = matches[:fractional].to_i
      d = matches[:fractional] ? matches[:fractional].length : 0
      t = matches[:exponent_sign] == '-' ? -1 : 1
      e = matches[:exponent].to_i

      # I know this looks nutty, but it's exactly what's defined in the spec,
      # and it works.
      s * (i + f * 10**-d) * 10**(t * e)
    end

    # Creates and returns a new token with the given _properties_.
    def create_token(type, properties = {})
      {
        :node => type,
        :pos  => @s.marker,
        :raw  => @s.marked
      }.merge!(properties)
    end

    # Preprocesses _input_ to prepare it for the tokenizer.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#input-preprocessing
    def preprocess(input)
      input = input.to_s.encode('UTF-8',
        :invalid => :replace,
        :undef   => :replace)

      input.gsub!(/(?:\r\n|[\r\f])/, "\n")
      input.gsub!("\u0000", "\ufffd")
      input
    end

    # Returns `true` if the given three-character _text_ would start an
    # identifier. If _text_ is `nil`, the next three characters in the input
    # stream will be checked, but will not be consumed.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#check-if-three-code-points-would-start-an-identifier
    def start_identifier?(text = nil)
      text = @s.peek(3) if text.nil?

      case text[0]
      when '-'
        !!(text[1] =~ RE_NAME_START || valid_escape?(text[1, 2]))

      when RE_NAME_START
        true

      when '\\'
        valid_escape?(text[0, 2])

      else
        false
      end
    end

    # Returns `true` if the given three-character _text_ would start a number.
    # If _text_ is `nil`, the next three characters in the input stream will be
    # checked, but will not be consumed.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#check-if-three-code-points-would-start-a-number
    def start_number?(text = nil)
      text = @s.peek(3) if text.nil?

      case text[0]
      when '+', '-'
        !!(text[1] =~ RE_DIGIT || (text[1] == '.' && text[2] =~ RE_DIGIT))

      when '.'
        !!(text[1] =~ RE_DIGIT)

      when RE_DIGIT
        true

      else
        false
      end
    end

    # Tokenizes the input stream and returns an array of tokens.
    def tokenize
      @s.reset

      tokens = []

      while token = consume
        tokens << token
      end

      tokens
    end

    # Returns `true` if the given two-character _text_ is the beginning of a
    # valid escape sequence. If _text_ is `nil`, the next two characters in the
    # input stream will be checked, but will not be consumed.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#check-if-two-code-points-are-a-valid-escape
    def valid_escape?(text = nil)
      text = @s.peek(2) if text.nil?
      !!(text[0] == '\\' && text[1] != "\n")
    end
  end

end
