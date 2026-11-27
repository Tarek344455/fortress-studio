# Fortress Studio (React Web Edition)

Fortress Studio is a bidirectional (Arabic/English) command center rewritten as a React + TypeScript + Vite web application from the original Flutter Android codebase.

## Features Ported
- **Command Deck (`قيادة المنظومة`)**: System and bridge readiness view (Termux, external apps, storage permissions, Vault/Guard/Trinity/State checks), `kashkool-savior` role/model prompt router (`Plan`, `Builder`, `Reviewer`, `Guard` across `nemotron`, `deepseek`, `qwen`, `claude-cli`), interactive Alpine proot terminal, and `fortress-guard` check runner.
- **Vault Explorer (`مستكشف vault`)**: Directory tree browser for `/mnt/sdcard/opencode/build-vault`, file viewer with clipboard copy, atomic write editor with automatic `.bak` creation, line-by-line diff viewer against `.bak`, and one-click `.bak` rollback.
- **Tools Studio (`الأدوات والاستوديو`)**: Registry of all 8 CLI tools (`trinity`, `fortress-guard`, `start-savior`, `start-deck`, `opencode`, `claude-free`, `agy-cli`, `kashkool-studio`) with status badges, optional argument input, and command execution output.
- **Settings (`الإعدادات`)**: Vault path reference list with copyable `CodeBlock`s, Termux/Guard/Storage permission status rows, and interactive storage permission grant.

## Web Runtime Adaptation
- Browser apps cannot invoke Android `MethodChannel` (`fortress.studio.app/bridge`), Termux intents, or local Android `/mnt/sdcard` filesystems directly. `src/services/nativeBridge.ts` provides a `localStorage`-backed Virtual Vault and command runner preserving the exact contracts, `.bak` atomic write/diff/rollback logic, and CLI behavior.

## Development
```bash
npm install
npm run dev
npm run build
```
