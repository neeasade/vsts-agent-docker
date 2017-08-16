#!/bin/sh

image="nathanisom27/vsts-agent-dotnet-docker"
tag="latest"

# only used in launch:
VSTS_ACCOUNT="cpgit"
VSTS_TOKEN=""
VSTS_WORK="/var/vsts"

# verbose do
vdo() {
    echo "$@"
    "$@" || return 1
}

build() {
    # no cache ensures we can do tags like 'latest' and 'dev' without duplicating
    vdo docker build -t "$target" . --no-cache
}

push() {
    vdo docker push "$target" || echo "failed to push -- are you logged in to dockerhub?"
}

launch() {
    if [ -z "$VSTS_TOKEN" ]; then
       echo "launch() needs a PAT token from VSTS."
       exit
    fi

    command="$(echo docker run \
        -e VSTS_ACCOUNT="${VSTS_ACCOUNT}"  \
        -e VSTS_TOKEN="${VSTS_TOKEN}" \
        -e VSTS_WORK="${VSTS_WORK}" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/vsts:/var/vsts)"

    if uname | grep MINGW; then
        # amend paths in git bash
        command="$(echo "$command" | sed 's|/|//|g')"
    fi

    image_id="$(eval "$command" -d $target)"
    docker logs $image_id -f
}

help() {
    echo valid options are: build, push, launch.
}

target="${image}:${tag}"
[ -z "$@" ] && help || "$@"
