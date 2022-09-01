import std/options

type
    Lexer* = object
        ## Convenience type to encapsulate the lexer functionality
        stream: string
        column: int
        line: int

    TokenTag = enum
        TkNumber, TkString, TkVar, TkFn
        
    Token* = object
        column: int
        line: int
        case tag*: TokenTag
        of TkNumber:
            num*: int
        of TkString:
            str*: string
        of TkVar:
            name*: string
        of TkFn:
            fnName*: char

proc new*(source: string): Lexer =
    ## Given a source string, initiates a Lexer
    result = Lexer(stream: source, column: 0, line: 1)

proc peek(lexer: Lexer): Option[char] =
    ## Peeks at the top of the stream, returning its first character if possible.
    
    if len(lexer.stream) != 0:
        return some(lexer.stream[0])
    
    return none(char)

proc bump(lexer: var Lexer) =
    ## Bumps the top of the stream without reading from it
    lexer.stream = lexer.stream[1 .. ^1]
    lexer.column += 1

proc munchComment(lexer: var Lexer) =
    while lexer.peek().isSome():
        let ch = lexer.peek().get()
        if ch != '\n':
            lexer.bump()
        # We're breaking before the newline, but this isn't a problem
        # because the main lexer function can deal with it while also
        # updating the lexer's position.
        else:
            return

proc lexInteger(lexer: var Lexer): Token =
    var number = 0
    
    while lexer.peek().isSome():
        let ch = lexer.peek().get()
        
        let digit = int(ch) - int('0')
        if digit < 0 or digit > 9:
            break

        number = number * 10 + digit
        lexer.bump()

    return Token(tag: TkNumber, num: number,
                 column: lexer.column, line: lexer.line)

proc lexString(lexer: var Lexer, opening: char): Token =
    var contents = ""
    while lexer.peek().isSome():
        let ch = lexer.peek().get()
        if ch != opening:
            contents.add(ch)
            lexer.bump()
        else:
            lexer.bump()
            break

    return Token(tag: TkString, str: contents,
                 column: lexer.column, line: lexer.line)

proc lexVariable(lexer: var Lexer): Token =
    var name = ""
    while lexer.peek().isSome():
        let ch = lexer.peek().get()
        if ch in 'a'..'z' or ch == '_':
            name.add(ch)
            lexer.bump()
        else:
            break

    return Token(tag: TkVar, name: name, column: lexer.column, line: lexer.line)

proc lexWordFn(lexer: var Lexer, name: char): Token =
    while lexer.peek().isSome():
        let ch = lexer.peek().get()
        if ch in 'A'..'Z' or ch == '_':
            lexer.bump()
        else:
            break

    return Token(tag: TkFn, fnName: name, column: lexer.column, line: lexer.line)

proc lex*(lexer: var Lexer): seq[Token] =
    ## Main workhorse function for actually lexing the code.
    
    while lexer.peek().isSome():
        let ch = lexer.peek().get()

        case ch

        # Spec mandated whitespace
        of '\t', '\r', ' ', '(', ')',
           '[', ']', '{', '}':
           lexer.bump()

        # Comment symbol
        of '#':
            lexer.munchComment()

        # We're dealing with a newline separatedly because
        # we need to update the lexer about the line position.
        of '\n':
            lexer.bump()
            
            lexer.column = 0
            lexer.line += 1

        # Integers
        of '0'..'9':
            let token = lexer.lexInteger()
            result.add(token)

        # Strings
        of '\'', '"':
            lexer.bump()
            let token = lexer.lexString(ch)
            result.add(token)

        # Variables
        of 'a'..'z', '_':
            let token = lexer.lexVariable()
            result.add(token)

        # Word Functions
        of 'A'..'Z':
            lexer.bump()
            let token = lexer.lexWordFn(ch)
            result.add(token)
        
        # Let's treat everything else as a symbol function
        else:
            lexer.bump()
            let token = Token(tag: TkFn, fnName: ch,
                              column: lexer.column, line: lexer.line)
            result.add(token)
