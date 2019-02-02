module WillItRuby
  class Scope
    attr_reader :processor, :self_type, :last_evaluated_result, :local_variables, :overrides
    include ProcessorDelegateMethods

    def initialize(processor, expressions, parent=processor.main_scope)
      @processor = processor
      @expressions = expressions
      @parent = parent
      @self_type = nil
      @last_evaluated_result = nil
      @local_variables = {}
      @overrides = {}
      @cache = {}
    end

    def process
      @expressions.each do |sexp|
        @current_sexp = sexp
        @last_evaluated_result = process_expression(sexp)
        should_stop = block_given? ? yield : false
        @current_sexp = nil
        break if should_stop
      end
    end

    def process_expression(sexp)
      @cache[sexp.__id__] ||= begin
        name, *args = sexp
        send(:"process_#{name}_expression", *args)
      end
    end

    def register_issue(line, message)
      @parent.register_issue(line, message)
    end

    def local_variable_defined?(name)
      @local_variables.key?(name)
    end

    def local_variable_set(name, value)
      @local_variables[name] = q value
    end

    def local_variable_get(name)
      q @local_variables[name]
    end

    def defined_local_variables
      @local_variables.keys
    end

    def inspect
      "#<#{self.class.name} @self_type=#{@self_type.inspect}>"
    end

    def q(value)
      new_value = (@overrides[value] || @parent&.q(value) || value)
      new_value.for_scope(self)
    end

    def add_override(value, new_value)
      @overrides[value] = new_value
    end

    protected
    attr_accessor :current_sexp

    def process_lit_expression(value)
      # TODO: should we handle Range literals differently?
      q object_class.get_constant(value.class.name.to_sym).create_instance(value: value)
    end

    def process_dot2_expression(begin_exp, end_exp)
      puts "STUB: #{self.class.name}#process_dot2_expression"
      BrokenDefinition.new
    end

    def process_dot3_expression(*args)
      puts "STUB: #{self.class.name}#process_dot3_expression"
      BrokenDefinition.new
    end

    def process_true_expression
      q @processor.v_true
    end

    def process_false_expression
      q @processor.v_false
    end

    def process_nil_expression
      q @processor.v_nil
    end

    def process_str_expression(_)
      puts "STUB: #{self.class.name}#process_str_expression"
      BrokenDefinition.new
    end

    def process_dstr_expression(_, *values)
      puts "STUB: #{self.class.name}#process_dstr_expression"
      BrokenDefinition.new
    end

    def process_evstr_expression(expression)
      puts "STUB: #{self.class.name}#process_evstr_expression"
      BrokenDefinition.new
    end

    def process_dsym_expression(_, *values)
      puts "STUB: #{self.class.name}#process_dsym_expression"
      BrokenDefinition.new
    end

    def process_dregx_expression(_, *values)
      puts "STUB: #{self.class.name}#process_dregx_expression"
      BrokenDefinition.new
    end

    def process_xstr_expression(value)
      puts "STUB: #{self.class.name}#process_xstr_expression"
      BrokenDefinition.new
    end

    def process_dxstr_expression(_, *values)
      puts "STUB: #{self.class.name}#process_dxstr_expression"
      BrokenDefinition.new
    end

    def process_array_expression(*values)
      puts "STUB: #{self.class.name}#process_array_expression"
      BrokenDefinition.new
    end

    def process_hash_expression(*entries)
      puts "STUB: #{self.class.name}#process_hash_expression"
      BrokenDefinition.new
    end

    def process_lasgn_expression(name, value)
      result = q process_expression(value)
      local_variable_set(name, result)
      result
    end

    def process_lvar_expression(name)
      if local_variable_defined?(name)
        q local_variable_get(name)
      else
        register_issue @current_sexp.line, "Undefined local variable `#{name}' for #{process_self_expression}"
        BrokenDefinition.new
      end
    end

    def process_self_expression
      q @self_type
    end

    def process_safe_call_expression(receiver, name, *args)
      puts "STUB: #{self.class.name}#process_safe_call_expression"
      BrokenDefinition.new
    end

    def process_call_expression(receiver, name, *args)
      if receiver.nil? && local_variable_defined?(name)
        q local_variable_get(name)
      else
        q call_method_on_receiver(receiver, name, args)
      end
    end

    def process_iter_expression(call, blargs, blexp = s(:nil))
      _, receiver, name, *args = call
      q call_method_on_receiver(receiver, name, args, blargs, blexp)
    end

    def process_defn_expression(name, args, *expressions)
      puts "STUB: #{self.class.name}#process_defn_expression"
      BrokenDefinition.new
    end

    def process_defs_expression(name, receiver, args, *expressions)
      puts "STUB: #{self.class.name}#process_defs_expression"
      BrokenDefinition.new
    end

    def process_class_expression(name, super_exp, *expressions)
      puts "STUB: #{self.class.name}#process_class_expression"
      BrokenDefinition.new
    end

    def process_sclass_expression(receiver, *expressions)
      puts "STUB: #{self.class.name}#process_sclass_expression"
      BrokenDefinition.new
    end

    def process_module_expression(name, *expressions)
      puts "STUB: #{self.class.name}#process_module_expression"
      BrokenDefinition.new
    end

    def process_cdecl_expression(name, value)
      puts "STUB: #{self.class.name}#process_cdecl_expression"
      BrokenDefinition.new
    end

    def process_const_expression(name)
      # TODO: has to be more complicated than this 
      object_class.get_constant(name)
    end

    def process_colon2_expression(left, right)
      puts "STUB: #{self.class.name}#process_colon2_expression"
      BrokenDefinition.new
    end

    def process_colon3_expression(name)
      puts "STUB: #{self.class.name}#process_colon3_expression"
      BrokenDefinition.new
    end

    def process_for_expression(iterable, variable, block)
      puts "STUB: #{self.class.name}#process_for_expression"
      BrokenDefinition.new
    end

    def process_while_expression(condition, block)
      puts "STUB: #{self.class.name}#process_while_expression"
      BrokenDefinition.new
    end

    def process_until_expression(condition, block)
      puts "STUB: #{self.class.name}#process_until_expression"
      BrokenDefinition.new
    end

    def process_if_expression(condition, true_block, false_block)
      condition_result = process_expression(condition)

      possible_scopes = []

      if condition_result.maybe_truthy?
        truthy_scope = MaybeScope.new(@processor, vectorize_sexp(true_block), self)
        Quantum::Resolver.new(truthy_scope, condition, true).process
        possible_scopes << truthy_scope
      end

      if condition_result.maybe_falsey?
        falsey_scope = MaybeScope.new(@processor, vectorize_sexp(false_block), self)
        Quantum::Resolver.new(falsey_scope, condition, false).process
        possible_scopes << falsey_scope
      end

      possible_scopes.each(&:process)

      all_affected_lvars = possible_scopes.map { |s| s.local_variables.keys }.reduce([]) { |a, b| a | b }
      new_lvars = all_affected_lvars - defined_local_variables
      existing_affected_lvars = all_affected_lvars - new_lvars

      new_lvars.each do |k|
        local_variable_set(k, v_nil)
      end

      existing_affected_lvars.each do |k|
        values = possible_scopes.map { |s| s.local_variable_get(k) || self.local_variable_get(k) }

        local_variable_set(k, Maybe::Object.from_possibilities(*values.map { |v| q v }))
      end

      if possible_scopes.all?(&:did_return?)
        return handle_return Maybe::Object.from_possibilities(*possible_scopes.map(&:return_value).map { |v| q v })
      elsif possible_scopes.any? { |x| x.did_return? || x.did_partially_return? }
        handle_partial_return Maybe::Object.from_possibilities(
          *possible_scopes.select(&:did_return?).map(&:return_value).map { |v| q v },
          *possible_scopes.select(&:did_partially_return?).map(&:partial_return).map { |v| q v }
        )

        non_returning_overrides = possible_scopes.reject(&:did_return?).reduce({}) do |a, b|
          a.merge(b.overrides) do |k, left, right|
            Maybe::Object.from_possibilities(left, right)
          end
        end
        @overrides.merge!(non_returning_overrides)
      end

      Maybe::Object.from_possibilities(*possible_scopes.select(&:did_not_return?).map(&:last_evaluated_result).map { |v| q v })
    end

    def process_or_expression(a, b)
      process_if_expression(a, a, b)
    end

    def process_and_expression(a, b)
      process_if_expression(a, b, a)
    end

    def process_case_expression(input, *when_expressions, else_expression)
      case_to_if = when_expressions.reverse.reduce(else_expression) do |e, w|
                     s(:if, w[1][1..-1].map{ |x| casecmp(x, input) }.reduce { |a, b| s(:or, a, b) },
                       s(:block, *w[2..-1]),
                       e)
                   end
      
      process_expression(case_to_if)
    end

    def process_return_expression(value = nil)
      handle_return(value.nil? ? v_nil : process_expression(value))
    end

    def process_break_expression(value = nil)
      puts "STUB: #{self.class.name}#process_break_expression"
      BrokenDefinition.new
    end

    def process_next_expression(value = nil)
      puts "STUB: #{self.class.name}#process_next_expression"
      BrokenDefinition.new
    end

    def process_yield_expression(*args)
      register_issue @current_sexp.line, "no block given (yield)"
      BrokenDefinition.new
    end

    def process_block_expression(*expressions)
      puts "STUB: #{self.class.name}#process_block_expression"
      BrokenDefinition.new
    end

    private

    def handle_return(processed_value)
      s(:block, @current_sexp).each_of_type(:return) do |sexp|
        register_issue sexp.line, "unexpected return"
      end
      BrokenDefinition.new
    end

    def handle_partial_return(processed_value)
      handle_return(processed_value)
    end

    def call_method_on_receiver(receiver, name, args, blargs=nil, blexp=nil)
      receiver_type = receiver.nil? ? process_self_expression : process_expression(receiver)

      call = Call.new(args, self)
      call.process

      block = if blargs && blexp
                Block.new(blargs, vectorize_sexp(blexp), processor, self)
              end

      method = receiver_type.get_method(name)
      if method
        error = method.check_args(args)

        # TODO: this is ridiculous. need to consolidate check_args and check_call
        if error
          register_issue @current_sexp&.line, error
          BrokenDefinition.new
        else
          error = method.check_call(call)
          if error
            register_issue @current_sexp&.line, error
            BrokenDefinition.new
          else
            method.make_call(receiver_type, call, block)
          end
        end
      else
        thing = receiver.nil? ? "local variable or method" : "method"
        register_issue @current_sexp&.line, "Undefined #{thing} `#{name}' for #{receiver_type.to_s}"
        BrokenDefinition.new
      end
    end

    def vectorize_sexp(sexp)
      return [s(:nil)] if sexp.nil?
      case sexp[0]
      when :block
        _, *expressions = sexp
        expressions
      else
        [sexp]
      end
    end

    def casecmp(a, b)
      s(:call, a, :===, b)
    end
  end
end