# Bootstrap macOS

Script de bootstrap para configurar um MacBook do zero, escrito em Ruby com testes em Minitest.

## Requisitos

- Ruby 2.6.10 (nativo do macOS)
- Minitest (stdlib)

## Estrutura do Projeto

```
bootstrap/
├── bin/
│   └── bootstrap              # Executável principal
├── lib/
│   └── bootstrap/
│       ├── shell.rb           # Wrapper para comandos shell
│       ├── step.rb            # Classe base para steps
│       ├── runner.rb          # Orquestra execução dos steps
│       └── steps/
│           ├── xcode.rb       # Xcode CLI Tools
│           ├── homebrew.rb    # Homebrew
│           ├── display.rb     # Resolução do display
│           ├── modifier_keys.rb # Troca Caps Lock <-> Control
│           ├── dock.rb        # Configuração do Dock
│           └── claude_code.rb # Claude Code
├── test/
│   ├── test_helper.rb
│   ├── shell_test.rb
│   ├── step_test.rb
│   ├── runner_test.rb
│   └── steps/
│       └── *_test.rb          # Testes para cada step
└── Rakefile
```

## Comandos

```bash
# Rodar bootstrap
./bin/bootstrap

# Rodar testes
rake test
```

## Arquitetura

### Shell (`lib/bootstrap/shell.rb`)

Wrapper para executar comandos no sistema:

- `Shell.run(command)` - Executa e captura output (não-interativo)
- `Shell.run_interactive(command)` - Executa com TTY (para comandos que pedem input)
- `Shell.success?(command)` - Retorna true/false
- `Shell.file_exists?(path)` - Verifica se arquivo existe
- `Shell.directory_exists?(path)` - Verifica se diretório existe

### Step (`lib/bootstrap/step.rb`)

Classe base abstrata. Todo step deve implementar:

- `name` - Nome do step para exibição
- `installed?` - Retorna true se já está configurado (idempotência)
- `install!` - Executa a instalação/configuração

O método `run!` da classe base chama `install!` apenas se `!installed?`.

### Runner (`lib/bootstrap/runner.rb`)

Executa steps em ordem, exibe progresso com cores no terminal.

## Princípios

1. **Idempotência** - Cada step verifica se já está configurado antes de executar
2. **Testabilidade** - Shell é injetado via construtor para facilitar mocks
3. **Simplicidade** - Sem gems externas, apenas stdlib do Ruby 2.6

## Steps Existentes

| Step | Descrição |
|------|-----------|
| Xcode | Instala Xcode Command Line Tools |
| Homebrew | Instala e configura Homebrew |
| Display | Configura resolução para 2304x1440 |
| ModifierKeys | Troca Caps Lock <-> Control (esquerdo) |
| Dock | Remove ícones e diminui tamanho |
| Finder | Configura visualização em List |
| ClaudeCode | Instala Claude Code via Homebrew |
