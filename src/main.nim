import lexer

var scanner = lexer.fromFile("examples/hello_world.kn")
let tokens = scanner.lex()

echo tokens
