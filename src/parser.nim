from lexer import Lexer, Token, TokenTag, lex
import error
import std/strformat
import std/strutils

type
    TreeTag* = enum
        TreeBool, TreeNull, TreeInt, TreeList,
        TreeStr, TreeVar, TreeFn, TreeEof
    
    Tree* = ref object
        tag: TreeTag
        str: string
        number: int
        boolean: bool
        list: seq[Tree]
    
    FileContext* = object
        filename: string
        contents: string

proc `$`*(tree: Tree): string =
    case tree.tag
    of TreeBool:
        return fmt"Bool({tree.boolean})"
    of TreeNull:
        return "Null"
    of TreeInt:
        return fmt"Int({tree.number})"
    of TreeList:
        let elems = tree.list.join(", ")
        return fmt"List({elems})"
    of TreeStr:
        return fmt"String({tree.str})"
    of TreeVar:
        return fmt"Var({tree.str})"
    of TreeFn:
        let args = tree.list.join(", ")
        return fmt"Fn({tree.str} -> {args})"
    of TreeEof:
        return "EOF"

proc parseRec(tokens: openArray[Token], context: FileContext): (Tree, seq[Token]) =
    ## Recursive function that does the actual job of parsing the tree
    new(result[0])

    if tokens.len == 0:
        result[0].tag = TreeEof
        return

    let head = tokens[0]
    
    result[1] = tokens[1 .. ^1]

    case head.tag
    of TkInt:
        result[0].tag = TreeInt
        result[0].number = head.num
        return

    of TkString:
        result[0].tag = TreeStr
        result[0].str = head.str
        return

    of TkVar:
        result[0].tag = TreeVar
        result[0].str = head.ident
        return

    of TkFn:
        let ident = head.ident
        result[0].tag = TreeFn
        result[0].str = ident

        var arity: int
        case ident[0]
        of 'T', 'F':
            result[0].tag = TreeBool
            result[0].boolean = ident[0] == 'T'
            return

        of 'N':
            result[0].tag = TreeNull
            return

        of '@':
            result[0].tag = TreeList
            result[0].list = @[]
            return

        # Other nullary functions
        of 'P', 'R':
            arity = 0

        # Unary functions
        of ':', 'B', 'C', 'Q', 'O', 'D',
           'L', '!', '~', 'A', ',', '[', ']':
            arity = 1

        # Ternary functions
        of 'I', 'G':
            arity = 3
        
        of 'S':
            arity = 4
        
        # We'll assume by default that anything else is binary
        else:
            arity = 2
        
        # If we're still here, we're parsing a function with a certain arity
        var
            reachedEnd = false
            index = 0
        while not reachedEnd and index < arity:
            let (tree, rest) = parseRec(result[1], context)
            
            if tree.tag == TreeEof:
                reachedEnd = true

                let 
                    positionContext = LexerContext(
                        filename: context.filename,
                        contents: context.contents,
                        position: head.final - 1)
                    
                    parserContext = ParserContext(
                        positionContext: positionContext,
                        expectedArity: arity,
                        receivedArity: index)
                
                bail(ParseError.ArityError, parserContext)
            else:
                result[0].list.add(tree)
                result[1] = rest
            
            index += 1
        
        return

proc parse*(scanner: var Lexer): Tree =
    let context = FileContext(filename: scanner.file, contents: scanner.stream)
    let (tree, _) = parseRec(scanner.lex(), context)

    return tree