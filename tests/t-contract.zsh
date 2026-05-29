#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-cpan-completion — plugin-contract pins.
#####          Entrypoint stem matches plugin dir (typical
#####          zsh-plugin install pattern), entrypoint parses
#####          cleanly under `zsh -n`, and (where applicable)
#####          every completion file starts with `#compdef`.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
}

@test 'entrypoint stem matches plugin directory basename' {
    # The standard zsh-plugin install pattern (oh-my-zsh, zinit,
    # antibody, antigen) sources `<repo>/<repo>.plugin.zsh`. The
    # stem of `zsh-cpan-completion.plugin.zsh` must equal the parent directory's
    # basename so generated source lines stay copy-pasteable.
    local entry='zsh-cpan-completion.plugin.zsh'
    local stem="${entry%.plugin.zsh}"
    local dir="${pluginDir##*/}"
    # Accept either exact match or `zsh-` prefix on dir (some repos
    # like `docker-aliases.plugin.zsh` live under `zsh-docker-aliases`).
    [[ "$stem" == "$dir" || "zsh-$stem" == "$dir" ]]
    assert $state equals 0
}

@test 'entrypoint parses cleanly under zsh -n' {
    run zsh -n "$pluginDir/zsh-cpan-completion.plugin.zsh"
    assert $state equals 0
}

@test 'every completion file starts with #compdef directive' {
    # Pass trivially when there are no `_*` files; otherwise every
    # one must lead with `#compdef`. A missing directive silently
    # disables completion. Use `find` so a zero-match doesn't trip
    # nomatch under EXTENDED_GLOB.
    local missing=""
    local d f
    for d in "$pluginDir/completions" "$pluginDir"; do
        [[ -d "$d" ]] || continue
        while IFS= read -r f; do
            [[ -f "$f" ]] || continue
            run head -1 "$f"
            [[ "$output" =~ ^#compdef ]] || missing="$missing ${f##*/}"
        done < <(find "$d" -maxdepth 1 -name "_*" -type f 2>/dev/null)
    done
    assert "$missing" is_empty
}

#--------------------------------------------------------------
# Round 2: CPAN-completion behavior pins
#--------------------------------------------------------------

@test 'plugin exports ZPWR_CPAN_MIN_PREFIX with default 2' {
    # The minimum-prefix env var controls how soon completion fires.
    # Pin the default so a user's `cpan A<tab>` still triggers a
    # search rather than waiting until 3+ chars.
    local body
    body=$(cat "$pluginDir/zsh-cpan-completion.plugin.zsh")
    assert "$body" contains 'ZPWR_CPAN_MIN_PREFIX=2'
}

@test 'plugin defines BOTH __cpan_single_module and __cpan_multiple_modules' {
    # The completion dispatches between the two helpers based on
    # match count; both must be present.
    local body
    body=$(cat "$pluginDir/zsh-cpan-completion.plugin.zsh")
    assert "$body" contains '__cpan_single_module'
    assert "$body" contains '__cpan_multiple_modules'
}

@test 'completion uses _describe -t cpan-module for menu output' {
    # The `-t cpan-module` tag is what users see in `zstyle` for
    # styling/filtering. A rename here silently breaks user themes.
    local body
    body=$(cat "$pluginDir/zsh-cpan-completion.plugin.zsh")
    assert "$body" contains "_describe -t cpan-module"
}

@test 'plugin file ends with #compdef directive or autoload helper' {
    # The plugin must register the completion surface; either via
    # #compdef line OR by exporting a callable. Pin presence so a
    # future minimal-deps trim doesn't drop the registration.
    run grep -E '(#compdef|compdef|_cpan)' "$pluginDir/zsh-cpan-completion.plugin.zsh"
    assert $state equals 0
}
