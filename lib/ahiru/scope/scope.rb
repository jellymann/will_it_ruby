module Ahiru
  class Scope
    attr_reader :processor, :self_type, :last_evaluated_result
    include ProcessorDelegateMethods

    def initialize(processor, expressions, parent=processor.main_scope)
      @processor = processor
      @expressions = expressions
      @parent = parent
      @self_type = nil
      @last_evaluated_result = nil
      @local_variables = {}
    end

    def process
      @expressions.each do |sexp|
        @current_sexp = sexp
        @last_evaluated_result = process_expression(sexp)
        @current_sexp = nil
      end
    end

    def process_expression(sexp)
      name, *args = sexp
      send(:"process_#{name}_expression", *args)
    end

    def register_issue(line, message)
      @parent.register_issue(line, message)
    end

    def local_variable_defined?(name)
      @local_variables.key?(name)
    end

    def local_variable_set(name, value)
      @local_variables[name] = value
    end

    def local_variable_get(name)
      @local_variables[name]
    end

    protected
    attr_accessor :current_sexp

    def process_lit_expression(value)
      # TODO: should we handle Range literals differently?
      object_class.get_constant(value.class.name.to_sym).create_instance(value: value)
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
      @processor.v_true
    end

    def process_false_expression
      @processor.v_false
    end

    def process_nil_expression
      @processor.v_nil
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
      puts "STUB: #{self.class.name}#process_lasgn_expression"
      BrokenDefinition.new
    end

    def process_lvar_expression(name)
      if local_variable_defined?(name)
        local_variable_get(name)
      else
        register_issue @current_sexp.line, "Undefined local variable `#{name}' for #{process_self_expression}"
        BrokenDefinition.new
      end
    end

    def process_self_expression
      @self_type
    end

    def process_safe_call_expression(receiver, name, *args)
      puts "STUB: #{self.class.name}#process_safe_call_expression"
      BrokenDefinition.new
    end

    def process_call_expression(receiver, name, *args)
      if receiver.nil? && local_variable_defined?(name)
        local_variable_get(name)
      else
        call_method_on_receiver(receiver, name, args)
      end
    end

    def process_iter_expression(call, blargs, blexp = s(:nil))
      puts "STUB: #{self.class.name}#process_iter_expression"
      BrokenDefinition.new
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
      @parent.process_const_expression(name)
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
      puts "STUB: #{self.class.name}#process_if_expression"
      BrokenDefinition.new
    end

    def process_case_expression(input, *expressions)
      puts "STUB: #{self.class.name}#process_case_expression"
      BrokenDefinition.new
    end

    def process_return_expression(value = nil)
      puts "STUB: #{self.class.name}#process_return_expression"
      BrokenDefinition.new
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
      puts "STUB: #{self.class.name}#process_yield_expression"
      BrokenDefinition.new
    end

    def process_block_expression(*expressions)
      puts "STUB: #{self.class.name}#process_block_expression"
      BrokenDefinition.new
    end

    private

    def call_method_on_receiver(receiver, name, args)
      call = Call.new(args, self)
      call.process
      receiver_type = receiver.nil? ? process_self_expression : process_expression(receiver)
      method = receiver_type.get_method(name)
      if method
        error = method.check_args(args)

        # TODO: this is ridiculous. need to consolidate check_args and check_call
        if error
          register_issue @current_sexp.line, error
          BrokenDefinition.new
        else
          error = method.check_call(call)
          if error
            register_issue @current_sexp.line, error
            BrokenDefinition.new
          else
            method.make_call(receiver_type, call)
          end
        end
      else
        thing = receiver.nil? ? "local variable or method" : "method"
        register_issue @current_sexp.line, "Undefined #{thing} `#{name}' for #{receiver_type}"
        BrokenDefinition.new
      end
    end
  end
end