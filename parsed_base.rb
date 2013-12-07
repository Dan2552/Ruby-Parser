class ParsedBase

  attr_accessor :name
  attr_reader :parent

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

  def token_handler(token)
    [
      { space: ->{}, optional: true }
    ]
  end

  def handle_instruction(token, hash)
    # unless hash.is_a? Hash
    #   hash = { hash => ->{} }
    # end
    hash.each do |k, v|
      next if [:once, :optional, :if, :unless].include? k
      if token_type(token) == k
        v.call
        return true
      else
        return k
      end
    end
  end

  def debug_print(message)
    return if message == " "
    spacing = "--" * current_scope.parent_depth

    position = `tput cols`.to_i / 3
    puts "#{current_scope.print_name(position)} --#{spacing}#{message}"
  end

  def token_type(token)
    case token
    when "\n", ";"
      :break
    when " "
      :space
    when "("
      :open_paren
    when ")"
      :close_paren
    when "end", "def", "class", "module"
      token.to_sym
    when ","
      :delimiter
    else
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

  # #STATES
  # @@states = []

  # def self.states *args
  #   args.each { |a| @@states << a }
  # end

  # def state
  #   @state ||= 0
  #   @@states[@state]
  # end

  # def next_state
  #   @state += 1
  # end

end
