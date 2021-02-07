# zsh-cpan-completion

![zsh-cpan-completion screenshot](http://menketechnologies.github.io/img/zsh-cpan-completion.png?raw=true)

This plugin has all functionality of OMZ cpanm completion but it also allows `cpan install word<tab>` and `cpanm install <tab>` to complete remote CPAN package from output of `perl -MCPAN -e 'CPAN::Shell->m("/$package/")'`.  The word before tab completion must be >= 2 characters in length to reduce crashing of zsh from too many packages.
ZPWR_CPAN_MIN_PREFIX controls the min length of prefix.

## Install for Zinit
> `~/.zshrc`
```sh
source "$HOME/.zinit/bin/zinit.zsh"
zinit ice lucid nocompile
zinit load MenkeTechnologies/zsh-cpan-completion
```

## Install for Oh My Zsh

```sh
cd "$HOME/.oh-my-zsh/custom/plugins"  && git clone https://github.com/MenkeTechnologies/zsh-cpan-completion.git
```

Add `zsh-cpan-completion` to plugins array in ~/.zshrc

## General Install

```sh
git clone https://github.com/MenkeTechnologies/zsh-cpan-completion.git
```

source zsh-cpan-completion.plugin.zsh or add code to zshrc or any startup script
