#!/usr/bin/env sh

repo='ONSdigital/git-diff-check'
binary='pre-commit'

get_latest_release() { # From https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# Fetch the most recent release number from github
release_version=$(get_latest_release ${repo})
binary="${binary}_${release_version}"

if [[ "$OSTYPE" == "darwin"* ]]; then
  binary="${binary}_darwin-amd64"
  target=${HOME}/.githooks
else
  echo "OS '${OSTYPE}' not currently supported by installer - please refer to manual instructions in the README."
  exit 0
fi

release="https://github.com/${repo}/releases/download/${release_version}/${binary}"

# Create the target location if it doesn't already exist
[ ! -d ${target} ] &&
  {
    echo "Creating global hooks folder at ${target}";
    mkdir -p ${target}
  }

# Check if we're up to date
echo "Check for previous versions ..."
[ -f ${target}/pre-commit ] &&
  {
    existing="$(${target}/pre-commit --version)"
    echo "-- found existing version ${existing}"
    [ "${existing}" = "$release_version" ] &&
      {
        echo "-- already up to date!"
        exit 0
      }
    echo "-- new version available ${release_version}"
  }

# Fetch the tool
echo "Fetching Git Diff precommit hook ${release_version} ..."
echo "-- from ${release} ..."
curl -L --progress-bar -f ${release} -o "${target}/pre-commit"

# Check whether cURL was successful
[ $? != 0 ] &&
  {
    echo "Oops, something went wrong. Couldn't fetch!"
    exit 1
  }

chmod +x "${target}/pre-commit"

# Update the git config
echo "Updating git config ..."
git config --global core.hooksPath ${target}

echo "Add done!"
