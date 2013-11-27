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
    Frame.new scope,
        if Scheme.evaluate(scope, nodes.car)
            nodes.cadr
        elsif nodes.cddr.null?
            Empty
        else
            nodes.caddr
        end
end

syntax("let") do |scope, nodes|
    Frame.new scope,
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
end

syntax("letrec") do |scope, nodes|
    Frame.new(scope,
        List(nodes.car.reduce([:let, []]) { |expr, node|
                expr.push([:define, node.car, node.cadr])
             }.push(nodes.cadr)))
end
