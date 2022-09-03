import lexer

var scanner = lexer.fromFile("examples/hello_world.kn")
let tokens = scanner.lex()

for token in tokens:
    echo token
