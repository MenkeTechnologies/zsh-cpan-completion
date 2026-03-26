```
 ________  ________  ________  ________           ________  ________  _____ ______   ________  ___       _______  _________  ___  ________  ________
|\_____  \|\   ____\|\   __  \|\   ____\         |\   ____\|\   __  \|\   _ \  _   \|\   __  \|\  \     |\  ___ \|\___   ___\\  \|\   __  \|\   ___  \
 \|___/  /\ \  \___|\ \  \|\  \ \  \___|_  ______\ \  \___|\ \  \|\  \ \  \\\__\ \  \ \  \|\  \ \  \    \ \   __/\|___ \  \_\ \  \ \  \|\  \ \  \\ \  \
     /  / /\ \_____  \ \   _  _\ \_____  \|\______\ \  \    \ \  \\\  \ \  \\|__| \  \ \   ____\ \  \    \ \  \_|/__  \ \  \ \ \  \ \  \\\  \ \  \\ \  \
    /  /_/__\|____|\  \ \  \\  \\|____|\  \|________|\ \  \___\ \  \\\  \ \  \    \ \  \ \  \___|\ \  \____\ \  \_|\ \  \ \  \ \ \  \ \  \\\  \ \  \\ \  \
   |\________\____\_\  \ \__\\ _\ ____\_\  \          \ \_______\ \_______\ \__\    \ \__\ \__\    \ \_______\ \_______\  \ \__\ \ \__\ \_______\ \__\\ \__\
    \|_______|\_________\|__|\|__|\_________\          \|_______|\|_______|\|__|     \|__|\|__|     \|_______|\|_______|   \|__|  \|__|\|_______|\|__| \|__|
             \|_________|        \|_________|
```

<p align="center">
  <img src="http://menketechnologies.github.io/img/zsh-cpan-completion.png?raw=true" alt="neural-link preview"/>
</p>

<p align="center">
  <code>[ SYSTEM ONLINE ] [ CPAN NEURAL-LINK ACTIVE ] [ ZSH MAINFRAME CONNECTED ]</code>
</p>

---

> *"The street finds its own uses for things."* — William Gibson

## // WHAT IS THIS

A **zsh completion engine** that jacks directly into the CPAN network. While the corpos at OMZ gave you basic `cpanm` completion, this plugin rips open a live connection to the Perl module registry and pulls completions straight from the source.

Type `cpan install <module><TAB>` or `cpanm install <module><TAB>` and watch the autocomplete flood in — real packages, real tarballs, no static lists.

### >> FEATURES

- Live remote CPAN package completion via `perl -MCPAN -e 'CPAN::Shell->m("...")'`
- Full `cpan` and `cpanm` flag/option completion
- Intelligent caching system — hit the net once, pull from local memory after
- Overload protection: prefix must be >= `ZPWR_CPAN_MIN_PREFIX` chars (default: `2`) to prevent your shell from flatlining
- Tarball file completion (`.tar.gz`, `.tgz`, `.tar.bz2`, `.zip`)

---

## // JACK IN

### Zinit — *recommended neural interface*

```sh
# >> ~/.zshrc
source "$HOME/.zinit/bin/zinit.zsh"
zinit ice lucid nocompile
zinit load MenkeTechnologies/zsh-cpan-completion
```

### Oh My Zsh — *legacy firmware*

```sh
cd "$HOME/.oh-my-zsh/custom/plugins" && git clone https://github.com/MenkeTechnologies/zsh-cpan-completion.git
```

Then slot `zsh-cpan-completion` into the `plugins` array in `~/.zshrc`.

### Manual Install — *bare metal*

```sh
git clone https://github.com/MenkeTechnologies/zsh-cpan-completion.git
```

Source `zsh-cpan-completion.plugin.zsh` in your `~/.zshrc` or any startup script.

---

## // CONFIG

| Variable | Default | Description |
|---|---|---|
| `ZPWR_CPAN_MIN_PREFIX` | `2` | Minimum prefix length before querying remote CPAN. Lower = more data, higher crash risk. Tune at your own peril. |

---

## // ARCHITECTURE

```
┌──────────────────────────────────────────────────┐
│                   ZSH MAINFRAME                  │
│                                                  │
│  ┌──────────┐    ┌──────────┐    ┌────────────┐ │
│  │  _cpan   │    │  _cpanm  │    │  plugin.zsh│ │
│  │ compdef  │───▶│ compdef  │───▶│  core logic │ │
│  └──────────┘    └──────────┘    └─────┬──────┘ │
│                                        │        │
│                                        ▼        │
│                               ┌────────────────┐│
│                               │  CPAN::Shell   ││
│                               │  remote query  ││
│                               └───────┬────────┘│
│                                       │         │
│                                       ▼         │
│                               ┌────────────────┐│
│                               │  zsh _describe ││
│                               │  completion UI ││
│                               └────────────────┘│
└──────────────────────────────────────────────────┘
```

---

## // LICENSE

MIT License — Copyright (c) 2017-2020 **MenkeTechnologies**

Free as in freedom. Fork it. Mod it. Distribute it. The source is open.

---

<p align="center"><code>[ END TRANSMISSION ]</code></p>
