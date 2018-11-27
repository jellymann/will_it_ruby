module Gemologist
  class Definition
    def self.add_class_definition(base_class, *generics, &block)
      @classes ||= {}
      c = @classes[base_class] ||= ClassDefinition.new(base_class, *generics)
      c.instance_eval(&block) if block_given?
      c
    end

    def self.for_class(base_class)
      @classes[base_class]
    end

    def self.for_type(type)
      case type
      when DuckType
        type.definition
      else
        @classes[type.native_type]
      end
    end

    class ClassDefinition
      attr_reader :base_class, :generics, :instance_methods, :class_methods, :constants

      def initialize(base_class, *generics)
        @base_class = base_class
        @generics = generics
        @instance_methods = {}
        @class_methods = {}
        @constants = {}
      end

      def add_method_definition(name, sig = { [] => Nil }, block_sig = nil)
        m = (@instance_methods[name] ||= [])
        m << method_from_sig(name, sig, block_sig)
      end

      def add_class_method_definition(name, sig = { [] => Nil }, block_sig = nil)
        m = (@class_methods[name] ||= [])
        m << method_from_sig(name, sig, block_sig)
      end

      def add_constant_definition(name, type)
        @constants[name] ||= type
      end

      def resolve_method_call(name, args = [], kwargs = {})
        find_matching_method_call(name, args, kwargs)&.return_type
      end

      def find_matching_method_call(name, args = [], kwargs = {})
        find_methods_by_name(name)&.each do |method|
          next if method.requires_block?
          return method if method.match_call?(args, kwargs)
        end
        nil
      end

      def find_matching_method_call_with_block(name, args = [], kwargs = {})
        find_methods_by_name(name)&.each do |method|
          next if !method.requires_block?
          return method if method.match_call?(args, kwargs)
        end
        nil
      end

      def find_methods_by_name(name)
        methods = @instance_methods[name]
        return methods unless methods.nil?
        superclass = base_class&.superclass
        return nil if superclass.nil?
        Definition.for_class(superclass).find_methods_by_name(name)
      end

      def has_matching_method?(method)
        methods = find_methods_by_name(method.name)
        return false if methods.nil?
        methods.any? do |m|
          m.match_method?(method)
        end
      end

      private

      def method_from_sig(name, sig, block_sig = nil)
        args, kwargs, return_type = args_from_sig(sig)
        block_args, _, block_return_type = args_from_sig(block_sig)
        Method.new(self, name, return_type, args, kwargs, block_args, block_return_type)
      end

      def args_from_sig(sig)
        return [nil, nil, nil] if sig.nil?

        case sig
        when Hash
          args, return_type = sig.first
          pargs, kwargs = kwargs_from_args(args)
          [pargs, kwargs, return_type]
        when Array
          pargs, kwargs = kwargs_from_args(sig)
          [pargs, kwargs, Nil]
        else
          [[], {}, sig]
        end
      end

      def kwargs_from_args(args)
        case args
        when Array
          pargs = args
          kwargs = {}
          if args.last.is_a?(Hash)
            *pargs, kwargs = args
          end
          [pargs, kwargs]
        when Hash
          [[], args]
        else
          [[args], {}]
        end
      end
    end

    class Method
      attr_reader :class_definition, :name, :return_type, :argument_list, :kwarg_types, :block_type

      def initialize(class_definition, name, return_type, argument_types = [], kwarg_types = {}, block_argument_types = nil, block_return_type = nil)
        @class_definition = class_definition
        @name = name
        @return_type = return_type
        @argument_list = ArgumentList.new(argument_types)
        @kwarg_types = kwarg_types
        if !block_argument_types.nil?
          @block_type = Block.new(block_return_type, block_argument_types)
        end
      end

      def match_call?(at, kt = {}, brt = nil)
        return false unless argument_list.match?(at)
        return false unless kwarg_match?(kt)
        true
      end

      def match_method?(other)
        return false unless match_call?(other.argument_list.types, kwarg_types)
        return false unless other.requires_block? == requires_block?
        return false unless return_type.match?(other.return_type)
        if requires_block?
          return false unless block_type.match?(other.block_type.return_type)
          return false unless block_type.argument_list.zip(other.block_type.argument_list).all? { |a,b| a.match?(b) }
        end
        true
      end

      def requires_block?
        !block_type.nil?
      end

      def kwarg_match?(kt)
        return true if kwarg_types.empty? && kt.empty?
        return false unless kwarg_types.reject { |_,v| v.optional? }.all? { |k,_| kt.key?(k) }
        kt.all? { |k,v| kwarg_types[k].match?(v) }
      end
    end

    class Block
      attr_reader :return_type, :argument_list
      def initialize(return_type, argument_types = [])
        @return_type = return_type
        @argument_list = ArgumentList.new(argument_types)
      end

      def match?(rt)
        return_type.match?(rt)
      end
    end

    class ArgumentList
      attr_reader :types

      def initialize(types)
        @types = types
      end

      def match_count?(args)
        args.count >= minimum_count_required && args.count <= maximum_count_allowed
      end

      def match?(args)
        return false unless match_count?(args)
        return true if args.empty? && minimum_count_required.zero?

        rest = self.consume(args.first)
        return false if rest.nil?

        rest.match?(args.drop(1))
      end

      def minimum_count_required
        @types.reject(&:optional?).reject(&:variadic?).count
      end

      def maximum_count_allowed
        @types.any?(&:variadic?) ? Float::INFINITY : @types.count
      end

      def consume(arg)
        type = types.first

        return nil unless type.match?(arg)

        if type.variadic?
          return self
        else
          return ArgumentList.new(types.drop(1))
        end
      end
    end

    class DuckDefinition < ClassDefinition
      def initialize
        super(nil)
        @type = MutableDuckType.new(self)
      end

      def resolve_method_call(name, args = [], kwargs = {})
        m = super
        return m.return_type unless m.nil?
        m = Method.new(self, name, Any, args, kwargs)
        (@instance_methods[name] ||= []) << m
        m.return_type
      end

      def to_type
        @type
      end
    end
  end

  class MutableDuckType < DuckType
    def initialize(definition = Definition::DuckDefinition.new)
      @definition = definition
    end

    def to_regular_duck_type
      DuckType.new(definition.instance_methods.values.flatten)
    end
  end
end