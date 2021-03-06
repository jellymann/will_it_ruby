module WillItRuby
  class NewMethodDefinition < MethodDefinition
    def initialize(class_definition)
      super(:new, s(:args), [], nil, nil)
      @class_definition = class_definition
    end

    def make_call(self_type, call, block=nil)
      @class_definition.create_instance.tap do |new_instance|
        initialize_method.make_call(new_instance, call, block)
      end
    end

    def check_args(args)
      initialize_method.check_args(args)
    end

    def check_call(call)
      initialize_method.check_call(call)
    end

    def arg_count
      initialize_method.arg_count
    end
    
    def resolve_for_scope(scope, self_type, truthy, receiver_sexp, call)
    end

    private

    # TODO: do this until Object/BasicObject are defined
    def create_init_method
      MethodDefinition.new(:initialize, s(:args), [], @processor, @parent_scope)
    end

    def initialize_method
      @class_definition.get_instance_method(:initialize) || create_init_method
    end
  end
end