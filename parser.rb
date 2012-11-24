require "./cons"

class Parser
    def initialize
        @escape = Hash["n"=>"\n", "\\"=>"\\", '"'=>'"', "t"=>"\t"]
    end

    def reset(input)
        @input = input if input
        @index = 0
    end

    def parse(input)
        reset(input)
        nodes = []
        nodes << read_expr(true) while more?
        nodes
    end

    def read_expr(skip = false)
        skip_space if skip
        case
            when consume("(") then read_list
            when read(:initial) then read_symbol
            when read(:dec),
                 read(:sign, :dec),
                 read(:sign, :dot, :dec),
                 read(:dot, :dec)
                read_number
            when read(:sign) then read_symbol
            when consume("#") then read_hash
            when consume('"') then read_string
            else error "syntax error"
        end.tap do
            skip_space if skip
        end
    end

    def read_list
        nodes = []
        until read(")") or not more?
            break if consume(:dot, :space) and last = read_expr(true)
            nodes << read_expr(true)
        end
        error("expected closing paren") unless consume(")")
        List(nodes, last||Empty)
    end

    def read_symbol
        start = @index
        skip while initial? or dec? or sign? or subsequent?
        expect_delimiter
        get(start).to_sym
    end

    def read_hash
        case token = consume
            when /[tf]/ then expect_delimiter && token == "t"
            else error "unexpected token after hash"
        end
    end

    def read_string
        string = ""
        i = @index
        until read('"') or not more?
            if consume("\\")
                string << get(i, -1) << (@escape[consume] ||
                    error("invalid escape sequence"))
                i = @index
            else
                skip
            end
        end
        error("unterminated string") unless consume('"')
        string << get(i, -1)
        expect_delimiter
        string
    end

    def read_sign
        sign = consume("-") ? -1 : 1
        consume("+")
        sign
    end

    def read_number
        num = read_simple_number
        num = read_complex_number(num, consume("@")) if read(/[-+@]/)
        expect_delimiter
        num
    end

    def read_simple_number
        sign = read_sign
        num = read_unsigned_number
        num = read_rational_number(num) if consume("/")
        sign * num
    end

    def read_unsigned_number
        start = @index
        mark = read_digits || read_digits
        error("expected number") if start == @index
        num = get(start)
        num.gsub!(/\.(?!\d)/, ".0")
        return Float(num) if mark
        Integer(num)
    end

    def read_rational_number(num)
        den = read_unsigned_number
        error("expected integer") unless num.integer? and den.integer?
        Rational(num, den)
    end

    def read_complex_number(real, polar)
        imag = read_simple_number
        error("expected `i'") unless polar or consume("i")
        return Complex.polar(real, imag) if polar
        Complex(real, imag)
    end

    def read_digits
        mark = consume(".")
        skip while digit?
        mark
    end

    def digit?
        dec?
    end

    def read(*chars)
        chars.each.with_index do |c, i|
            return unless case c
                when String then c == peek(i)
                when Regexp then c.match(peek(i))
                else send("#{c}?", peek(i))
            end
        end
        get(@index, chars.size)
    end

    def consume(*chars)
        return skip && peek(-1) if chars.empty?
        if text = read(*chars)
            skip(chars.size)
            text
        end
    end

    def get(pre, post = 0)
        @input[pre...@index + post]
    end

    def peek(n = 0)
        @input[@index + n]
    end

    def skip(n = 1)
        @index += n
    end

    def more?
        @index < @input.size
    end

    def skip_space
        loop do
            skip while space? and more?
            if read(";")
                while consume(";")
                    skip while more? and not consume("\n")
                end
            else
                break
            end
        end
    end

    def delimiter?(char = peek)
        space?(char) or paren?(char) or not more?
    end

    def expect_delimiter
        delimiter? || error("expected delimiter")
    end

    def paren?(char = peek)
        ["(", ")"].include?(char)
    end

    def dec?(char = peek)
        ["0", "1", "2", "3", "4",
         "5", "6", "7", "8", "9"
        ].include?(char)
    end

    def space?(char = peek)
        ["\n", "\s", "\t", "\r"].include?(char)
    end

    def sign?(char = peek)
        ["+", "-"].include?(char)
    end

    def dot?(char = peek)
        char == "."
    end

    def initial?(char = peek)
        ["!", "$", "%", "&", "*",
         "/", ":", "<", "=", ">",
         "?", "^", "_", "~", "a",
         "b", "c", "d", "e", "f",
         "g", "h", "i", "j", "k",
         "l", "m", "n", "o", "p",
         "q", "r", "s", "t", "u",
         "v", "w", "x", "y", "z"
        ].include?(char)
    end

    def subsequent?(char = peek)
        [".", "\\", "@"].include?(char)
    end
end
