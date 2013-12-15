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

  def expect_name?
    !(history.include?(" ") || history.include?("("))
  end

  def history
    @history ||= []
  end

  def special_name(token)
    self.name = "#{name}#{token}"

    unless ["<<"].include?(name)
      raise "Unexpeced #{token} (invalid operator #{name})"
    end
  end

  def token_handler(token)
    history << token
    comment_handler(token) + [
      { #name
        once: true,
        all: ->{ self.name = token }
      }, {
        optional: true,
        if: :expect_name?,
        left_chevron: ->{ special_name(token) }
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
        dot: -> { new_scope(ParsedCall, chains) },
        equal: -> { new_scope(ParsedCall, chains).handle(token) },
        plus: -> { new_scope(ParsedCall, chains).handle(token) },
        dash: -> { new_scope(ParsedCall, chains).handle(token) },
        forward_slash: -> { new_scope(ParsedCall, chains).handle(token) },
        percent: -> { new_scope(ParsedCall, chains).handle(token) },
        left_chevron: -> { new_scope(ParsedCall, chains).handle(token) }
      }
    ]
  end

  def block_handler(token)
    [
      { # { block open
        optional: true,
        open_curley: -> { new_scope(ParsedBlock, blocks) },
        do: -> { new_scope(ParsedBlock, blocks) },
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
