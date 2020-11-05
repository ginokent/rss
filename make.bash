#!/usr/bin/env bash
set -Ee -o pipefail
cd "$(dirname "$0")" || exit 1

# log
export  pipe_debug="exec awk \"{print \\\"\\\\033[00m\$(date +%Y-%m-%dT%H:%M:%S%z) [ debug] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin" &&  debugln () { test "$DEBUG" != true || echo "${*:?"log content"}" | sh -c "${pipe_debug:?}"  1>&2; }
export   pipe_info="exec awk \"{print \\\"\\\\033[34m\$(date +%Y-%m-%dT%H:%M:%S%z) [  info] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin" &&   infoln () { echo "${*:?"log content"}" | sh -c "${pipe_info:?}"   1>&2; }
export     pipe_ok="exec awk \"{print \\\"\\\\033[32m\$(date +%Y-%m-%dT%H:%M:%S%z) [    ok] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin" &&     okln () { echo "${*:?"log content"}" | sh -c "${pipe_ok:?}"     1>&2; }
export pipe_notice="exec awk \"{print \\\"\\\\033[01m\$(date +%Y-%m-%dT%H:%M:%S%z) [notice] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin" && noticeln () { echo "${*:?"log content"}" | sh -c "${pipe_notice:?}" 1>&2; }
export   pipe_warn="exec awk \"{print \\\"\\\\033[33m\$(date +%Y-%m-%dT%H:%M:%S%z) [  warn] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin" &&   warnln () { echo "${*:?"log content"}" | sh -c "${pipe_warn:?}"   1>&2; }
export  pipe_error="exec awk \"{print \\\"\\\\033[31m\$(date +%Y-%m-%dT%H:%M:%S%z) [ error] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin" &&  errorln () { echo "${*:?"log content"}" | sh -c "${pipe_error:?}"  1>&2; }

export apt_update_cmd="last=\$(stat /var/lib/apt/lists/* 2>/dev/null | awk -F\"Change:\" \"/Change:/ {print \\\$2}\" | sort | tail -n 1); [ 43200 -ge \$((\$(date +%s)-\$(date -d\"\${last:=1970-1-1}\" +%s))) ] || command apt update"

# env
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# const
export PROG_NAME=make.bash

# function 1
infoln () { (
  echo "$*" | sh -c "${stderrPipeInfo:?}"
)}
errorln () { (
  echo "$*" | sh -c "${stderrPipeError:?}"
)}
stderr () {(echo "$*" 1>&2)}
commandNotFound () { (
  ! command -v "${1:?"commandNotFound: \$1 as command is required"}" >/dev/null
)}
runCmd () { (
  cmd="${1:?"runCmd: \$1 as commands for bash -c option is required"}"
  infoln "RUN: ${cmd:?}"
  bash -c "${cmd:?}"
)}

outputHelp () { (
  WIDTH=48
  stderr --------------------------------------------------------------------------------
  stderr "$(printf "\033[36m%-${WIDTH:?}s\033[0m%s\n" "TASK" "DOCUMENT")"
  stderr --------------------------------------------------------------------------------
  stderr "$(
    grep -E '^[[:space:]]*task-[^[:space:]]+[[:space:]]*\(\).*{.*## .*$' "$0" |
      awk -F'[[:blank:]]*\\(\\).*{.*##[[:blank:]]*' '{gsub(/.*task-/,""); printf "\033[36m%-'"${WIDTH:?}"'s\033[0m%s\n", $1, $2; }'
      #perl -pe 's|__ENVIRONMENT__|\033[1m'"${ENVIRONMENT:?}"'\033[0m|g; s|__0__|'"$0"'|g; s|\*\*([^\*]+)\*\*|\033[1m$1\033[0m|g;'
  )"
  stderr --------------------------------------------------------------------------------
)}

task-help () {  ## このドキュメントを表示します。
  outputHelp
}

task-generate-status-aws-amazon-com-filtered-rss () {  ## status.aws.amazon.com.filtered.rss を生成します。 ref. https://dev.classmethod.jp/articles/aws-service-status-check/
  #ignore_region_list="af-south-|ap-east-|ap-northeast-|ap-south-|ap-southeast-|ca-central-|eu-central-|eu-east-|eu-north-|eu-south-|eu-west-|me-south-|sa-east-|us-east-|us-west-"  # NOTE(k.ogino): 除外リージョンの雛形
  ignore_region_list="af-south-|ap-east-|ap-northeast-2|ap-northeast-3|ap-south-|ap-southeast-|ca-central-|eu-central-|eu-east-|eu-north-|eu-south-|eu-west-|me-south-|sa-east-|us-east-|us-west-"
  time cat >./status.aws.amazon.com.filtered.rss <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0">
    <head>
        <title>AWS Service Status (filtered)</title>
    </head>
    <body>
        <outline text="AWS Service Status (filtered)" title="AWS Service Status (filtered)">
$(
  curl -fLRSs https://status.aws.amazon.com/ |
    grep -E -o "href=\".*rss/.*.rss\"" |
    grep -E -v "${ignore_region_list:?}" |
    sed '
      s|href="|http://status.aws.amazon.com|;
      s|"$||;
      s|\(http://status.aws.amazon.com/rss/\)\(.*\)\(\.rss\)|            <outline type="rss" text="\2" title="\2" xmlUrl="\1\2\3" htmlUrl="http://status.aws.amazon.com/"/>|;
      s|text="\([^"\]*\)-\(ap-northeast-1\)"|text="\1 (\2)"|;
      s|title="\([^"\]*\)-\(ap-northeast-1\)"|title="\1 (\2)"|;
    ' |
    sort -u
)
        </outline>
    </body>
</opml>
EOF
}

main () { (
  if ! test "${BASH_VERSINFO[0]}" -ge 3; then
    printf '\033[1;31m%s\033[0m\n' "bash 3.x or later is required" 1>&2
    exit 1
  fi

  # 引数がなければ help ドキュメントを表示して正常終了します。
  if [ $# -eq 0 ]; then
    task-help
    exit 0
  fi

  task="${1:?"${PROG_NAME:?}: \$1 as task is required"}"
  shift
  "task-${task:?}" "$@"
)} && main "$@"
