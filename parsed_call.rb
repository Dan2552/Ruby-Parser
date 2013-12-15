class ParsedCall < ParsedBase
  children :arguments, :blocks, :chains

  def chain
    chains.first
  end

  def block
    blocks.first
  end

  def expect_close_paren?
    states.select { |s| s == "(" }.count >
      states.select { |s| s == ")" }.count
  end

  def expect_delimiter?
    arguments.count > argument_delimeter_count
  end

  def argument_delimeter_count
    states.select { |s| s == "," }.count
  end

  def expect_argument?
    arguments.count == argument_delimeter_count
  end

  def leading_spaces?
    states.include? " "
  end

  def open_for_multiline?
    (arguments.count > 0 && expect_argument?) ||
      expect_close_paren?
  end

  def token_handler(token)
    comment_handler(token) + [
      { #name
        once: true,
        all: ->{ self.name = token }
      }, { # ( before args
        unless: :leading_spaces?,
        optional: true,
        open_paren: -> { states << token }
      }, { #need to catch space before args
        optional: true,
        space: -> { states << " " }
      }, { #comma before args (must be parent's)
        once: true,
        optional: true,
        delimiter: ->{ close_scope.handle(token) }
      }
    ] + argument_handler(token) + [
      { #if we don't expect a ) but get one
        unless: :expect_close_paren?,
        optional: true,
        close_paren: ->{ close_scope.handle(token) }
      }, { # )
        if: :expect_close_paren?,
        close_paren: -> { states << token }
      }
    ] + block_handler(token) + [
    ] + chain_handler(token) + [
      {
        break: ->{ close_scope.handle(token) }
      }
    ]
  end

  def chain_handler(token)
    [
      {
        optional: true,
        dot: -> { new_scope(ParsedCall, chains) }
      }, {
        optional: true,
        equal: -> { new_scope(ParsedCall, chains).handle(token) }
      }, {
        optional: true,
        plus: -> { new_scope(ParsedCall, chains).handle(token) }
      }, {
        optional: true,
        dash: -> { new_scope(ParsedCall, chains).handle(token) }
      }, {
        optional: true,
        forward_slash: -> { new_scope(ParsedCall, chains).handle(token) }
      }, {
        optional: true,
        percent: -> { new_scope(ParsedCall, chains).handle(token) }
      }
    ]
  end

  def block_handler(token)
    [
      { # { block open
        optional: true,
        open_curley: -> { new_scope(ParsedBlock, blocks) }
      }, { # do block open
        optional: true,
        do: -> { new_scope(ParsedBlock, blocks) }
      }, { # } block close (passed down to parent Block)
        optional: true,
        close_curley: -> { close_scope.handle(token) }
      }
    ]
  end

  def argument_handler(token)
    [
      {
        optional: true,
        if: :open_for_multiline?,
        break: -> { }
      }, { #argument
        optional: true,
        if: :expect_argument?,
        word: ->{ new_scope(ParsedCall, arguments).handle(token) }
      }, { #comma after argument
        optional: true,
        if: :expect_delimiter?,
        delimiter: ->{ states << token }
      }
    ]
  end

end
