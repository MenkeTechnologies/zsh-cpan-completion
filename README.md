# zsh-cpan-completion

This plugin has all functionality of OMZ cpanm completion but it also allows `cpan install <tab>` and `cpanm install <tab>` to complete remote CPAN package from output of `perl -MCPAN -e 'CPAN::Shell->m("/$package/")'`.

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
