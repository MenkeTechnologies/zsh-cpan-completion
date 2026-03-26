#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Author: MenkeTechnologies
##### GitHub: https://github.com/MenkeTechnologies
##### Date: Thu Mar 26 2026
##### Purpose: zsh unit tests for cpan completion plugin
##### Notes:
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"

    # stub zsh completion functions used by the plugin
    function _describe() { : ; }
    function _retrieve_cache() { return 1 ; }
    function _store_cache() { : ; }

    source "$pluginDir/zsh-cpan-completion.plugin.zsh"
}

@teardown {
    unfunction _describe _retrieve_cache _store_cache 2>/dev/null
    unfunction __cpan_single_module __cpan_multiple_modules __cpan_modules 2>/dev/null
}

# ── environment / setup ─────────────────────────────────────

@test 'ZPWR_CPAN_MIN_PREFIX is exported and equals 2' {
    assert "$ZPWR_CPAN_MIN_PREFIX" is_not_empty
    assert "$ZPWR_CPAN_MIN_PREFIX" same_as "2"
}

@test 'fpath contains src directory' {
    local found=0
    local src_dir="$pluginDir/src"
    local p
    for p in $fpath; do
        if [[ "$p" == "$src_dir" ]]; then
            found=1
            break
        fi
    done
    assert $found equals 1
}

@test 'src/_cpan completion file exists' {
    assert "$pluginDir/src/_cpan" is_file
}

@test 'src/_cpanm completion file exists' {
    assert "$pluginDir/src/_cpanm" is_file
}

@test '__cpan_single_module function is defined' {
    run whence -w __cpan_single_module
    assert $output contains "function"
}

@test '__cpan_multiple_modules function is defined' {
    run whence -w __cpan_multiple_modules
    assert $output contains "function"
}

@test '__cpan_modules function is defined' {
    run whence -w __cpan_modules
    assert $output contains "function"
}

# ── __cpan_single_module parsing ─────────────────────────────

@test 'single module: parses id and CPAN_FILE' {
    local -a ary searchLines
    local package i
    searchLines=(
        "Fetching with HTTP::Tiny"
        "Module id = Acme::Test"
        "    CPAN_FILE  A/AU/AUTHOR/Acme-Test-0.01.tar.gz"
    )
    i=1

    # override _describe to capture args
    local -a captured
    function _describe() { captured=("${@}") ; }

    __cpan_single_module

    assert "$ary[1]" same_as 'Acme\:\:Test:A/AU/AUTHOR/Acme-Test-0.01.tar.gz'
}

@test 'single module: ary is empty when no id line present' {
    local -a ary searchLines
    local package i
    searchLines=(
        "No match found"
    )
    i=1

    __cpan_single_module

    assert "${#ary}" equals "0"
}

@test 'single module: ary is empty when CPAN_FILE is missing' {
    local -a ary searchLines
    local package i
    searchLines=(
        "Module id = Acme::Test"
        "Some other line"
    )
    i=1

    __cpan_single_module

    assert "${#ary}" equals "0"
}

@test 'single module: escapes colons in module name' {
    local -a ary searchLines
    local package i
    searchLines=(
        "Module id = Foo::Bar::Baz"
        "    CPAN_FILE  F/FO/FOO/Foo-Bar-Baz-1.0.tar.gz"
    )
    i=1

    __cpan_single_module

    # colons in Foo::Bar::Baz should be escaped
    assert "$ary[1]" same_as 'Foo\:\:Bar\:\:Baz:F/FO/FOO/Foo-Bar-Baz-1.0.tar.gz'
}

@test 'single module: starts parsing from given index i' {
    local -a ary searchLines
    local package i
    searchLines=(
        "Garbage line 1"
        "Garbage line 2"
        "Module id = Start::Here"
        "    CPAN_FILE  S/ST/START/Start-Here-0.1.tar.gz"
    )
    i=3

    __cpan_single_module

    assert "$ary[1]" same_as 'Start\:\:Here:S/ST/START/Start-Here-0.1.tar.gz'
}

# ── __cpan_multiple_modules parsing ──────────────────────────

@test 'multiple modules: parses Module < lines' {
    local -a searchLines
    local package i
    local PREFIX="Te"
    searchLines=(
        "Module < Acme::Test   A/AU/AUTHOR/Acme-Test-0.01.tar.gz"
        "Module < Acme::Test2  A/AU/AUTHOR/Acme-Test2-0.02.tar.gz"
        "2 items found"
    )
    i=1

    # capture what _store_cache receives
    local -a stored_ary
    function _store_cache() { stored_ary=("${(@P)2}") ; }

    __cpan_multiple_modules

    assert "${#stored_ary}" equals "2"
}

@test 'multiple modules: correctly formats name:tarball pairs' {
    local -a searchLines
    local package i
    local PREFIX="Te"
    searchLines=(
        "Module < Test::Simple  T/TE/TEST/Test-Simple-1.0.tar.gz"
    )
    i=1

    local -a stored_ary
    function _store_cache() { stored_ary=("${(@P)2}") ; }

    __cpan_multiple_modules

    assert "$stored_ary[1]" same_as 'Test\:\:Simple:T/TE/TEST/Test-Simple-1.0.tar.gz'
}

@test 'multiple modules: empty result for non-matching lines' {
    local -a searchLines
    local package i
    local PREFIX="Te"
    searchLines=(
        "No modules found"
        "Try a different search"
    )
    i=1

    local store_called=0
    function _store_cache() { store_called=1 ; }

    __cpan_multiple_modules

    assert "$store_called" equals "0"
}

@test 'multiple modules: uses cache when available' {
    local -a searchLines
    local package i
    local PREFIX="cached"
    searchLines=(
        "Module < Should::Not::Parse  X/XX/XXX/Should-Not-Parse-0.1.tar.gz"
    )
    i=1

    local store_called=0
    # simulate cache hit: _retrieve_cache succeeds
    function _retrieve_cache() { return 0 ; }
    function _store_cache() { store_called=1 ; }

    __cpan_multiple_modules

    # _store_cache should NOT be called when cache hit
    assert "$store_called" equals "0"
}

@test 'multiple modules: cache key includes PREFIX' {
    local -a tmp_ary searchLines
    local package i
    local PREFIX="mymod"
    local stored_cache_key=""
    searchLines=(
        "Module < My::Mod  M/MY/MYMOD/My-Mod-1.0.tar.gz"
    )
    i=1

    function _store_cache() { stored_cache_key="$1" ; }

    __cpan_multiple_modules

    assert "$stored_cache_key" same_as "cpan_mymod_cache"
}

# ── __cpan_modules routing ───────────────────────────────────

@test 'modules: single module line detected by routing pattern' {
    local line="Module id = Acme::Foo"
    local matched=""
    if [[ $line == (#b)(Module[[:space:]]##id[[:space:]]##=[[:space:]]##)([^[:space:]]##)* ]]; then
        matched="single"
    elif [[ $line == (#b)(Module[[:space:]]##\<[[:space:]]##)([^[:space:]]##)[[:space:]]##([^[:space:]]##)* ]]; then
        matched="multiple"
    fi
    assert "$matched" same_as "single"
}

@test 'modules: multiple module line detected by routing pattern' {
    local line="Module < Acme::Foo  A/AC/ACME/Acme-Foo-1.0.tar.gz"
    local matched=""
    if [[ $line == (#b)(Module[[:space:]]##id[[:space:]]##=[[:space:]]##)([^[:space:]]##)* ]]; then
        matched="single"
    elif [[ $line == (#b)(Module[[:space:]]##\<[[:space:]]##)([^[:space:]]##)[[:space:]]##([^[:space:]]##)* ]]; then
        matched="multiple"
    fi
    assert "$matched" same_as "multiple"
}

@test 'modules: non-module line not matched by routing patterns' {
    local line="Nothing useful here"
    local matched="none"
    if [[ $line == (#b)(Module[[:space:]]##id[[:space:]]##=[[:space:]]##)([^[:space:]]##)* ]]; then
        matched="single"
    elif [[ $line == (#b)(Module[[:space:]]##\<[[:space:]]##)([^[:space:]]##)[[:space:]]##([^[:space:]]##)* ]]; then
        matched="multiple"
    fi
    assert "$matched" same_as "none"
}

# ── pattern matching ─────────────────────────────────────────

@test 'single module id pattern matches with extra whitespace' {
    local line="Module   id   =   Extra::Spaces"
    if [[ $line == (#b)(Module[[:space:]]##id[[:space:]]##=[[:space:]]##)([^[:space:]]##)* ]]; then
        assert "${match[2]}" same_as "Extra::Spaces"
    else
        assert 1 equals 0 "Pattern should have matched"
    fi
}

@test 'multiple module pattern matches standard format' {
    local line="Module < Test::More  T/TE/TEST/Test-More-1.0.tar.gz"
    if [[ $line == (#b)(Module[[:space:]]##\<[[:space:]]##)([^[:space:]]##)[[:space:]]##([^[:space:]]##)* ]]; then
        assert "${match[2]}" same_as "Test::More"
        assert "${match[3]}" same_as "T/TE/TEST/Test-More-1.0.tar.gz"
    else
        assert 1 equals 0 "Pattern should have matched"
    fi
}

@test 'CPAN_FILE pattern matches with leading spaces' {
    local line="    CPAN_FILE   A/AU/AUTHOR/Dist-0.01.tar.gz"
    if [[ $line == (#b)([[:space:]]##CPAN_FILE[[:space:]]##)([^[:space:]]##)* ]]; then
        assert "${match[2]}" same_as "A/AU/AUTHOR/Dist-0.01.tar.gz"
    else
        assert 1 equals 0 "Pattern should have matched"
    fi
}

@test 'single module id pattern does not match multiple module format' {
    local line="Module < Test::More  T/TE/TEST/Test-More-1.0.tar.gz"
    if [[ $line == (#b)(Module[[:space:]]##id[[:space:]]##=[[:space:]]##)([^[:space:]]##)* ]]; then
        assert 1 equals 0 "Pattern should NOT have matched"
    else
        assert 1 equals 1
    fi
}

# ── colon escaping ───────────────────────────────────────────

@test 'colon escaping: single colon pair' {
    local val="Foo::Bar"
    val="${val//:/\\:}"
    assert "$val" same_as 'Foo\:\:Bar'
}

@test 'colon escaping: multiple colon pairs' {
    local val="A::B::C::D"
    val="${val//:/\\:}"
    assert "$val" same_as 'A\:\:B\:\:C\:\:D'
}

@test 'colon escaping: no colons unchanged' {
    local val="NoColons"
    val="${val//:/\\:}"
    assert "$val" same_as "NoColons"
}

# ── _cpan completion script ─────────────────────────────────

@test '_cpan has compdef header' {
    run head -1 "$pluginDir/src/_cpan"
    assert $output contains "#compdef cpan"
}

@test '_cpan contains all expected short flags' {
    local flags=(-a -A -c -C -D -f -F -g -G -h -i -I -j -J -l -L -m -M -n -O -p -P -r -s -t -T -u -v -V -w -x -X)
    local content
    content="$(<"$pluginDir/src/_cpan")"
    local flag
    for flag in "${flags[@]}"; do
        if [[ "$content" != *"'${flag}["* ]]; then
            assert 1 equals 0 "Missing flag $flag in _cpan"
            return
        fi
    done
    assert 1 equals 1
}

@test '_cpan references ZPWR_CPAN_MIN_PREFIX' {
    run grep -c 'ZPWR_CPAN_MIN_PREFIX' "$pluginDir/src/_cpan"
    assert $output same_as "1"
}

@test '_cpan references __cpan_modules' {
    run grep -c '__cpan_modules' "$pluginDir/src/_cpan"
    assert $output same_as "1"
}

# ── _cpanm completion script ────────────────────────────────

@test '_cpanm has compdef header' {
    run head -1 "$pluginDir/src/_cpanm"
    assert $output contains "#compdef cpanm"
}

@test '_cpanm contains key long flags' {
    local flags=(--install --self-upgrade --info --installdeps --look --help --version --force --notest --sudo --verbose --quiet --mirror --reinstall --interactive --scandeps)
    local content
    content="$(<"$pluginDir/src/_cpanm")"
    local flag
    for flag in "${flags[@]}"; do
        if [[ "$content" != *"${flag}"* ]]; then
            assert 1 equals 0 "Missing flag $flag in _cpanm"
            return
        fi
    done
    assert 1 equals 1
}

@test '_cpanm references ZPWR_CPAN_MIN_PREFIX' {
    run grep -c 'ZPWR_CPAN_MIN_PREFIX' "$pluginDir/src/_cpanm"
    assert $output same_as "1"
}

@test '_cpanm references __cpan_modules' {
    run grep -c '__cpan_modules' "$pluginDir/src/_cpanm"
    assert $output same_as "1"
}

@test '_cpanm supports tarball file extensions' {
    local content
    content="$(<"$pluginDir/src/_cpanm")"
    assert "$content" contains "tar.gz"
    assert "$content" contains "tgz"
    assert "$content" contains "tar.bz2"
    assert "$content" contains "zip"
}

@test '_cpan supports tarball file extensions' {
    local content
    content="$(<"$pluginDir/src/_cpan")"
    assert "$content" contains "tar.gz"
    assert "$content" contains "tgz"
    assert "$content" contains "tar.bz2"
    assert "$content" contains "zip"
}
