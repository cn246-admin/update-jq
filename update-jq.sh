#!/bin/sh

# Description: Download, verify and install jq binary on Linux and Mac
# Author: Chuck Nemeth
# https://jqlang.github.io/jq/

#######################
# VARIABLES
#######################
bin_dir="$HOME/.local/bin"
man_dir="$HOME/.local/share/man/man1"
tmp_dir="$(mktemp -d /tmp/jq.XXXXXXXX)"

if command -v jq >/dev/null; then
  jq_installed_version="$(jq --version)"
else
  jq_installed_version="Not Installed"
fi

jq_version_number="$(curl -Ls https://api.github.com/repos/jqlang/jq/releases/latest | \
                     awk -F': ' '/tag_name/ { gsub(/\"|jq-|\,/,"",$2); print $2 }')"
jq_version="jq-${jq_version_number}"
jq_url="https://github.com/jqlang/jq/releases/download/${jq_version}"
jq_man="jq.1"

sum_file="sha256sum.txt"


#######################
# FUNCTIONS
#######################
# Define clean_up function
clean_up () {
  printf '%s' "Would you like to delete the tmp_dir and the downloaded files? (Yy/Nn) "
  read -r choice
  case "${choice}" in
    [yY]|[yY]es)
      printf '%s\n' "Cleaning up install files"
      cd && rm -rf "${tmp_dir}"
      exit "${1}"
      ;;
    *)
      printf '%s\n' "Exiting without deleting files from ${tmp_dir}"
      exit "${1}"
      ;;
  esac
}

# green output
code_grn () {
  tput setaf 2
  printf '%s\n' "${1}"
  tput sgr0
}

# red output
code_red () {
  tput setaf 1
  printf '%s\n' "${1}"
  tput sgr0
}

# yellow output
code_yel () {
  tput setaf 3
  printf '%s\n' "${1}"
  tput sgr0
}


#######################
# OS CHECK
#######################
case "$(uname -s)" in
  "Darwin")
      case "$(uname -p)" in
        "arm")
          # Currently no arm releases
          # See: https://github.com/jqlang/jq/issues/2386
          jq_binary="jq-osx-amd64"
          ;;
        *)
          jq_binary="jq-osx-amd64"
          ;;
      esac
    ;;
  "Linux")
    jq_binary="jq-linux64"
    ;;
  *)
    code_red "[ERROR] Unsupported OS. Exiting"
    clean_up 1
esac


#######################
# PATH CHECK
#######################
case :$PATH: in
  *:"${bin_dir}":*)  ;;  # do nothing
  *)
    code_red "[ERROR] ${bin_dir} was not found in \$PATH!"
    code_red "Add ${bin_dir} to PATH or select another directory to install to"
    clean_up 1
    ;;
esac


#######################
# VERSION CHECK
#######################
cd "${tmp_dir}" || exit

if [ "${jq_version}" = "${jq_installed_version}" ]; then
  printf '%s\n' "Installed Verision: ${jq_installed_version}"
  printf '%s\n' "Latest Version: ${jq_version}"
  code_yel "[INFO] Already using latest version. Exiting."
  clean_up 0
else
  printf '%s\n' "Installed Verision: ${jq_installed_version}"
  printf '%s\n' "Latest Version: ${jq_version}"
fi


#######################
# DOWNLOAD
#######################
printf '%s\n' "Downloading the jq binary and verification files"

code_yel "${jq_version}"
code_yel "${jq_url}/${jq_binary}"
code_yel "${jq_url}/${sum_file}"

# Download the things
curl -sL -o "${tmp_dir}/${jq_binary}" "${jq_url}/${jq_binary}"
curl -sL -o "${tmp_dir}/${sum_file}" "${jq_url}/${sum_file}"


#######################
# VERIFY
#######################
# Verify shasum
printf '%s\n' "Verifying ${jq_binary}"
sums=$(awk -v var="${jq_binary}" '$0 ~ var { gsub(/ /, "  ", $0); print }' "${sum_file}")
#sums=$(grep "${jq_binary}" "${sum_file}" | sed 's/ /  /g')

if ! echo "${sums}" | shasum -qc; then
  code_red "[ERROR] Problem with checksum!"
  clean_up 1
fi


#######################
# PREPARE
#######################
# Create bin dir if it doesn't exist
if [ ! -d "${bin_dir}" ]; then
  mkdir -p "${bin_dir}"
fi


#######################
# INSTALL
#######################
# Install jq binary
if [ -f "${tmp_dir}/${jq_binary}" ]; then
  mv "${tmp_dir}/${jq_binary}" "${bin_dir}/jq"
  chmod 700 "${bin_dir}/jq"
fi


#######################
# VERSION CHECK
#######################
code_grn "Done!"
code_grn "Installed Version: $(jq --version)"


#######################
# MAN PAGE
#######################
if [ ! -f "${man_dir}/${jq_man}" ]; then
  printf '\n%s\n' "I didn't compile the man page, but installed jq using homebrew and copied it from there"
  printf '%s\n' "brew install jq"
  printf '%s\n' "cp /opt/homebrew/Cellar/jq/${jq_version_number}/share/man/man1/jq.1 ~/.local/share/man/man1"
  printf '%s\n' "brew uninstall jq"
fi


#######################
# CLEAN UP
#######################
clean_up 0

# vim: ft=sh ts=2 sts=2 sw=2 sr et
