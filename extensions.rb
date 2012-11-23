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
