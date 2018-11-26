module Gemologist
  class Scope
    def initialize(self_type = T(Kernel), parent_scope = nil)
      @self_type = self_type
      @parent_scope = parent_scope
      @local_variables = {}
    end

    def local_variable(name)
      @local_variables[name] || @parent_scope&.local_variable(name)
    end

    def local_variable_defined?(name)
      @local_variables.has_key?(name) || @parent_scope&.has_key?(name) || false
    end

    def analyze_expression(sexp)
      case sexp[0]
      when :lasgn
        @local_variables[sexp[1]] = determine_type(sexp[2])
      when :block
        _, *expressions = sexp
        expressions.map { |x| analyze_expression(x) }.last
      else determine_type(sexp)
      end
    end

    def determine_types(sexps)
      sexps.map { |x| determine_type(x) }.reduce { |a, b| a | b }
    end

    def determine_type(sexp)
      case sexp[0]
      when :lit then T(sexp[1].class)
      when :str, :dstr then T(String)
      when :if
        if_type = s[2].nil? ? T(NilClass) : determine_type(s[2])
        else_type = s[3].nil? ? T(NilClass) : determine_type(s[3])
        if_type | else_type
      when :case
        when_types = determine_types(s[2..-2].map { |w| w[2] })
        else_type = s[-1].nil? ? T(NilClass) : determine_type(s[-1])
        when_types | else_type
      when :array
        return T(Array, Any) if s.length == 1
        array_type = determine_types(s[1..-1])
        T(Array, array_type)
      when :hash
        return T(Hash, Any, Any) if sexp.length == 1
        _, *entries = sexp
        keys, values = [:even?, :odd?].map { |x| entries.values_at(*entries.each_index.select(&x)) }
        key_types = determine_types(keys)
        value_types = determine_types(values)
        T(Hash, key_types, value_types)
      when :call
        receiver, name, args, kwargs = get_call_parameters(sexp)

        return local_variable(name) if receiver.nil?

        Definition.for_type(receiver).resolve_method_call(name, args, kwargs)
      when :iter
        receiver, name, args, kwargs = get_call_parameters(sexp[1])

        _, *block_args = sexp[2]

        method = Definition.for_type(receiver).find_matching_method_call_with_block(name, args, kwargs)

        method.return_type
      end
    end

    def get_call_parameters(sexp)
      _, receiver, name, *args = sexp

      case receiver
      when Sexp
        receiver = determine_type(receiver)
      when nil
        if args.empty? && local_variable_defined?(name)
          return [nil, name, nil, nil]
        else
          receiver = T(Kernel)
        end
      else
        receiver = T(receiver)
      end

      pargs = args.map { |a| analyze_expression(a) }
      kwargs = {}

      if !pargs.empty? && T(Hash, Symbol, Any).match?(pargs.last)
        pargs = pargs.first(pargs.length - 1)
        kwargs = kwargs_from_hash_literal(args.last)
      end

      [receiver, name, pargs, kwargs]
    end

    def kwargs_from_hash_literal(sexp)
      _, *values = *sexp

      Hash[*values].transform_keys { |k| k[1] }.transform_values { |v| determine_type(v) }
    end
  end
end