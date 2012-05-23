class NSObject
  def add_block_method(sym, &block)
    block_methods[sym] = block
    nil
  end

  def method_missing(sym, *args, &block)
    if block_methods.keys.member? sym
      return block_methods[sym].call(*args, &block)
    end
    raise NoMethodError.new("undefined method `#{sym}' for " + "#{self.inspect}:#{self.class.name}")
  end

  def methods
    methods = super
    methods + block_methods.keys
  end

  private
  def block_methods
    @block_methods ||= {}
  end
end