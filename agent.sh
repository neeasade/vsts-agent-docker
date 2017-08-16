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

    if agent_running; then
        echo "found running image, attaching to that.."
        logs
        exit
    fi

    command="$(echo docker run \
        -e VSTS_ACCOUNT="${VSTS_ACCOUNT}"  \
        -e VSTS_TOKEN="${VSTS_TOKEN}" \
        -e VSTS_WORK="${VSTS_WORK}" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/vsts:/var/vsts \
        -d $target)"

    if uname | grep MINGW; then
        # amend paths in git bash, ref: https://github.com/moby/moby/issues/12751
        # command="$(echo "$command" | sed 's|/|//|g')"
        # note: don't do the above, hurts path checking in tests.
        echo "this won't work in windows git bash, run the following from CMD:"
        echo "$command"
    else
        eval "$command"
        logs
    fi
}

pull() {
    vdo docker pull $target
}

stop() {
    vdo docker stop $(get_running_id)
}

logs() {
    vdo docker logs $(get_running_id) -f
}

relaunch() {
    stop
    launch
}

agent_running() {
    [ -z "$(get_running_id)" ] && return 1 || return 0
}

get_running_id() {
    docker ps | grep "$target" | awk '{ print $1 }'
}

help() {
    echo valid options are: build, push, launch, logs, relaunch, stop.
}

# allow this to run when symlinked from anywhere with relativeness
cd $(dirname $([ -L $0  ] && readlink -f $0 || echo $0))
cd ubuntu/16.04/civicplus

target="${image}:${tag}"
[ -z "$@" ] && help || "$@"
