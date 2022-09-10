import error

type
    Lexer* = object
        ## Convenience type to encapsulate the lexer functionality
        stream*: string
        file*: string
        position: int
    
    TokenTag* = enum
        TkString, TkInt, TkVar, TkFn

    Token* = object
        ## Token type that contains position and value information
        start*: int
        final*: int

        case tag*: TokenTag
        of TkString:
            str*: string
        of TkInt:
            num*: int
        of TkVar, TkFn:
            ident*: string

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
    ## Tokenizes a string.
    ## 
    ## PANIC: The function will panic in case of unbound strings
    let start = lexer.position

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
            filename: lexer.file, contents: lexer.stream, position: start)
        bail(LexerError.KnOpenString, context)
    
    return Token(start: start, final: lexer.position, tag: TkString, str: str)

proc lexInteger(lexer: var Lexer): Token =
    ## Tokenizes an int.
    let start = lexer.position

    var 
        number = 0
        ch: char
    
    while lexer.peek(ch) and ch in '0'..'9':
        let digit = int(ch) - int('0')
        number = number * 10 + digit
        lexer.bump()
    
    return Token(start: start, final: lexer.position, tag: TkInt, num: number)

proc munchComment(lexer: var Lexer) =
    ## Gets rid of a comment.
    var ch: char
    while lexer.peek(ch) and ch != '\n':
        lexer.bump()

proc lexVariable(lexer: var Lexer): Token =
    ## Lexes a variable name.
    let start = lexer.position

    var
        ident = ""
        ch: char
    
    while lexer.peek(ch) and (ch in 'a'..'z' or ch == '_'):
        ident.add(ch)
        lexer.bump()
    
    return Token(start: start, final: lexer.position, tag: TkVar, ident: ident)

proc lexWordFunction(lexer: var Lexer): Token =
    ## Lexes a word function name, but not an extension function.
    let start = lexer.position

    var
        ident = ""
        ch: char
    
    while lexer.peek(ch) and (ch in 'A'..'Z' or ch == '_'):
        ident.add(ch)
        lexer.bump()
    
    return Token(start: start, final: lexer.position, tag: TkFn, ident: ident)

proc lexSymbolicFunction(lexer: var Lexer): Token =
    let start = lexer.position
    
    var ch: char
    discard lexer.peek(ch)
    lexer.bump()

    let final = lexer.position

    return Token(start: start, final: final, tag: TkFn, ident: $ch)

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
        # Spec mandated whitespace
        of '\t', '\n', '\r', ' ', '(', ')':
            lexer.bump()
        
        # Comments
        of '#':
            lexer.munchComment()
        
        # Strings
        of '\'', '"':
            let token = lexer.lexString()
            tokens.add(token)
        
        # Integers
        of '0'..'9':
            let token = lexer.lexInteger()
            tokens.add(token)
        
        # Variables
        of 'a'..'z', '_':
            let token = lexer.lexVariable()
            tokens.add(token)
        
        # Word Function
        of 'A'..'Z':
            let token = lexer.lexWordFunction()
            tokens.add(token)

        # For now, let's treat everything else as symbolic function
        else:
            let token = lexer.lexSymbolicFunction()
            tokens.add(token)
    
    return tokens