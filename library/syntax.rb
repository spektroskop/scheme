def sequence(seq)
    return seq if seq.null?
    return seq.car if seq.cdr.null?
    return Cons.new(:begin, seq) if seq.car.pair?
    seq
end

def args(nodes)
    nodes.array.tap do |nodes|
        return nodes.map(&:car), nodes.map(&:cadr)
    end
end

syntax("load") do |scope, nodes|
    scope.load(nodes.car)
end

syntax("define") do |scope, nodes|
    if nodes.car.symbol?
        expr = Scheme.evaluate(scope, nodes.cadr)
        scope.define(nodes.car, expr)
    else
        Frame.new(scope,
            List([:define, nodes.caar,
                 [:lambda, nodes.cdar,
                 sequence(nodes.cdr)]]))
    end
end

syntax("lambda") do |scope, nodes|
    Procedure.new(scope, nodes.car, sequence(nodes.cdr))
end

syntax("begin") do |scope, nodes|
    Body.new(scope, nodes)
end

syntax("quote") do |scope, nodes|
    nodes.car
end

syntax("if") do |scope, nodes|
    expr =
        if Scheme.evaluate(scope, nodes.car)
            nodes.cadr
        elsif nodes.cddr.null?
            Empty
        else
            nodes.caddr
        end
    Frame.new(scope, expr)
end

syntax("and") do |scope, nodes|
    expr = nodes.reverse.reduce(true) do |expr, node|
        List([:if, node, expr, false])
    end
    Frame.new(scope, expr)
end

syntax("or") do |scope, nodes|
    expr = nodes.reverse.reduce(false) do |expr, node|
        List([:if, node, true, expr])
    end
    Frame.new(scope, expr)
end

syntax("let") do |scope, nodes|
    expr =
        if Symbol === nodes.car
            names, values = args(nodes.cadr)
            List([:letrec, [[nodes.car,
                 [:lambda, names, sequence(nodes.caddr)]]],
                 [nodes.car, *values]])
        else
            names, values = args(nodes.car)
            List([[:lambda, names,
                 sequence(nodes.cdr)],
                 *values])
        end
    Frame.new(scope, expr)
end

syntax("letrec") do |scope, nodes|
    expr = List(nodes.car.reduce([:let, Empty]) { |expr, node|
               expr.push([:define, node.car, node.cadr])
           }.push(nodes.cadr))
    Frame.new(scope, expr)
end
