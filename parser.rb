require "./error"
require "./cons"

class Parser
    attr_reader :index, :input

    def reset(input=nil)
        @input = input if input
        @index = 0
        self
    end

    def parse(input)
        reset(input)
        nodes = []
        nodes << read_expr while more?
        nodes
    end

    def read_expr
        skip_space
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
            when consume("'") then read_quote
            when consume("`") then read_quasiquote
            when consume(",") then read_unquote
            when consume('"') then read_string
            else error("syntax error")
        end.tap do
            skip_space
        end
    end

  # ---------------------------- #

    def read_list
        nodes = []
        until read(")")
            break if consume(:dot, :space) and last = read_expr
            nodes << read_expr
        end
        error("expected closing paren") unless consume(")")
        List(nodes, last || Empty)
    end

    def read_symbol
        start = index
        skip while initial? or dec? or sign? or subsequent?
        expect_delimiter
        get(start).to_sym
    end

    def read_hash
        case token = consume
            when /[tf]/ then expect_delimiter && token == "t"
            else error("unexpected token after hash")
        end
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

    def read_quote
        List([:quote, read_expr])
    end

    def read_quasiquote
        List([:quasiquote, read_expr])
    end

    def read_unquote
        List([consume("@") ? :"unquote-splicing" : :"unquote", read_expr])
    end

    def read_string
        esc = Hash["n" => "\n", "\\" => "\\", '"' => '"', "t" => "\t"]
        string = ""
        i = @index
        until read('"') or not more?
            if consume("\\")
                string << get(i, -1) << (esc[consume] || error("invalid escape sequence"))
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

  # ---------------------------- #

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
        if chars.empty?
            skip
            peek(-1)
        elsif text = read(*chars)
            skip(chars.size)
            text
        end
    end

    def get(pre, post=0)
        @input[pre...@index+post]
    end

    def peek(n=0)
        @input[@index+n]
    end

    def skip(n=1)
        @index += n
    end

    def skip_space
        skip while space?
    end

    def more?
        @index < @input.size
    end

    def expect_delimiter
        delimiter? || error("expected delimiter")
    end

  # ---------------------------- #

    def test(group, char)
        group.include?(char) rescue false
    end

    def paren?(char=peek)
        test("()", char)
    end

    def sign?(char=peek)
        test("+-", char)
    end

    def dec?(char=peek)
        test("0123456789", char)
    end

    def dot?(char=peek)
        char == "."
    end

    def space?(char=peek)
        test("\n\s\t\r", char)
    end

    def initial?(char=peek)
        test("!$%&*/:<=>?^_~abcdefghijklmnopqrstuvwxyz", char)
    end

    def subsequent?(char=peek)
        test(".\\@", char)
    end

    def delimiter?(char=peek)
        not more? or space?(char) or paren?(char)
    end
end
