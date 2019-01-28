module Ahiru
  module Maybe
    class MethodSet
      attr_reader :possibilities

      def initialize(*possibilities)
        @possibilities = possibilities.uniq
      end

      def make_call(self_type, call)
        return_values = @possibilities.map { |p| p.make_call(call) }
        Maybe::Object.from_possibilities(*return_values)
      end

      def check_args(args)
        errors = @possibilities.map { |p| p.check_args(args) }
        if errors.all?(&:nil?)
          nil
        else
          errors.compact.join(', ') # TODO: this is probably not the best thing to do
        end
      end

      def check_call(call)
        errors = @possibilities.map { |p| p.check_call(call) }
        if errors.all?(&:nil?)
          nil
        else
          errors.compact.join(', ') # TODO: this is probably not the best thing to do
        end
      end
    end
  end
end