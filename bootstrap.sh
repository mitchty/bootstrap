#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
#
# Cause... setting shit up should be easy. And I'm lazy.
#
export script=$(basename "$0")
export dir=$(cd "$(dirname "$0")"; pwd)
export iam=${dir}/${script}
export PATH="${PATH}:${dir}"

export HOMEBREW_BUILD_FROM_SOURCE=yesplease
local_files=${local_files:=yes}
osx_release=$(sw_vers -productVersion | sed -e 's/\.[0-9]\{1\}//2')
brew_home=/usr/local/brew/${osx_release}
iam_user=$(id -u -nr)
iam_group=$(id -g -nr)
brew_bin=${brew_home}/bin
brew_itself=${brew_bin}/brew
export PATH=${brew_bin}:${PATH}
ansible_verbose=${ansible_verbose:=""}
[ "${VERBOSE}" != '' ] && ansible_verbose="-v"

[ -d "/vagrant" ] && sut=true

sut_guard()
{
  # Let local testing in /vagrant work.
  if [ "${sut}" = "true" ]; then
    cd /vagrant
  else
    cd "${base_home}"
  fi
}

xcode_setup()
{
  echo "Making sure that xcode/git will run"
  cmd="sudo xcodebuild -license accept"
  echo "${cmd}"
  ${cmd}
}

homebrew_setup()
{
  # Find out when crap breaks faster...ish
  set -e

  if [ ! -d "${brew_home}" ]; then
    cmd="sudo mkdir -p ${brew_home}"
    echo "${cmd}"
    ${cmd}
  fi

  cmd="sudo chown -R ${iam_user}:${iam_group} ${brew_home}"
  echo "${cmd}"
  ${cmd}

  if [ ! -e "${brew_itself}" ]; then
    xcode_setup

    instfile="${TMPDIR}/brew-install"
    if [ ! -e "${instfile}" ]; then
      echo "Install homebrew for the first time"
      trap 'rm -fr "${instfile}"; exit' INT TERM EXIT
      git clone --depth 1 "https://github.com/Homebrew/homebrew" "${brew_home}"
      trap - INT TERM EXIT
    else
      echo "lock file found ${instfile}"
      exit 2
    fi
    rm -f "${instfile}"
  fi

  export PATH=${brew_bin}:${PATH}

  if [ ! -e "${brew_bin}/git" ]; then
    cmd="brew install -v git --with-brewed-curl"
    echo "${cmd}"
    ${cmd}
  fi
  if [ ! -e "${brew_bin}/ansible" ]; then
    cmd="brew install -v ansible"
    echo "${cmd}"
    ${cmd}
  fi
}

# still a work in progress to be honest.
ansible()
{
  # Allow this sudo to fail if we get prompted or aren't setup
  set +e
  cmd="ansible-playbook ${ansible_verbose} --inventory-file inventory --sudo bootstrap.yml"
  echo "${cmd}"
  ${cmd}
  set -e

  if [ $? != 0 ]; then
    echo "sudo not setup will prompt to do root actions then"
    cmd="ansible-playbook ${ansible_verbose} --ask-sudo-pass --inventory-file inventory --sudo bootstrap.yml"
    echo "${cmd}"
    ${cmd}
  fi

  if [ "${sut}" != "true" ]; then
    all_ansible_plays
  fi
}

all_ansible_plays()
{
  for playbook in osx-user osx-homebrew; do
    ansible_play ${playbook}
  done
}


ansible_play()
{
  playbook="$1"
  cmd="ansible-playbook ${ansible_verbose} --inventory-file inventory ${playbook}.yml"
  echo "${cmd}"
  ${cmd}
}

nix_setup()
{
  sut_guard
  xcode_setup
  set -e
  cwd=$(pwd)
  _tmp="/tmp/nix-setup-$$"
  mkdir ${_tmp}
  cd "${_tmp}"
  curl -O https://nixos.org/nix/install
  sh install
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  dest="${HOME}/src/github.com/NixOS/nixpkgs"
  rm -fr "${dest}"
  git clone --depth 1 https://github.com/NixOS/nixpkgs.git "${dest}"
  cd "${HOME}/.nix-defexpr"
  rm -rf channels
  ln -s "${dest}" nixpkgs
  export NIX_PATH=${dest}:nixpkgs=${dest}
  rm -fr /tmp/nix-setup*
  cd "${cwd}"
}

maybe_nix()
{
 if [ "${SKIP_NIX}" == "" ]; then
      if [ "$(uname)" = "Darwin" ]; then
          nix_setup
      fi
  fi
}

maybe_homebrew()
{
  if [ "${SKIP_HOMEBREW}" == "" ]; then
      if [ "$(uname)" = "Darwin" ]; then
          echo "on osx, going to install homebrew+ansible"
          homebrew_setup
      fi
  fi
}

sut_guard

case $1 in
ansible)
  if [ "$2" != "" ]; then
    ansible_play "$2"
  else
    ansible
  fi
  ;;
homebrew)
  homebrew_setup
  ;;
nix)
  maybe_nix
  ;;
vagrant)
  # Add mitch user and run crap as that user.
  osx_adduser.sh
  sudo su -l mitch -c "$(pwd)/bootstrap.sh nix"
  sudo su -l mitch -c "$(pwd)/bootstrap.sh vagrant-nix"
  ;;
nix-defaults)
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  dest="${HOME}/src/github.com/NixOS/nixpkgs"
  export NIX_PATH=${dest}:nixpkgs=${dest}
  nix-env -iA nixpkgs.emacs24Macport nixpkgs.emacs24Packages.org
  ;;
old)
  maybe_nix
  maybe_homebrew
  ansible
  all_ansible_plays
  echo "${sut}"
  ;;
*)
  ${iam} nix
#  ${iam} nix-basic
  echo "No args given, cowardly exiting"
  ;;
esac
