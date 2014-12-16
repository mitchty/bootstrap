#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
#
# Cause... setting shit up should be easy. And I'm lazy.
#
local_files=${local_files:=yes}
osx_release=$(sw_vers -productVersion | sed -e 's/\.[0-9]\{1\}//2')
brew_home=/usr/local/brew/${osx_release}
iam_user=$(id -u -nr)
iam_group=$(id -g -nr)
brew_bin=${brew_home}/bin
brew_itself=${brew_bin}/brew
ansible_verbose=${ansible_verbose:=""}
[ "${VERBOSE}" != '' ] && ansible_verbose="-v"

[ -d "/vagrant" ] && sut=true

sut_guard()
{
  # Let local testing in /vagrant work.
  if [ ${sut} = "true" ]; then
    cd /vagrant
  else
    cd "${base_home}"
  fi
}

export PATH=${brew_bin}:${PATH}

homebrew_setup()
{
  # Find out when crap breaks faster...ish
  set -e

  if [ ! -d ${brew_home} ]; then
    cmd="sudo mkdir -p ${brew_home}"
    echo "${cmd}"
    ${cmd}
  fi

  cmd="sudo chown -R ${iam_user}:${iam_group} ${brew_home}"
  echo "${cmd}"
  ${cmd}

  if [ ! -e ${brew_itself} ]; then
    echo "Making sure that xcode/git will run"
    cmd="sudo xcodebuild -license accept"
    echo "${cmd}"
    ${cmd}

    brew_url="https://raw.githubusercontent.com/Homebrew/install/master/install"
    instfile="${TMPDIR}/brew-install"
    if [ ! -e "${instfile}" ]; then
      echo "Install homebrew for the first time"
      trap 'rm -fr "${instfile}"; exit' INT TERM EXIT
      git clone "https://github.com/Homebrew/homebrew" ${brew_home}
      trap - INT TERM EXIT
    else
      echo "lock file found ${instfile}"
      exit 2
    fi
    rm -f "${instfile}"
  fi

  export PATH=${brew_bin}:${PATH}

  for prep in git ansible; do
    if [ ! -e ${brew_bin}/${prep} ]; then
      cmd="brew install ${prep}"
      echo "${cmd}"
      ${cmd}
    fi
  done
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

 for playbook in osx-user osx-homebrew cabal; do
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
*)
  if [ "$(uname)" = "Darwin" ]; then
    echo "on osx, going to install homebrew+ansible"
    homebrew_setup
  fi
  ansible
  exit $?
  ;;
esac
