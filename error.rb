module Scheme
    Error = Class.new(StandardError)
end

def error(message="")
    raise Scheme::Error, message
end

