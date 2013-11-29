require "./procedure"
require "./error"

class Scope
    class Loader
        def initialize(scope)
            @scope = scope
        end

        def primitive(name, &block)
            @scope.define(name, Primitive.new(&block))
        end

        def syntax(name, &block)
            @scope.define(name, Syntax.new(&block))
        end

        def load(path)
            @scope.load(path)
        end
    end

    attr_reader :parent, :symbols

    def initialize(parent = nil)
        @parent, @symbols = parent, Hash.new
    end

    def keys
        @symbols.keys
    end

    def lookup(name)
        if @symbols.key?(name)
            @symbols[name]
        else
            error("undefined -> `#{name}'") unless @parent
            @parent.lookup(name)
        end
    end

    def define(name, object)
        [*name].zip([*object]) do |name, object|
            object.name = name if object.respond_to?(:name=)
            @symbols[name.to_sym] = object
        end
        @symbols.values[-1]
    end

    def load(path)
        error("`#{path}' not found") unless File.file?(path)
        loader = Loader.new(self)
        return loader.instance_eval(File.read(path)) if File.extname(path) == ".rb"
        Scheme.run(self, File.read(path))
    end
end
