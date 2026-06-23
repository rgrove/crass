# encoding: utf-8
require 'strscan'

module Crass

  # Similar to a StringScanner, but with extra functionality needed to tokenize
  # CSS while preserving the original text.
  class Scanner
    # Current character, or `nil` if the scanner hasn't yet consumed a
    # character, or is at the end of the string.
    attr_reader :current

    # Current marker position. Use {#marked} to get the substring between
    # {#marker} and {#pos}.
    attr_accessor :marker

    # Position of the next character that will be consumed. This is a character
    # position, not a byte position, so it accounts for multi-byte characters.
    #
    # Byte offsets (used internally for fast substring extraction) are tracked
    # separately by the underlying StringScanner, whose `pos` always reflects
    # the byte offset corresponding to this character position.
    attr_accessor :pos

    # String being scanned.
    attr_reader :string

    # Creates a Scanner instance for the given _input_ string or IO instance.
    def initialize(input)
      @string  = input.is_a?(IO) ? input.read : input.to_s
      @scanner = StringScanner.new(@string)

      reset
    end

    # Consumes the next character and returns it, advancing the pointer, or
    # an empty string if the end of the string has been reached.
    def consume
      if @pos < @len
        @pos    += 1
        @current = @scanner.getch
      else
        ''
      end
    end

    # Consumes the rest of the string and returns it, advancing the pointer to
    # the end of the string. Returns an empty string is the end of the string
    # has already been reached.
    def consume_rest
      result = @scanner.rest

      # `StringScanner#rest` does not advance the scan pointer, so move it to
      # the end of the input to keep the byte offset in sync with {#pos}. This
      # ensures a subsequent {#marked} extracts the correct substring.
      @scanner.terminate

      @current = result[-1]
      @pos     = @len

      result
    end

    # Returns `true` if the end of the string has been reached, `false`
    # otherwise.
    def eos?
      @pos == @len
    end

    # Sets the marker to the position of the next character that will be
    # consumed.
    def mark
      @byte_marker = @scanner.pos
      @marker      = @pos
    end

    # Returns the substring between {#marker} and {#pos}, without altering the
    # pointer.
    def marked
      # Extract the marked text using byte offsets rather than character
      # offsets. Slicing the original string by character offset is O(n) on
      # multi-byte input (Ruby must translate the character index into a byte
      # index), which makes tokenizing non-ASCII input superlinear. Byte slicing
      # is O(length) regardless of how far into the string we are.
      @string.byteslice(@byte_marker, @scanner.pos - @byte_marker) || ''
    end

    # Returns up to _length_ characters starting at the current position, but
    # doesn't consume them. The number of characters returned may be less than
    # _length_ if the end of the string is reached.
    def peek(length = 1)
      # Grab the bytes for up to _length_ characters and then take the first
      # _length_ characters. A UTF-8 character is at most four bytes, so `length
      # * 4` bytes always contains at least _length_ whole characters when that
      # many remain. This avoids the O(n) character-offset slice that
      # `@string[pos, length]` would otherwise perform on multi-byte input.
      @string.byteslice(@scanner.pos, length * 4).slice(0, length) || ''
    end

    # Moves the pointer back one character without changing the value of
    # {#current}. The next call to {#consume} will re-consume the current
    # character.
    def reconsume
      @scanner.unscan
      @pos -= 1 if @pos > 0
    end

    # Resets the pointer to the beginning of the string.
    def reset
      @scanner.reset

      @byte_marker = 0
      @current     = nil
      @len         = @string.size
      @marker      = 0
      @pos         = 0
    end

    # Tries to match _pattern_ at the current position. If it matches, the
    # matched substring will be returned and the pointer will be advanced.
    # Otherwise, `nil` will be returned.
    def scan(pattern)
      if match = @scanner.scan(pattern)
        @pos     += match.size
        @current  = match[-1]
      end

      match
    end

    # Scans the string until the _pattern_ is matched. Returns the substring up
    # to and including the end of the match, and advances the pointer. If there
    # is no match, `nil` is returned and the pointer is not advanced.
    def scan_until(pattern)
      if match = @scanner.scan_until(pattern)
        @pos     += match.size
        @current  = match[-1]
      end

      match
    end
  end

end
