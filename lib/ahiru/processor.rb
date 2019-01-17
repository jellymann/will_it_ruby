module Ahiru
  class Processor
    attr_reader :issues

    def initialize
      @issues = []
    end

    def process_file(path)
      source = File.read(path)
      process_string(source, path)
    end

    def process_string(source, path='(unknown)')
      sexp = RubyParser.new.parse(source)
      file = SourceFile.new(path, source, sexp, self)
      file.process
    rescue Racc::ParseError => e
      register_issue issue_from_parse_error(e, path)
    end

    def register_issue(issue)
      @issues << issue
    end

    private

    def self.issue_from_parse_error(e, path)
      e.message =~ /\A\([^\)]+\):(\d+) :: (.+)\z/
      Issue.new(path, $1.to_i, $2)
    end
  end
end