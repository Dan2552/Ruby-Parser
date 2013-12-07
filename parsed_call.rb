class ParsedCall < ParsedBase
  children :arguments

  def states
    @states ||= []
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

  def token_handler(token)
    [
      { #name
        once: true,
        word: ->{ self.name = token }
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
      }, { #argument
        optional: true,
        if: :expect_argument?,
        word: ->{ new_scope(ParsedCall, arguments).handle(token) }
      }, { #comma after argument
        optional: true,
        if: :expect_delimiter?,
        delimiter: ->{ states << token }
      }, { #if we don't expect a ) but get one
        unless: :expect_close_paren?,
        optional: true,
        close_paren: ->{ close_scope.handle(token) }
      }, { # )
        if: :expect_close_paren?,
        close_paren: -> { states << token }
      }, {
        break: ->{ close_scope.handle(token) }
      }
    ]
  end

end
