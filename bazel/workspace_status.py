#!/usr/bin/env python3
import os
import plistlib
import re
import sys
import shutil
import subprocess
from copy import copy
import urllib.request
from typing import Sequence

env = copy(os.environ)

def git(*args: Sequence[str], git_binary_path: str = shutil.which("git")) -> str:
    git_command_list = (git_binary_path,) + args

    return subprocess_run(git_command_list).strip()


def subprocess_run(command_args) -> str:
    pipes = subprocess.Popen(command_args,
                             stdout=subprocess.PIPE,
                             env=env)
    std_out, std_err = pipes.communicate()

    return "" if std_out is None else std_out.decode("utf-8")

def print_buildbuddy_workspace_metadata():
    ''' Prints BuildBuddy specific metadata values

    These are all read by BuildBuddy and drive various features.

    Docs: https://www.buildbuddy.io/docs/guide-metadata/
    Example: https://github.com/buildbuddy-io/buildbuddy/blob/master/workspace_status.sh
    '''

    # Repository (i.e. https://github.com/tinyspeck/slack-objc)
    repo_url = git("config", "--get", "remote.origin.url")
    print("REPO_URL {}".format(repo_url))

    # Git SHA
    commit_sha = git("rev-parse", "HEAD")
    print("COMMIT_SHA {}".format(commit_sha))

    # Branch — Use CI environment as precedent, to help with detached HEAD on CI
    git_branch = env.get("BUILDKITE_BRANCH", None)
    if not git_branch:
        git_branch = git("rev-parse", "--abbrev-ref", "HEAD")
    print("GIT_BRANCH {}".format(git_branch))

    # Prints MODIFIED or CLEAN if there are uncommitted changes
    diff_index = git("diff-index", "HEAD")
    if diff_index:
        git_tree_status = "MODIFIED"
    else:
        git_tree_status = "CLEAN"
    print("GIT_TREE_STATUS {}".format(git_tree_status))

print_buildbuddy_workspace_metadata()
