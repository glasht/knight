import lexer
import parser
import error
from std/os import commandLineParams
from system import quit

let args = commandLineParams()

var scanner: lexer.Lexer
if args.len == 2:
    let (flag, arg) = (args[0], args[1])

    if flag == "-e":
        scanner = lexer.fromString(arg)
    elif flag == "-f":
        scanner = lexer.fromFile(arg)
    else:
        bail(InterfaceError.ArgsError)

elif args.len == 1:
    if args[0] in ["-v", "--version"]:
        echo "NimKnight 0.0.1 - Knight 2.0"
        quit(0)
    
    # Either they asked for help message or they did an oopsie. 
    # This solves both.
    else:
        bail(InterfaceError.ArgsError)

else:
    bail(InterfaceError.ArgsError)
 
let tree = parser.parse(scanner)
echo tree
