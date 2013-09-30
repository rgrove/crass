# encoding: utf-8
require_relative 'token-scanner'
require_relative 'tokenizer'

module Crass

  # Parses a CSS string or list of tokens.
  #
  # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#parsing
  class Parser
    BLOCK_END_TOKENS = {
      :'{' => :'}',
      :'[' => :']',
      :'(' => :')'
    }

    # -- Class Methods ---------------------------------------------------------

    # Parses a CSS stylesheet and returns a parse tree.
    #
    # See {Tokenizer#initialize} for _options_.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#parse-a-stylesheet
    def self.parse_stylesheet(input, options = {})
      parser = Parser.new(input, options)
      rules  = parser.consume_rules(:top_level => true)

      rules.map do |rule|
        case rule[:node]
        # TODO: handle at-rules
        when :qualified_rule then parser.create_style_rule(rule)
        else rule
        end
      end
    end

    # Converts a node or array of nodes into a CSS string based on their
    # original tokenized input.
    #
    # Options:
    #
    #   * **:exclude_comments** - When `true`, comments will be excluded.
    #
    def self.stringify(nodes, options = {})
      nodes  = [nodes] unless nodes.is_a?(Array)
      string = ''

      nodes.each do |node|
        case node[:node]
        when :comment
          string << node[:raw] unless options[:exclude_comments]

        when :style_rule
          string << self.stringify(node[:selector][:tokens], options)
          string << "{"
          string << self.stringify(node[:children], options)
          string << "}"

        when :property
          string << options[:indent] if options[:indent]
          string << self.stringify(node[:tokens], options)

        else
          if node.key?(:raw)
            string << node[:raw]
          elsif node.key?(:tokens)
            string << self.stringify(node[:tokens], options)
          end
        end
      end

      string
    end

    # -- Instance Methods ------------------------------------------------------

    # Array of tokens generated from this parser's input.
    attr_reader :tokens

    # Initializes a parser based on the given _input_, which may be a CSS string
    # or an array of tokens.
    #
    # See {Tokenizer#initialize} for _options_.
    def initialize(input, options = {})
      unless input.kind_of?(Enumerable)
        input = Tokenizer.tokenize(input, options)
      end

      @tokens = TokenScanner.new(input)
    end

    # Consumes an at-rule and returns it.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-an-at-rule
    def consume_at_rule(input = @tokens)
      rule = {}

      rule[:tokens] = input.collect do
        rule[:name]    = parse_value(input.consume)
        rule[:prelude] = []

        while token = input.consume
          case token[:node]
          when :comment then next
          when :semicolon, :eof then break

          when :'{' then
            rule[:block] = consume_simple_block(input)
            break

          # TODO: At this point, the spec says we should check for a "simple
          # block with an associated token of <<{-token>>", but isn't that
          # exactly what we just did above? And the tokenizer only ever produces
          # standalone <<{-token>>s, so how could the token stream ever contain
          # one that's already associated with a simple block? What am I
          # missing?

          else
            input.reconsume
            rule[:prelude] << consume_component_value(input)
          end
        end
      end

      create_node(:at_rule, rule)
    end

    # Consumes a component value and returns it.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-component-value0
    def consume_component_value(input = @tokens)
      return nil unless token = input.consume

      case token[:node]
      when :'{', :'[', :'(' then consume_simple_block(input)
      when :function then consume_function(input)
      else token
      end
    end

    # Consumes a declaration and returns it, or `nil` on parse error.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-declaration0
    def consume_declaration(input = @tokens)
      declaration = {}

      declaration[:tokens] = input.collect do
        declaration[:name] = input.consume[:value]

        value = []
        token = input.consume
        token = input.consume while token[:node] == :whitespace

        return nil if token[:node] != :colon # TODO: parse error

        value << token while token = input.consume
        declaration[:value] = value

        maybe_important = value.reject {|v| v[:node] == :whitespace }[-2, 2]

        if maybe_important &&
            maybe_important[0][:node] == :delim &&
            maybe_important[0][:value] == '!' &&
            maybe_important[1][:node] == :ident &&
            maybe_important[1][:value].downcase == 'important'

          declaration[:important] = true
        end
      end

      create_node(:declaration, declaration)
    end

    # Consumes a list of declarations and returns them.
    #
    # NOTE: The returned list may include `:comment`, `:semicolon`, and
    # `:whitespace` nodes, which is non-standard.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-list-of-declarations0
    def consume_declarations(input = @tokens)
      declarations = []

      while token = input.consume
        case token[:node]
        when :comment, :semicolon, :whitespace
          declarations << token

        when :at_keyword
          # TODO: this is technically a parse error when parsing a style rule,
          # but not necessarily at other times.

          # TODO: It seems like we should reconsume the current token here,
          # since that's what happens when consuming a list of rules.
          declarations << consume_at_rule(input)

        when :ident
          decl_tokens = [token]
          input.consume

          while input.current
            decl_tokens << input.current
            break if input.current[:node] == :semicolon
            input.consume
          end

          if decl = consume_declaration(TokenScanner.new(decl_tokens))
            declarations << decl
          end

        else
          # TODO: parse error (invalid property name, etc.)
          while token && token[:node] != :semicolon
            token = consume_component_value(input)
          end
        end
      end

      declarations
    end

    # Consumes a function and returns it.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-function
    def consume_function(input = @tokens)
      function = {
        :name   => input.current[:value],
        :value  => [],
        :tokens => [input.current]
      }

      function[:tokens].concat(input.collect do
        while token = input.consume
          case token[:node]
          when :')', :eof then break
          when :comment then next

          else
            input.reconsume
            function[:value] << consume_component_value(input)
          end
        end
      end)

      create_node(:function, function)
    end

    # Consumes a qualified rule and returns it, or `nil` if a parse error
    # occurs.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-qualified-rule0
    def consume_qualified_rule(input = @tokens)
      rule = {:prelude => []}

      rule[:tokens] = input.collect do
        while true
          return nil unless token = input.consume

          if token[:node] == :'{'
            rule[:block] = consume_simple_block(input)
            break

          # elsif [simple block with an associated <<{-token>>??]

          # TODO: At this point, the spec says we should check for a "simple block
          # with an associated token of <<{-token>>", but isn't that exactly what
          # we just did above? And the tokenizer only ever produces standalone
          # <<{-token>>s, so how could the token stream ever contain one that's
          # already associated with a simple block? What am I missing?

          else
            input.reconsume
            rule[:prelude] << consume_component_value(input)
          end
        end
      end

      create_node(:qualified_rule, rule)
    end

    # Consumes a list of rules and returns them.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-list-of-rules0
    def consume_rules(flags = {})
      rules = []

      while true
        return rules unless token = @tokens.consume

        case token[:node]
          when :comment, :whitespace then rules << token
          when :eof then return rules

          when :cdc, :cdo
            unless flags[:top_level]
              @tokens.reconsume
              rule = consume_qualified_rule
              rules << rule if rule
            end

          when :at_keyword
            @tokens.reconsume
            rule = consume_at_rule
            rules << rule if rule

          else
            @tokens.reconsume
            rule = consume_qualified_rule
            rules << rule if rule
        end
      end
    end

    # Consumes and returns a simple block associated with the current input
    # token.
    #
    # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-simple-block0
    def consume_simple_block(input = @tokens)
      start_token = input.current[:node]
      end_token   = BLOCK_END_TOKENS[start_token]

      block = {
        :start  => start_token.to_s,
        :end    => end_token.to_s,
        :value  => [],
        :tokens => [input.current]
      }

      block[:tokens].concat(input.collect do
        while token = input.consume
          break if token[:node] == end_token || token[:node] == :eof

          input.reconsume
          block[:value] << consume_component_value(input)
        end
      end)

      create_node(:simple_block, block)
    end

    # Creates and returns a new parse node with the given _properties_.
    def create_node(type, properties = {})
      {:node => type}.merge!(properties)
    end

    # Parses the given _input_ tokens into a selector node and returns it.
    #
    # Doesn't bother splitting the selector list into individual selectors or
    # validating them. Feel free to do that yourself! It'll be fun!
    def create_selector(input)
      create_node(:selector,
        :value  => parse_value(input),
        :tokens => input)
    end

    # Creates a `:style_rule` node from the given qualified _rule_, and returns
    # it.
    #
    # * http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#style-rules
    # * http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#consume-a-list-of-declarations0
    def create_style_rule(rule)
      children = []
      tokens   = TokenScanner.new(rule[:block][:value])

      consume_declarations(tokens).each do |decl|
        unless decl[:node] == :declaration
          children << decl
          next
        end

        children << create_node(:property,
          :name   => decl[:name],
          :value  => parse_value(decl[:value]),
          :tokens => decl[:tokens])
      end

      create_node(:style_rule,
        :selector => create_selector(rule[:prelude]),
        :children => children
      )
    end

    # Returns the unescaped value of a selector name or property declaration.
    def parse_value(nodes)
      string = ''

      nodes = [nodes] unless nodes.is_a?(Array)

      nodes.each do |node|
        case node[:node]
        when :comment, :semicolon then next

        when :at_keyword, :ident
          string << node[:value]

        when :function
          if node[:value].is_a?(String)
            string << node[:value]
          else
            string << parse_value(node[:value])
          end

        else
          if node.key?(:raw)
            string << node[:raw]
          elsif node.key?(:tokens)
            string << parse_value(node[:tokens])
          end
        end
      end

      string.strip
    end
  end

end
