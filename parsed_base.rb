class ParsedBase

  attr_accessor :name
  attr_reader :parent

  KEYWORDS = [
    "BEGIN",
    "END",
    "__ENCODING__",
    "__END__",
    "__FILE__",
    "__LINE__",
    "alias",
    "and",
    "begin",
    "break",
    "case",
    "class",
    "def",
    "defined?",
    "do",
    "else",
    "elsif",
    "end",
    "ensure",
    "false",
    "for",
    "if",
    "in",
    "module",
    "next",
    "nil",
    "not",
    "or",
    "redo",
    "rescue",
    "retry",
    "return",
    "self",
    "super",
    "then",
    "true",
    "undef",
    "unless",
    "until",
    "when",
    "while",
    "yield"
  ]

  def initialize(parent)
    raise "#{self.class} requires a parent" unless parent
    @parent = parent
  end

  def parent
    @parent
  end

  def current_scope
    if parent
      parent.current_scope
    else
      @current_scope ||= self
    end
  end

  def current_scope= new_scope
    #puts "Scope: #{new_scope}"
    if parent
      parent.current_scope = new_scope
    else
      @current_scope = new_scope
    end
  end

  def handle token
    case token
    when " "
    else
      raise "Unknown token for #{self.class}: #{token}"
    end
  end

  def parent_depth
    return (1 + parent.parent_depth) if parent
    0
  end

  def print_name(spacing)
    cls_name = self.class.to_s.split("Parsed")[1]
    spacing = spacing - cls_name.length
    spacing = spacing - name.to_s.length
    spacing = spacing - 2
    spacing = " " * spacing
    "#{spacing}#{name}:#{cls_name}"
  end

  def new_scope(cls, add_to=nil)
    cls.new(self).tap do |new_scope|
      debug_print "new scope #{new_scope}"
      add_to << new_scope if add_to
      self.current_scope = new_scope
    end
  end

  def close_scope
    self.current_scope = parent
  end

  def done_once
    @done_once ||= []
  end

  def handle(token)
    debug_print "handling :#{token_type(token)} #{token.gsub("\n", "")}"
    handler ||= token_handler(token)
    handler.each_with_index do |hash, index|
      next if hash[:once] && done_once.include?(index)
      done_once << index if hash[:optional]

      next unless current_scope.send(hash[:if]) if hash[:if]
      next if current_scope.send(hash[:unless]) if hash[:unless]

      was_handled = handle_instruction(token, hash)
      if was_handled == true
        done_once << index
        return
      else
        unless hash.keys.include? :optional
          raise "Token expected :#{was_handled}, got :#{token_type(token)} #{token.gsub("\n", "")}"
        end
      end
    end
  end

  def comment_handler(token)
    [
      {
        hash: -> { new_scope(ParsedComment) },
        optional: true
      }
    ]
  end

  def token_handler(token)
    comment_handler(token) + [
      {
        space: ->{},
        optional: true
      }
    ]
  end

  def handle_instruction(token, hash)
    if hash.keys.include? :all
      if hash[:except] == token_type(token)
        return "anything_but_#{token_type(token)}"
      end
      hash[:all].call
      return true
    end

    last_expected = nil

    hash.each do |k, v|
      next if [:once, :optional, :if, :unless].include? k
      if token_type(token) == k
        v.call
        return true
      else
        last_expected = k
      end
    end
    return last_expected
  end

  def debug_print(message)
    return if message == " "
    spacing = "--" * current_scope.parent_depth

    position = `tput cols`.to_i / 3
    return if message.include? "handling :space"
    puts "#{current_scope.print_name(position)} --#{spacing}#{message}"
  end

  def named_tokens
    {
      ' '  => :space,
      "\n" => :break,
      ';'  => :break,
      '('  => :open_paren,
      ')'  => :close_paren,
      '{'  => :open_curley,
      '}'  => :close_curley,
      '|'  => :pipe,
      ','  => :delimiter,
      '#'  => :hash,
      '.'  => :dot,
      '='  => :equal,
      '+'  => :plus,
      '/'  => :forward_slash,
      '-'  => :dash,
      '%'  => :percent,
      '<'  => :left_chevron,
      '>'  => :right_chevron
    }
  end

  def token_type(token)
    if named_tokens.keys.include? token
      return named_tokens[token]
    else
      return token.to_sym if KEYWORDS.include? token
      :word
    end
  end

  def self.children *args
    args.each do |child|
      self.class_eval do
        define_method(child) do
          value = instance_variable_get("@#{child}")
          unless value
            value = []
            instance_variable_set("@#{child}", value)
          end
          value
        end
      end
    end
  end

  def states
    @states ||= []
  end

end
