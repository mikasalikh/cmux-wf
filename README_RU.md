# cmux-wf

Набор скриптов и Claude Code skill для организации рабочих процессов [Claude Code](https://claude.ai) внутри [cmux](https://cmux.com) — мультиплексора терминалов с поддержкой статусов, логов, уведомлений и управления workspace.

**[English version](README.md)**

---

## 📦 Что входит в пакет

```
cmux-wf/
├── install.sh                          # Установщик с проверкой зависимостей
├── prompts/
│   └── pm.md                           # PM-промпт — инструкция для оркестратора
├── scripts/
│   ├── cdm.sh                          # Claude Dangerous Mode — быстрый запуск
│   └── pm-cmux.sh                      # PM-оркестратор агентов
└── .claude/
    └── skills/
        └── cmux/
            └── SKILL.md                # Claude Code skill — полный справочник cmux API
```

| Компонент | Назначение |
|---|---|
| `cdm.sh` | Быстрый запуск Claude Code с `--dangerously-skip-permissions` и автонастройкой cmux workspace |
| `pm-cmux.sh` | PM-оркестратор — управление Claude-агентами через cmux workspace |
| `prompts/pm.md` | PM-промпт — Claude анализирует проект и сам определяет агентов и задачи |
| `.claude/skills/cmux/` | Skill для Claude Code — полное знание cmux API |

---

## 🔧 Требования

| Зависимость | Назначение | Установка |
|---|---|---|
| [Homebrew](https://brew.sh) | Пакетный менеджер | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| [cmux](https://cmux.com) | Мультиплексор терминалов | `brew install cmux` |
| [Claude Code](https://claude.ai) | CLI для Claude | `brew install --cask claude-code` |
| zsh | Требуется для `pm-cmux.sh` | Встроен в macOS |
| bc | Вычисление прогресса | Встроен в macOS |

---

## ⚡ Установка

```bash
git clone https://github.com/mikasalikh/cmux-wf.git
cd cmux-wf
./install.sh
```

Инсталлятор интерактивно проверяет каждую зависимость и предлагает установить недостающие:

1. **Homebrew** — если не найден, предложит установить
2. **cmux** — `brew install cmux`
3. **Claude Code** — `brew install --cask claude-code`
4. Копирует скрипты в `~/.local/bin` (или указанную директорию)
5. Создаёт симлинк `cdm` для быстрого вызова

Установка в другую директорию:

```bash
./install.sh ~/my-scripts
```

---

## 🎯 Quick Start — PM-оркестратор

Самый быстрый способ использовать cmux-wf — запустить Claude как PM-оркестратора. Он сам проанализирует проект, определит нужных агентов и распределит работу.

### Шаг 0 — Подготовьте документацию проекта

PM-оркестратор работает на основе документации. Чем лучше описан проект — тем точнее будет планирование и распределение задач.

> [!IMPORTANT]
> Перед запуском оркестратора убедитесь, что в проекте есть ключевые документы. Без них PM будет угадывать — с ними будет действовать точно.

Рекомендуемый минимум:

| Документ | Что описывает | Пример файла |
|---|---|---|
| **PRD** | Требования к продукту, user stories, acceptance criteria | `docs/prd.md` |
| **Архитектура** | Компоненты системы, связи, data flow | `docs/architecture.md` |
| **Стек технологий** | Языки, фреймворки, БД, инфраструктура | `docs/stack.md` или в README |
| **Дизайн / UI** | Макеты, wireframes, UI kit, ссылки на Figma | `docs/design.md` |
| **API-контракты** | Эндпоинты, форматы запросов/ответов | `docs/api.md` или OpenAPI spec |
| **Схема БД** | Таблицы, связи, индексы | `docs/database.md` |

Не обязательно иметь всё — но каждый документ повышает качество работы агентов. PM использует их для формирования точных промптов.

### Шаг 1 — Скопируйте cmux-wf в проект

```bash
cp -r /path/to/cmux-wf/.claude/ ~/your-project/.claude/
cp -r /path/to/cmux-wf/prompts/ ~/your-project/prompts/
```

> [!NOTE]
> Claude Code автоматически распознает skill `cmux` и сможет управлять workspace, panes, статусами и логами. Если Claude Code уже запущен — перезапустите сессию, чтобы skill подхватился.

### Шаг 2 — Запустите cmux

Откройте приложение cmux (или из терминала):

```bash
open -a cmux
```

### Шаг 3 — Запустите cdm внутри cmux

```bash
cd ~/your-project
cdm                        # или: cdm ~/your-project
```

> [!IMPORTANT]
> `cdm` нужно запускать **только внутри терминала cmux**. Если cmux не запущен — сначала откройте его: `open -a cmux`.

> [!CAUTION]
> `cdm` запускает Claude с флагом `--dangerously-skip-permissions` — полный доступ к файловой системе, shell и сети без подтверждений. Подробнее в разделе [Безопасность](#-безопасность).

### Шаг 4 — Дайте задачу PM

В сессии Claude напишите:

```
Прочитай prompts/pm.md — это твоя инструкция как PM-оркестратор.
Задача: <опишите что нужно сделать>
```

### Примеры задач

```
# Новая фича
Задача: Добавь авторизацию через OAuth2 — backend API + frontend формы + тесты.

# Рефакторинг
Задача: Перенеси монолитный API на модульную структуру. Раздели по доменам.

# Полный MVP
Задача: Создай MVP чат-бота с RAG — backend на FastAPI, frontend на React,
vector store на pgvector. Разбей на фазы, запускай агентов параллельно.

# Frontend с браузером
Задача: Переделай дашборд — новый layout, графики, фильтры.
Открой http://localhost:5173 в cmux браузере и проверяй результат визуально.

# E2E с браузером
Задача: Реализуй форму регистрации и протестируй через cmux браузер —
заполни поля, отправь форму, проверь что редирект и данные в БД корректны.
```

### Что произойдёт

1. Claude прочитает `prompts/pm.md` и станет PM-оркестратором
2. Проанализирует ваш проект — стек, структуру, зависимости
3. Разобьёт задачу на фазы и подзадачи, создаст `progress.md`
4. Запустит агентов в отдельных cmux workspace через `pm-cmux.sh`
5. Будет мониторить прогресс, реагировать на ошибки, запускать следующие фазы
6. В sidebar cmux вы увидите статусы всех агентов в реальном времени

> [!TIP]
> Вы можете наблюдать за работой каждого агента, переключаясь между cmux workspace. PM видит всё через `pm_dashboard` и `pm_read_agent`.

---

## 📖 Reference — `pm-cmux.sh`

PM-оркестратор для управления Claude-агентами через cmux workspace. Работает как библиотека (source) и как CLI.

### Как библиотека (zsh)

```zsh
source scripts/pm-cmux.sh

# 1. Инициализация
pm_init

# 2. Запуск агентов — каждый в своём workspace
ws_be=$(pm_launch_agent backender "API Scaffold" "Create FastAPI app skeleton...")
ws_ai=$(pm_launch_agent ai-engineer "Embedder" "Create RAG embedder service...")

# 3. Обновление статусов
pm_update_agent backender working "$ws_be"
pm_update_agent ai-engineer working "$ws_ai"

# 4. Прогресс
pm_set_progress 0.35 "Phase 1: 15/42 tasks"
pm_phase_progress 1 15 42

# 5. Мониторинг
pm_dashboard                        # полный обзор
pm_read_agent "$ws_be" 100          # вывод агента без переключения

# 6. Завершение
pm_agent_done backender "$ws_be"    # ✅ + уведомление
pm_agent_failed ai-engineer "Timeout" "$ws_ai"  # ❌ + уведомление

# 7. Очистка
pm_cleanup_agent backender "$ws_be"
```

### Как CLI

```bash
pm-cmux.sh init
pm-cmux.sh launch backender "API Scaffold" "Create FastAPI app..."
pm-cmux.sh update backender working
pm-cmux.sh done backender
pm-cmux.sh failed ai-engineer "Timeout"
pm-cmux.sh progress 0.65 "v1 MVP: 65%"
pm-cmux.sh phase 3 18 52
pm-cmux.sh read workspace:5 50
pm-cmux.sh dashboard
pm-cmux.sh cleanup backender workspace:5
pm-cmux.sh help
```

### 🎨 Встроенные агенты

| Агент | Цвет | Роль |
|---|---|---|
| pm | 🔵 `#007AFF` | PM-оркестратор |
| backender | 🟢 `#34c759` | Backend-разработка |
| frontender | 🔷 `#5AC8FA` | Frontend-разработка |
| db-architect | 🟡 `#FFD60A` | Архитектура БД |
| ai-engineer | 🟣 `#FF2D92` | AI/ML интеграции |
| channel-engineer | 🟠 `#FF9500` | Каналы коммуникации |
| test-writer | ⚪ `#FFFFFF` | Тесты |
| security-auditor | 🔴 `#FF3B30` | Аудит безопасности |

### 📊 Статусы агентов

| Статус | Значение |
|---|---|
| ⏳ starting | Агент запускается |
| ⚡ working | Агент работает |
| 💤 waiting | Ожидает ввода или зависимость |
| 🔍 reviewing | Ревью кода |
| ✅ done | Завершён успешно |
| ❌ failed | Завершён с ошибкой |
| 🚫 blocked | Заблокирован |

---

### 🧠 Claude Code Skill — cmux

Skill `.claude/skills/cmux/SKILL.md` даёт Claude Code полное знание cmux API. Когда skill установлен, Claude может самостоятельно:

- Создавать и управлять workspace и split-панелями
- Устанавливать статусы и прогресс в sidebar
- Отправлять команды в терминалы других workspace
- Читать вывод агентов через `read-screen`
- Открывать и взаимодействовать с браузером
- Отправлять уведомления

> [!TIP]
> Skill активируется автоматически когда задача связана с управлением workspace или оркестрацией агентов.

### 🌐 Встроенный браузер

cmux имеет встроенный браузер прямо в терминале — Claude может открывать страницы, кликать элементы, заполнять формы, делать скриншоты и выполнять JavaScript. Удобно для интерактивной frontend-разработки и тестирования без переключения контекста:

```bash
cmux browser open-split "http://localhost:3000"         # браузер в split
cmux browser click "#submit-btn"                        # клик по элементу
cmux browser fill "#email" "test@example.com"           # заполнение формы
cmux browser screenshot --out /tmp/page.png             # скриншот
cmux browser eval "document.title"                      # выполнение JS
```

---

## ✅ Best Practices

### 🏗️ Организация работы

- **Один агент — один workspace.** Так логи, статусы и вывод не пересекаются
- **`pm_init` перед запуском агентов** — инициализирует PM workspace
- **Обновляйте статусы** — sidebar cmux показывает состояние всех агентов в реальном времени
- **`pm_dashboard` для обзора** — показывает workspace, статусы и последние логи
- **Очищайте завершённые workspace** — `pm_cleanup_agent` закрывает workspace и убирает статус

### 🖥️ Работа с cdm

- **Запускайте `cdm` только внутри cmux** — сначала откройте приложение cmux, затем `cdm` в его терминале
- Запускайте `cdm` из корня проекта — Claude Code получит правильный контекст
- `--remote-control` позволяет управлять сессией программно через cmux

### 📡 Мониторинг агентов

- **`pm_read_agent`** — читайте вывод агента без переключения workspace
- **Передавайте причину в `pm_agent_failed`** — она попадёт в лог и уведомление macOS
- **`pm_set_progress` для milestone-ов** — не обновляйте на каждую микро-задачу
- **Signal-based мониторинг** для автоматического обнаружения завершения агентов (см. skill)

### ⚙️ cmux-команды в скриптах

- **Всегда `2>/dev/null`** на cmux вызовах — graceful handling при отсутствии сокета
- **Проверяйте доступность** перед серией команд: `command -v cmux &>/dev/null`
- **`--workspace`** для таргетирования конкретного workspace; без него — текущий
- **Используйте цвета консистентно** — придерживайтесь цветовой карты агентов

---

## 🛑 Безопасность

> [!CAUTION]
> **`--dangerously-skip-permissions`**
>
> Этот флаг **полностью отключает** систему подтверждений Claude Code.
> Claude получает неограниченный доступ к файловой системе, shell и сети.
>
> | | |
> |---|---|
> | 🔴 **Запрещено** | Production-серверы, shared-машины, CI/CD pipelines |
> | 🟡 **С осторожностью** | Локальная разработка с чужим / незнакомым кодом |
> | 🟢 **Допустимо** | Изолированная локальная среда, доверенные проекты |
>
> **Вы несёте полную ответственность за все действия Claude в этом режиме.**

> [!WARNING]
> - Промпт-файлы агентов создаются в `/tmp` — не передавайте чувствительные данные через промпты
> - cmux socket (`/tmp/cmux.sock`) доступен всем локальным процессам — ограничьте доступ к машине

