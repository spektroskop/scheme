class Object
    def symbol?
        Symbol === self
    end

    def number?
        Numeric === self
    end

    def complex?
        Numeric === self
    end

    def real?
        Float === self or
        Rational === self or
        Integer === self
    end

    def rational?
        Rational === self or
        Integer === self
    end

    def integer?
        Integer === self
    end
end

class TrueClass
    def to_s
        "#t"
    end
end

class FalseClass
    def to_s
        "#f"
    end
end

class Numeric
    def exact?
        case self
        when Integer, Rational then true
        when Float then false
        when Complex then
            real.exact? and imaginary.exact?
        end
    end

    def inexact?
        not exact?
    end

    def exact
        case self
        when Integer, Rational then self
        when Float then rationalize
        when Complex then
            Complex(real.exact, imaginary.exact)
        end
    end

    def inexact
        case self
        when Integer, Rational then to_f
        when Float then self
        when Complex then
            Complex(real.inexact, imaginary.inexact)
        end
    end
end
