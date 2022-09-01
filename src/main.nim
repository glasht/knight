import lexer

let code = "; = hello \"Hello\" ; = world \"World\" OUTPUT + hello world"

var scanner = lexer.new("; = hello \"Hello\" ; = world \"World\" OUTPUT + hello world")
let tokens = scanner.lex()

echo code
for token in tokens:
    echo token
