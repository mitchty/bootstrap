#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
export script=$(basename "$0")
export dir=$(cd "$(dirname "$0")"; pwd)
export iam=${dir}/${script}

set -e
PATH="~/.cabal/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"
TMPDIR="/tmp"
export PATH TMPDIR

package=$1
temp=$(mktemp -d -t "cabalsandbox-${package}")
cd ${temp}
cabal sandbox init
cabal install -v "${package}"
cp .cabal-sandbox/bin/* ~/.cabal/bin
cd /
rm -fr ${temp}
