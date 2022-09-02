import error

type
    Lexer* = object
        ## Convenience type to encapsulate the lexer functionality
        stream: string
        file: string
        position: int
    
    TokenTag* = enum TkString

    Token* = object
        ## Token type that contains position and value information
        start: int
        final: int

        case tag*: TokenTag
        of TkString:
            str*: string

proc fromString*(source: string): Lexer =
    ## Generates a lexer from a string containing Knight source code
    let lexer = Lexer(stream: source, file: "stdin", position: 0)
    return lexer

proc fromFile*(filename: string): Lexer =
    ## Generates a lexer from a filename.
    ## 
    ## PANIC: Should the process not be able to read the file, it will exit
    ## the process with error code 1
    try:
        let 
            stream = readFile(filename)
            lexer = Lexer(stream: stream, file: filename, position: 0)
        
        return lexer
    except IOError:
        let context = LexerContext(filename: filename, contents: "", position: 0)
        bail(LexerError.KnIOError, context)

proc peek(lexer: Lexer, ch: var char): bool =
    ## Checks the first value of the stream, updates ch to have that character
    ## and returns True.
    ## 
    ## Otherwise, it returns false.
    if lexer.position < lexer.stream.len:
        ch = lexer.stream[lexer.position]
        return true

    return false

proc bump(lexer: var Lexer) =
    ## Updates the lexer position.
    lexer.position += 1

proc lexString(lexer: var Lexer): Token =
    ## Tokenizes a string if possible.
    ## 
    ## PANIC: The function will panic in case of unbound strings
    let openingPosition = lexer.position

    var opening: char
    discard lexer.peek(opening)
    lexer.bump()

    var 
        str: string
        ch: char
        closed = false
    
    while lexer.peek(ch) and not closed:
        if ch != opening:
            str.add(ch)
        else:
            closed = true
        
        lexer.bump()
    
    if not closed:
        let context = LexerContext(
            filename: lexer.file, contents: lexer.stream, position: openingPosition)
        bail(LexerError.KnOpenString, context)
    
    return Token(
        start: openingPosition,
        final: lexer.position - openingPosition,
        tag: TkString,
        str: str)

proc lex*(lexer: var Lexer): seq[Token] =
    ## The main lexing workhorse.
    ## Returns a sequence of tokens.
    ## 
    ## PANIC: The function will panic in case of unbound strings in the
    ## Knight source code.
    var tokens: seq[Token]
    
    var ch: char
    while lexer.peek(ch):
        case ch
        of '\'', '"':
            let token = lexer.lexString()
            tokens.add(token)
        
        # For now, let's just ignore everything else
        else:
            lexer.bump()
    
    return tokens