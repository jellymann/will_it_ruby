module WillItRuby
  class ClassInstance
    attr_reader :class_definition, :singleton_class_definition, :label, :value
    include ProcessorDelegateMethods
    include InstanceVariables

    def initialize(class_definition, label: nil, value: nil)
      @class_definition = class_definition
      @label = label
      @value = value
    end

    def processor
      @class_definition.processor
    end

    def get_method(name)
      @class_definition.get_instance_method(name)
    end

    def has_method?(name)
      @class_definition.has_instance_method?(name)
    end

    def to_s
      if @value || @label
        "#{@value&.inspect || @label}:#{@class_definition}"
      else
        "#<#{@class_definition}>"
      end
    end

    def to_s_simple
      if @value || @label
        @value&.inspect || @label
      else
        "#<#{@class_definition}>"
      end
    end

    def inspect
      "#<#{self.class.name} @class_definition=#{class_definition.name.inspect} @label=#{label.inspect} @value=#{value.inspect}>"
    end

    def value_known?
      return true if @class_definition == object_class.get_constant(:NilClass)
      !@value.nil?
    end

    def check_is_a(other)
      # TODO: check included modules
      @class_definition.is_or_sublass_of?(other)
    end

    def check_equality(other)
      if other == self
        v_true
      elsif self.value_known? && other.value_known?
        self.value == other.value ? v_true : v_false
      elsif other.is_a?(Maybe::Object)
        e = other.possibilities.map { |p| self.check_equality(p) }
        return v_false if e.all? { |x| x == v_false }
        return v_true if e.all? { |x| x == v_true }
        v_bool
      elsif self.class_definition != other.class_definition
        v_false
      else
        v_bool
      end
    end

    def maybe_truthy?
      definitely_truthy?
    end

    def maybe_falsey?
      definitely_falsey?
    end

    def maybe_nil?
      definitely_nil?
    end

    def definitely_truthy?
      !value_known? || value
    end

    def definitely_falsey?
      value_known? && !value
    end

    def definitely_nil?
      @class_definition == object_class.get_constant(:NilClass)
    end

    def resolve_truthy
      maybe_truthy? ? nil : ImpossibleDefinition.new
    end

    def resolve_falsey
      maybe_falsey? ? nil : ImpossibleDefinition.new
    end

    def for_scope(scope)
      self
    end

    def |(other)
      Maybe::Object.from_possibilities(self, other)
    end

    def without_nils
      definitely_nil? ? ImpossibleDefinition.new : self
    end

    def create_scope(expressions=[], block=nil)
      MethodScope.new(processor, expressions, @class_definition.create_scope, self, block)
    end
  end
end
