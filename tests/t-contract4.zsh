#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-cpan-completion — fourth-tier contracts.
#####          Pins for cpanm-cache-directory routing, perl
#####          subprocess error tolerance (stderr swallowed via
#####          2>/dev/null so missing perl/CPAN does not break tab),
#####          and the namespace-prefix `__cpan_` discipline.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-cpan-completion.plugin.zsh"
}

@test 'perl-MCPAN invocation swallows stderr via 2>/dev/null' {
    # Pin: stderr suppression on the perl subprocess. If perl is absent
    # or MCPAN is uninstalled, the shell call returns empty and the
    # completion falls through silently rather than spamming errors.
    grep -qF "perl -MCPAN -e " "$pluginFile"
    local has_perl=$?
    grep -qF "2>/dev/null)}\")" "$pluginFile"
    local has_redirect=$?
    assert $(( has_perl + has_redirect )) equals 0
}

@test 'all helper fns use the __cpan_ namespace prefix' {
    # Pin: every internal helper starts with __cpan_. A future
    # convenience wrapper without the prefix risks shadowing a user fn.
    local total namespaced
    total=$(grep -cE '^function [a-z_]' "$pluginFile")
    namespaced=$(grep -cE '^function __cpan_' "$pluginFile")
    assert "$total" same_as "$namespaced"
}

@test 'cache key format: cpan_${PREFIX}_cache (per-prefix isolation)' {
    # Pin: cache keys are scoped by the current PREFIX so two parallel
    # `cpan Mo<TAB>` vs `cpan Ne<TAB>` lookups do not stomp each
    # other. Removing $PREFIX would conflate every search into one
    # cache entry, returning wrong candidates after the second query.
    grep -qF 'cpan_${PREFIX}_cache' "$pluginFile"
    assert $? equals 0
}

@test 'match-array elements are colon-escaped for _describe format' {
    # Pin: _describe parses entries as `name:description`. A literal
    # colon in the module name (Foo::Bar) would split into two
    # candidates without the escape. Pin presence of the substitution
    # `//:/\\:` on both name and tarball assignments — name+tarball
    # in __cpan_single_module, name+tarball in __cpan_multiple_modules
    # => 4 sites total.
    local count pat
    # Build the pattern at runtime to avoid zunit's @test{} parser
    # interpreting the backslashes.
    pat=$(printf '//:/%s%s:' '\\' '\\')
    pat="${pat:0:6}"
    # pat is now literally:  //:/\\:
    count=$(grep -cF "$pat" "$pluginFile")
    assert "$count" same_as '4'
}

@test 'searchLines split by NEWLINE via f-at flag for empty-preserving split' {
    # Pin: the f-at parameter flag splits on backslash-n with empty
    # element preservation. The f-alone form drops empty lines; the
    # s-on-backslash-n form collapses runs of newlines. CPAN output has
    # blank separators between records so the at-modifier is correct.
    local fat has_fat has_perl
    fat=$(printf '%cf@%c' '(' ')')
    if grep -qF "$fat" "$pluginFile"; then
        has_fat=0
    else
        has_fat=1
    fi
    if grep -qF "perl -MCPAN" "$pluginFile"; then
        has_perl=0
    else
        has_perl=1
    fi
    assert $(( has_fat + has_perl )) equals 0
}
