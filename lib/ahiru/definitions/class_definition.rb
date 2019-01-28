module Ahiru
  class ClassDefinition
    attr_reader :name, :singleton_class_definition, :super_type, :processor
    include ProcessorDelegateMethods

    def initialize(name, super_type, parent_scope, processor=parent_scope&.processor)
      @name = name
      @scopes = []
      @parent_scope = parent_scope
      @super_type = super_type
      @instance_methods = {}
      @class_methods = {
        new: NewMethodDefinition.new(self)
      }
      @constants = {}
      @processor = processor
    end

    def is_or_sublass_of?(other_def)
      return true if other_def == self
      return false if @parent_scope.nil?
      @parent_scope.is_or_sublass_of?(other_def)
    end

    def add_instance_method(name, definition)
      @instance_methods[name] = definition
    end

    def def_instance_method(name, args, **options, &block)
      add_instance_method(name, BuiltInMethodDefinition.new(name, args, **options, &block))
    end
    
    def monkey_patch_expressions(expressions)
      scope = ClassScope.new(@parent_scope.processor, expressions, @parent_scope, self)
      @scopes << scope
      scope.process
    end

    def get_method(name)
      @class_methods[name] || @super_type&.get_method(name)
    end

    def get_instance_method(name)
      @instance_methods[name] || @super_type&.get_instance_method(name)
    end

    def create_instance(**options)
      ClassInstance.new(self, **options)
    end

    def to_s
      name
    end

    def inspect
      "#<#{self.class.name} @name=#{name.inspect} @super_type=#{super_type&.name.inspect}>"
    end

    def class_definition
      @parent_scope.processor.object_class.get_constant(:Class)
    end

    def add_constant(name, value)
      @constants[name] = value
    end

    def get_constant(name)
      @constants[name]
    end

    def check_is_a(other)
      class_class = object_class.get_constant(:Class)
      class_class.is_or_sublass_of?(other)
    end

    def maybe_truthy?
      true
    end

    def maybe_falsey?
      false
    end

    def definitely_truthy?
      true
    end

    def definitely_falsey?
      false
    end
  end
end