import lexer

let code = "; = hello \"Hello\"\n; = world 'World'\n; OUTPUT + hello world\n; OUT + hello 2"

var scanner = lexer.new(code)
let tokens = scanner.lex()

echo code
for token in tokens:
    echo token
