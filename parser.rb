require "./error"
require "./scanner"
require "./empty"
require "./cons"
require "./extensions"

class Parser < Scanner
    def run(input, &block)
        setup(input)
        expr = block ? yield(read_expr) : read_expr while more?
        expr
    end

    def read_expr
        skip_space
        expr = case
               when consume("(") then read_list
               when initial? then read_identifier
               when peek(%r<[+-]>, %r<[i\d.]>) then read_number
               when peek(".", %r<[i\d]>) then read_number
               when digit? then read_number
               when sign?, peek("...") then read_peculiar_identifier
               when consume("#") then read_sharp
               when consume("'") then read_quote
               when consume("`") then read_quasiquote
               when consume(",") then read_unquote
               when consume('"') then read_string
               else error("Syntax error")
               end
        skip_space
        expr
    end

    def read_list
        nodes = []
        nodes << read_expr until peek(". ") or peek(")")
        tail = read_expr if consume(". ")
        error("Expected closing paren") unless consume(")")
        List(nodes, tail || Empty)
    end

    def read_identifier
        data = ""
        data += consume while subsequent?
        expect_delimiter
        data.intern
    end

    def read_peculiar_identifier
        data = if sign? then consume
               else consume("...")
               end
        expect_delimiter
        data.intern
    end

    def read_sharp
        case token = consume
        when %r<[doxb]>
            radix = read_radix(token)
            exact = read_exact if consume("#")
            read_number(radix, exact)
        when %r<[ei]>
            exact = read_exact(token)
            radix = read_radix if consume("#")
            read_number(radix || "", exact)
        when %r<[tf]>
            expect_delimiter
            token == "t"
        else
            error("Unexpected token after `#'")
        end
    end

    def read_exact(token = nil)
        case token || token = consume
        when %r<[ei]> then token
        else error("Expected exactness")
        end
    end

    def read_radix(token = nil)
        case token || consume
        when "b" then "0b"
        when "d" then ""
        when "o" then "0"
        when "x" then "0x"
        else error("Expected radix")
        end
    end

    def read_sign
        case consume(%r<[+-]>)
        when "+" then  1
        when "-" then -1
        end
    end

    def read_number(radix = "", exact = nil)
        number = read_complex_number(radix)
        error("Expected number") unless number
        expect_delimiter
        case exact
        when "i" then number.inexact
        when "e" then number.exact
        else number
        end
    end

    def read_complex_number(radix)
        if number = consume(%r<[+-]>, "i")
            return Complex(number)
        end

        return unless number = read_real_number(radix)

        return Complex(number) if consume("i")

        if consume("@")
            return unless imaginary = read_real_number(radix)
            return Complex.polar(number, imaginary)
        end

        if sign = read_sign
            imaginary = read_unsigned_real_number(radix) || 1
            return unless consume("i")
            return Complex(number, sign * imaginary)
        end

        number
    end

    def read_real_number(radix)
        sign = read_sign
        return unless number = read_unsigned_real_number(radix)
        number * (sign || 1)
    end

    def read_decimal_number(radix, default = nil)
        return if radix != ""
        read_unsigned_integer(radix) || default
    end

    def read_unsigned_real_number(radix)
        if consume(".") and decimal = read_decimal_number(radix)
            return Float("0." + decimal)
        end

        return unless number = read_unsigned_integer(radix)

        if consume(".") and decimal = read_decimal_number(radix, "0")
            return Float(number + "." + decimal)
        end

        if consume("/") and denominator = read_unsigned_integer(radix)
            return Rational(Integer(number), Integer(denominator))
        end

        Integer(radix + number)
    end

    def read_unsigned_integer(radix)
        number = ""
        number += consume while digit?(radix: radix)
        number.empty? ? nil : number
    end

    def read_quote
        List([:quote, read_expr])
    end

    def read_unquote
        List([consume("@") ? :"unquote-splicing" : :"unquote", read_expr])
    end

    def read_quasiquote
        List([:quasiquote, read_expr])
    end

    def read_escape_sequence
        case consume
        when "n" then "\n"
        when "\\" then "\\"
        when '"' then '"'
        when "t" then "\t"
        else error("Invalid escape sequence")
        end
    end

    def read_string
        string = ""
        string += consume("\\") ? read_escape_sequence : consume until peek('"')
        error("Unterminated string") unless consume('"')
        expect_delimiter
        string
    end

    def expect_delimiter
        delimiter? or error("Expected delimiter")
    end

    def skip_space
        consume while space?
    end

    def delimiter?
        not more? or space? or peek(%r<[()]>)
    end

    def space?(char = peek)
        char =~ %r<\s>
    end

    def sign?(char = peek)
        char =~ %r<[+-]>
    end

    def digit?(char = peek, radix: "")
        case radix
        when "0b" then char =~ %r<[0-1]>
        when "" then char =~ %r<\d>
        when "0" then char =~ %r<[0-7]>
        when "0x" then char =~ %r<\h>
        end
    end

    def initial?(char = peek)
        char =~ %r<[a-z!$%&*/:<=>?^_~]>i
    end

    def subsequent?(char = peek)
        initial? or digit? or sign? or char =~ %r<[.\@]>
    end
end
