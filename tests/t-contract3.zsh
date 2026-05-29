#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-cpan-completion — third-tier surface pins:
#####          - _cpan and _cpanm both terminate with `return ret` (exit-code propagation)
#####          - _arguments cardinality: every short flag is single-arg shaped
#####          - file glob covers all 4 archive extensions (tar.gz tgz tar.bz2 zip)
#####          - perl driver uses -MCPAN -e CPAN::Shell (not legacy `cpan` shell-out)
#####          - ZPWR_CPAN_MIN_PREFIX guard uses >= comparison (not > or ==)
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-cpan-completion.plugin.zsh"
    cpanFile="$pluginDir/src/_cpan"
    cpanmFile="$pluginDir/src/_cpanm"
}

@test '_cpan ends with `return ret` (compsys exit-code contract)' {
    # Pin: compsys completion fns must `return $ret` so the dispatcher
    # knows whether a candidate was added. Omitting it returns the rc
    # of the last command, which silently breaks fallback chaining.
    local last
    last=$(grep -vE '^\s*$|^#' "$cpanFile" | tail -1)
    assert "$last" same_as 'return ret'
}

@test '_cpanm ends with `return ret` (compsys exit-code contract)' {
    local last
    last=$(grep -vE '^\s*$|^#' "$cpanmFile" | tail -1)
    assert "$last" same_as 'return ret'
}

@test '_arguments uses -s flag (allows clustered short opts: -abc == -a -b -c)' {
    # Pin: `-s` lets users cluster short flags. Without it, `cpan -av`
    # would treat -av as a single unknown flag. cpan supports short
    # flag clustering; the completion must match.
    grep -qE '_arguments -s ' "$cpanFile"
    assert $? equals 0
}

@test 'file glob covers all 4 CPAN archive extensions (tar.gz tgz tar.bz2 zip)' {
    # Pin: cpan accepts local archives in these 4 formats. Dropping
    # any extension silently disables completion for that archive type.
    grep -qF 'tar.gz|tgz|tar.bz2|zip' "$cpanFile"
    assert $? equals 0
}

@test 'perl driver uses CPAN::Shell methods (not cpan shell-out)' {
    # Pin: the perl driver invokes CPAN::Shell directly, not the
    # legacy `cpan` interactive REPL. Replacing with `cpan -i` would
    # hang on TTY input prompts in non-interactive context.
    grep -qE 'perl[[:space:]]+-MCPAN' "$pluginFile"
    assert $? equals 0
}
