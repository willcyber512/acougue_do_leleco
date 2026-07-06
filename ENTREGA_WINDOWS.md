# Entrega Windows - Açougue do Leleco

## Como funciona

A balança gera a etiqueta.
O leitor USB lê a etiqueta.
O sistema recebe o código, identifica o produto, adiciona na venda, baixa estoque e registra a venda.

## A dona precisa instalar Flutter?

Não.

Flutter só é necessário no computador do desenvolvedor para gerar o executável.

Depois do build, entregue a pasta:

build\windows\x64\runner\Release

A dona abre o arquivo .exe dentro dessa pasta.

## Importante

Não copie só o .exe. Copie a pasta Release inteira.

## Leitor USB recomendado

Leitor USB comum que funcione como teclado:

- USB HID Keyboard
- Lê código EAN-13
- Envia Enter no final da leitura, se possível

## Teste do leitor

1. Conectar o leitor USB no notebook.
2. Abrir Bloco de Notas.
3. Passar o leitor em uma etiqueta.
4. Se aparecerem números, o leitor está funcionando.
5. Abrir o sistema.
6. Ir em Leitor USB > Teste do leitor USB.
7. Clicar no campo e passar a etiqueta.
8. Se aparecer "Leitor funcionando", está pronto.

## Cadastro correto

O código/PLU do produto na balança precisa ser igual ao código do produto no sistema.

Exemplo:

Na balança:
PLU 1234 = Picanha

No sistema:
Código 1234 = Picanha

## Build no Windows

No computador Windows com Flutter instalado:

scripts\build_windows_release.bat

O executável fica em:

build\windows\x64\runner\Release
