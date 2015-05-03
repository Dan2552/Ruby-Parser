module DefinitionArgumentList
  #e.g.
  # method definition: def my_method(***arg1, arg2, arg3***)
  # block definition: { |***arg1, arg2***| blah }

  def definition_argument_list
    required :word, -> { arguments << token },
      if: :expect_arguments?,
      unless: :expect_argument_delimiter?
    optional :delimiter, -> { states << token },
      if: :expect_argument_delimiter?
  end

  def expect_argument_delimiter?
    arguments.count > argument_delimiter_count
  end

  def argument_delimiter_count
    states.select { |s| s == "," }.count
  end

end
