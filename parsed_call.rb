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
      raise "Unexpected #{token} (invalid operator #{name})"
    end
  end

  def handlers
    clear_token_handlers
    comment_handler

    history << token

    required_once :all, ->{ self.name = token }

    optional :left_chevron, ->{ special_name(token) },
      if: :expect_name?

    # ( before args
    optional :open_paren, -> { states << token },
      unless: :leading_spaces?

    # need to catch space before args
    optional :space, -> { states << " " }

    # comma before args (must be parent's)
    optional_once :delimiter, ->{ close_scope.handle(token) }

    argument_handler

    # if we don't expect a ) but get one
    optional :close_paren, ->{ close_scope.handle(token) },
      unless: :expect_close_paren?

    # )
    required :close_paren,  -> { states << token },
      if: :expect_close_paren?

    block_handler
    chain_handler
    required :break, ->{ close_scope.handle(token) }

  end

  def chain_handler
    optional :dot, -> { new_scope(ParsedCall, chains) }
    optional :equal, -> { new_scope(ParsedCall, chains).handle(token) }
    optional :plus, -> { new_scope(ParsedCall, chains).handle(token) }
    optional :dash, -> { new_scope(ParsedCall, chains).handle(token) }
    optional :forward_slash, -> { new_scope(ParsedCall, chains).handle(token) }
    optional :percent, -> { new_scope(ParsedCall, chains).handle(token) }
    optional :left_chevron, -> { new_scope(ParsedCall, chains).handle(token) }
  end

  def block_handler
    optional :open_curley, -> { new_scope(ParsedBlock, blocks) }
    optional :do, -> { new_scope(ParsedBlock, blocks) }
    optional :close_curley, -> { close_scope.handle(token) }
  end

  def argument_handler
    optional :break, -> { },
      if: :open_for_multiline?

    # argument
    optional :word, ->{ new_scope(ParsedCall, arguments).handle(token) },
      if: :expect_argument?

    # comma after argument
    optional :delimiter, ->{ states << token },
      if: :expect_delimiter?
  end

end
