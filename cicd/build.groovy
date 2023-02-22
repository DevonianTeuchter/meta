# Build Job : https://128.168.139.253:8443/view/Framework/job/Port-Build/
# This build job will build a https://github.com/ZOSOpenTools/meta compatible project and archive the pax.Z artifact
# This job is configured to clone the meta repo at the outset into the current working directory.
# This job must run on the z/OS zot system
# Inputs: 
#   - PORT_GITHUB_REPO : e.g: https://github.com/ZOSOpenTools/makeport.git
#   - PORT_BRANCH : (default: main)
# Output:
#   - pax.Z artifact is published as a Jenkins artifact
#   - package is copied to /jenkins/build on z/OS zot system

set -e # Fail on error
set -x # Display verbose output

# Jenkins cannot interpret colours
export NO_COLOR=1

# source Jenkins environment variables on zot
. /jenkins/.env

# Add cloned meta dir to PATH
export PATH="$PWD/bin:$PATH"

# Get port name based on git repo
PORT_NAME=$(basename "${PORT_GITHUB_REPO}")
PORT_NAME=${PORT_NAME%%.*}
PORT_NAME=${PORT_NAME%%port}

# Set TMPDIR to a local tmp directory
export TMPDIR="${PWD}/tmp"
mkdir -p "${TMPDIR}"

git clone -b "${PORT_BRANCH}" "${PORT_GITHUB_REPO}" ${PORT_NAME} && cd ${PORT_NAME}

# Always run tests and update dependencies and generate pax file
zopen build -v -b release -u -gp -nosym
