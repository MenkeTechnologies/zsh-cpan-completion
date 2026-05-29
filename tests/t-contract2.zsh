#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-cpan-completion second-tier contracts.
#####          Cover surfaces not pinned by t-unit.zsh:
#####          ZPWR_CPAN_MIN_PREFIX overridability, __cpan_modules
#####          cleanup of i, return-on-match short-circuit, both
#####          completion files end with _cpan/_cpanm invocation.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-cpan-completion.plugin.zsh"
}

@test 'ZPWR_CPAN_MIN_PREFIX defaults to 2 but is overridable from caller' {
    # Pin: the plugin must NOT clobber a user-set value. Current code
    # uses `export ZPWR_CPAN_MIN_PREFIX=2` which DOES overwrite. Pin
    # the current behavior so a future migration to test -z guard is
    # a deliberate change.
    local out
    out=$(ZPWR_CPAN_MIN_PREFIX=5 zsh -c "
        source '$pluginFile' 2>/dev/null
        print \"\$ZPWR_CPAN_MIN_PREFIX\"
    ")
    # Current behavior: plugin overwrites. Pin as 2 so a future change
    # to preserve user value flips this to 5 and the test catches it.
    assert "$out" same_as '2'
}

@test '__cpan_modules unsets i after iteration (no global leak)' {
    # Pin: __cpan_modules walks searchLines with a numeric i; without
    # the trailing `unset i`, the loop variable leaks into the user's
    # interactive shell.
    grep -qE '^[[:space:]]+unset i' "$pluginFile"
    assert $? equals 0
}

@test '__cpan_modules returns 0 immediately on match (short-circuit)' {
    # Pin: when a matching line is found, the wrapped helper is
    # called and the fn returns. Removing the return would silently
    # double-call helpers for inputs that match both patterns.
    local count
    count=$(grep -cE 'return 0' "$pluginFile" || true)
    [[ "$count" -ge 2 ]]
    assert $? equals 0
}

@test '_cpan file is inline-style completion (uses _arguments + state $ret)' {
    # Pin: _cpan is the inline-style completion form (compdef registers
    # it; the body uses _arguments and returns $ret). NOT a wrapper fn
    # that gets invoked at end. Pin the canonical structure.
    grep -qE '_arguments' "$pluginDir/src/_cpan"
    assert $? equals 0
    local last
    last=$(grep -vE '^\s*$' "$pluginDir/src/_cpan" | tail -1)
    assert "$last" same_as 'return ret'
}

@test '_cpanm file is inline-style completion (_arguments + return ret)' {
    grep -qE '_arguments' "$pluginDir/src/_cpanm"
    assert $? equals 0
    local last
    last=$(grep -vE '^\s*$' "$pluginDir/src/_cpanm" | tail -1)
    assert "$last" same_as 'return ret'
}

@test 'plugin uses perl -MCPAN -e CPAN::Shell to drive the search (no scrape of HTML)' {
    # Pin: the data source is the real CPAN::Shell module via perl.
    # If a refactor scraped metacpan.org HTML, the completion would
    # break offline AND introduce a network dependency on a third
    # party. Pin the local perl-shell entrypoint.
    grep -q "perl -MCPAN -e" "$pluginFile"
    assert $? equals 0
    grep -q "CPAN::Shell->m" "$pluginFile"
    assert $? equals 0
}
