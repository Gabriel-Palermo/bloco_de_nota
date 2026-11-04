# Bloco de Notas

Aplicativo de anotações desenvolvido em Flutter como projeto acadêmico do curso de Engenharia de Software. Utiliza SQLite para armazenamento local e Firebase Cloud Firestore para sincronização das anotações na nuvem.

## Sobre o projeto

O Bloco de Notas permite que usuários criem e organizem suas anotações, com armazenamento local e integração com serviços Firebase.

Cada anotação é vinculada ao usuário autenticado, permitindo recuperar os dados após sair e entrar novamente na conta.

## Tecnologias utilizadas

- **Flutter:** desenvolvimento da interface.
- **Dart:** linguagem de programação.
- **SQLite:** armazenamento local.
- **Firebase Authentication:** cadastro e autenticação de usuários.
- **Cloud Firestore:** armazenamento e sincronização na nuvem.
- **sqflite:** integração com SQLite.
- **sqflite_common_ffi_web:** suporte ao SQLite no Flutter Web.

## Funcionalidades

- Cadastro de usuários.
- Login e logout.
- Criação, edição e exclusão de anotações.
- Armazenamento local com SQLite.
- Sincronização com Firebase Cloud Firestore.
- Associação das anotações ao usuário autenticado.
- Recuperação das anotações após novo login.
- Organização por categorias: Estudos, Trabalho, Pessoal e categorias personalizadas.
- Pesquisa de anotações por título ou conteúdo.
- Arquivamento e desarquivamento de anotações.
- Separação entre notas ativas e arquivadas.
- Prevenção de duplicação durante a sincronização.

## Tecnologias e arquitetura

O projeto está organizado da seguinte maneira:

```text
lib/
├── database/
│   └── database_helper.dart
├── models/
│   └── note.dart
├── pages/
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── notes_page.dart
│   └── note_form_page.dart
├── services/
│   ├── auth_service.dart
│   └── note_service.dart
├── widgets/
│   └── note_card.dart
├── firebase_options.dart
└── main.dart
```

- **Models:** representam os dados das anotações.
- **Database:** controla as operações do SQLite.
- **Services:** concentram a autenticação e as operações de sincronização.
- **Pages:** contêm as telas da aplicação.
- **Widgets:** componentes reutilizáveis da interface.

## Estratégia de sincronização

O aplicativo utiliza SQLite para manter uma cópia local das anotações e Cloud Firestore para armazenar os dados na nuvem.

A sincronização funciona da seguinte forma:

1. As anotações locais são consultadas.
2. Anotações que ainda não possuem identificador na nuvem são enviadas ao Firestore.
3. O identificador do documento criado é armazenado no SQLite, evitando duplicações.
4. As anotações vinculadas ao UID do usuário são recuperadas do Firestore.
5. Os dados recebidos são salvos ou atualizados no banco local.

O identificador `cloudId` permite relacionar cada anotação local ao documento correspondente na nuvem.

## Segurança

O Firebase Authentication identifica os usuários por meio do UID.

As regras de segurança do Cloud Firestore restringem a leitura, criação, edição e exclusão de documentos às contas autenticadas e aos respectivos proprietários das anotações.

As configurações públicas necessárias para inicializar o Firebase ficam no arquivo `firebase_options.dart`. Credenciais privadas e chaves de serviço não devem ser adicionadas ao repositório.

## Como executar o projeto

### 1. Pré-requisitos

- Flutter instalado.
- Dart instalado.
- Google Chrome instalado.
- Projeto configurado no Firebase.

### 2. Clonar o repositório

```bash
git clone https://github.com/Gabriel-Palermo/bloco_de_nota.git
```

### 3. Entrar na pasta

```bash
cd bloco_de_nota
```

### 4. Instalar as dependências

```bash
flutter pub get
```

### 5. Configurar o SQLite para Web

```bash
dart run sqflite_common_ffi_web:setup
```

### 6. Configurar o Firebase

Configure o Firebase Authentication e o Cloud Firestore no projeto Firebase.

Caso necessário, gere novamente as configurações do FlutterFire:

```bash
dart pub global run flutterfire_cli:flutterfire configure
```

Confira também as regras de segurança do Firestore antes de executar a aplicação.

### 7. Executar no Chrome

```bash
flutter run -d chrome
```

## Testes realizados

Foram realizados testes funcionais para verificar:

- Cadastro e autenticação de usuários.
- Criação de anotações.
- Edição sem gerar documentos duplicados.
- Exclusão de anotações.
- Sincronização entre SQLite e Firestore.
- Recuperação das anotações após logout e novo login.
- Persistência dos dados após atualizar a página.
- Criação e seleção de categorias.
- Pesquisa por título e conteúdo.
- Arquivamento e desarquivamento de anotações.
- Execução da aplicação no Google Chrome.

## Evidências

As capturas de tela das funcionalidades e do armazenamento das anotações no Firebase estão disponíveis na pasta `Prints`.

## Autor

**Gabriel Palermo**

Projeto acadêmico desenvolvido no curso de Engenharia de Software.