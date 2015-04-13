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
        _once: true,
        all: ->{ self.name = token }
      }, {
        _optional: true,
        _if: :expect_name?,
        left_chevron: ->{ special_name(token) }
      }, { # ( before args
        _unless: :leading_spaces?,
        _optional: true,
        open_paren: -> { states << token }
      }, { #need to catch space before args
        _optional: true,
        space: -> { states << " " }
      }, { #comma before args (must be parent's)
        _once: true,
        _optional: true,
        delimiter: ->{ close_scope.handle(token) }
      }
    ] + argument_handler(token) + [
      { #if we don't expect a ) but get one
        _unless: :expect_close_paren?,
        _optional: true,
        close_paren: ->{ close_scope.handle(token) }
      }, { # )
        _if: :expect_close_paren?,
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
        _optional: true,
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
        _optional: true,
        open_curley: -> { new_scope(ParsedBlock, blocks) },
        do: -> { new_scope(ParsedBlock, blocks) },
        close_curley: -> { close_scope.handle(token) }
      }
    ]
  end

  def argument_handler(token)
    [
      {
        _optional: true,
        _if: :open_for_multiline?,
        break: -> { }
      }, { #argument
        _optional: true,
        _if: :expect_argument?,
        word: ->{ new_scope(ParsedCall, arguments).handle(token) }
      }, { #comma after argument
        _optional: true,
        _if: :expect_delimiter?,
        delimiter: ->{ states << token }
      }
    ]
  end

end
