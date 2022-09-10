import std/strformat
import std/strutils
from system import quit

type
    ParseError* = enum ArityError

    InterfaceError* = enum ArgsError
    
    LexerError* = enum
        KnIOError, KnOpenString
    
    LexerContext* = object
        filename*: string
        contents*: string
        position*: int
    
    ParserContext* = object
        positionContext*: LexerContext
        expectedArity*: int
        receivedArity*: int

proc getInfo(context: LexerContext): (int, int, string) =
    ## Given a context, retrives the line number, column number
    ## and content of that line
    let position = context.position

    var
        line = 1
        column = 1
    
    for index, ch in context.contents:
        if index > position:
            break

        if ch == '\n':
            column = 1
            line += 1
        else:
            column += 1
    
    let content = split(context.contents, '\n')[line - 1]
    return (line, column, content)

proc getSnippet(line: string, column: int): string =
    ## Given a line and a column number, does basic formatting and snips
    ## the line if needed.
    
    let 
        header = "   | "
        # We need to switch from 1 indexing to 0 indexing
        # for the math to work out
        column = column - 1
        empathicArrow = "\e[32m^\e[0m"
    
    var snippet = header

    # If the line is already small enough we can just add to it
    if line.len < (80 - snippet.len):
        snippet = snippet & line & '\n'

        let
            # We need to subtract one here to make space for the indicator
            leftSpaces = repeat(" ", column + header.len - 1)
            rightSpaces = repeat(" ", line.len - column)
        
        snippet = snippet & leftSpaces & empathicArrow & rightSpaces & '\n'

    else:
        let
            biggestOffset = int((80 - snippet.len) / 2)
            leftOffset = max(0, column - biggestOffset)
            rightOffset = min(line.len, column + biggestOffset)
        
        snippet = snippet & line[leftOffset .. rightOffset - 1] & '\n'

        let
            offsetColumn = column - leftOffset - 1
            leftSpaces = repeat(" ", offsetColumn + header.len)
            rightSpaces = repeat(" ", line.len - offsetColumn)
        
        snippet = snippet & leftSpaces & empathicArrow & rightSpaces & '\n'
    
    return snippet

proc bail*(_: InterfaceError) =
    # We're using the argument as a way to just select the right function
    echo ( "Usage: knight options\n" &
            "Options:\n" &
            "  -e             Runs the second parameter as a program.\n" &
            "  -f             Interprets the second parameter as a filename,\n"&
            "                 and runs the program contained therein.\n" &
            "  -h, --help     Prints this message\n" &
            "  -v, --version  Prints the version.\n" )
    quit(1)

proc bail*(error: LexerError, context: LexerContext) =
    case error
    of KnIOError:
        echo ( fmt"[E000] File I/O Error: {context.filename}" &
               "Couldn't read the given file." &
               "\nPlease make sure the file exists and you have the " &
               "appropriate permissions." )
        quit(1)

    of KnOpenString:
        let 
            (line, column, content) = getInfo(context)
            snippet = getSnippet(content, column)

        echo ( "[E001] Open String:\n" &
               fmt"{context.filename}:{line}:{column}:" & '\n' &
               snippet & '\n' &
               "There's an open string in the file. Please close it.")
        quit(1)

proc bail*(_: ParseError, context: ParserContext) =
    let
        (line, column, content) = getInfo(context.positionContext)
        snippet = getSnippet(content, column)
    
    echo ( fmt"[E002] Arity Error:" & '\n' &
           fmt"{context.positionContext.filename}:{line}:{column}:" & '\n' & 
           fmt"Expected {context.expectedArity} arguments," &
           fmt"but received {context.receivedArity}." & '\n' &
           snippet)
    quit(1)