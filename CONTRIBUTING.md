# Contributing Guidelines
This document contains the KubeNow community contribution guidelines, including what is required before submitting a code change. The document was adapted from the [Contributing to Spark](https://spark.apache.org/contributing.html) document.

Contributing to KubeNow doesn't just mean writing code. Helping new users, testing releases, and improving documentation are also welcome. In fact, proposing significant code changes usually requires first gaining experience and credibility within the community by helping in other ways. This document also describe how to become an effective contributor.

When you contribute to this project, you affirm that the contribution is your original work and that you license the work to the project under the project's open source license. Whether or not you state this explicitly, by submitting any copyrighted material via pull request, email, or other means you agree to license the material under the project's open source license and warrant that you have the legal authority to do so.

## Contributing by Filling an Issue and/or Helping Other Users
User are always welcome to ask questions and/or report some technical difficulties by [filling an issue here](https://github.com/kubenow/KubeNow/issues). A related way to contribute to KubeNow is to help answer user questions. In fact, taking a few minutes to help answering questions is an excellent and visible way to help the community, which also demonstrates your expertise.

## Contributing Documentation Changes
To propose a change to release documentation (that appear under https://kubenow.readthedocs.io/en/latest/?badge=latest), edit the source files in the [related GitHub repository](https://github.com/kubenow/docs), whose README file shows how to build the documentation locally to test your changes. The process to propose a doc change is otherwise the same as the process for proposing code changes below.

## Contributing by Developing New Features and/or Bug Fix
It is always great and exciting knowing that a contributor would like to propose a new features and/or deal with a bug. Ideally, bug reports are accompanied by a proposed code change to fix the bug. This isn’t always possible, as those who discover a bug may not have the experience to fix it. A bug may be reported by creating an issue but without creating a pull request (see further details below).

Bug reports are only useful however if they include enough information to understand, isolate and ideally reproduce the bug. Simply encountering an error does not mean a bug should be reported. Unreproducible bugs, or simple error reports, may be closed.

As mentioned at the beginning, it is of course possible to propose new features as well. These are generally not helpful unless accompanied by detail, such as a design document and/or code change. Feature requests may be rejected, or closed after a long period of inactivity.

In both scenarios when a new functionality or a bug fix would like to be proposed, then we would enthusiasticly recommend the following steps:

1. Before pushing a pull request, always open an issue first. This will allow a technical discussion with the developers which promotes a better support and review process.  
2. Start working either on a separated branch or a fork of the project.
3. If point 1 has led to a positive outcome, then please open a pull request (see below) and wait for it to be reviewed.

### Opening a Pull Request

1. [Fork](https://help.github.com/articles/fork-a-repo/) the Github repository at https://github.com/kubenow/KubeNow if you haven’t already
2. Clone your fork, create a new branch, push commits to the branch
3. Consider whether documentation or tests need to be added or updated as part of the change, and add them as needed
4. [Open a pull request](https://help.github.com/articles/about-pull-requests/) against the master branch
   1. The PR title should be quite a specific title describing the PR itself
   2. If the pull request is still a work in progress, and so is not ready to be merged, but needs to be pushed to Github to facilitate review, then add [skip ci] at the end of the commit's message
   3. Consider identifying committers or other contributors who have worked on the code being changed. Find the file(s) in Github and click "Blame" to see a line-by-line annotation of who changed the code last. You can add @username in the PR description to ping them immediately
5. We do not test pull requests automatically for security issues, but after evaluation an owner will trigger the continous integration for your pull request

### Closing Your Pull Request
* If a change is accepted, it will be merged and the pull request will automatically be closed
* If your pull request is ultimately rejected, please close it promptly
* If a pull request has gotten little or no attention, consider improving the description or the change itself and ping likely reviewers again after a few days. Consider proposing a change that's easier to include, like a smaller and/or less invasive change.
* If it has been reviewed but not taken up after weeks, after soliciting review from the most relevant reviewers, or, has met with neutral reactions, the outcome may be considered a "soft no". It is helpful to withdraw and close the PR in this case.

### Code Style Guide
Please follow the style of the existing codebase:

* For any Terraform files, please make sure to format with `terraform fmt`
* For any Packer file, please make sure to validate with `packer validate` 
* For any shell script, please make sure to validate with [shellcheck](https://github.com/koalaman/shellcheck), and to format with [shfmt](https://github.com/mvdan/sh)
* For any json file, please make sure to format with `python -mjson.too`
* For any yaml file, please make sure to validate with [yamllint](https://github.com/adrienverge/yamllint), using the `.yamllint.yml` configuration
* For any Ansible file please make sure to validate with [ansible-lint](https://github.com/willthames/ansible-lint)

Any violation of the previous policies will fail the CI process.

## Contributing by Reviewing Changes
Changes to KubeNow source code are proposed, reviewed and committed via [Github pull requests](https://github.com/kubenow/KubeNow/pulls) (see above). Anyone can view and comment on active changes here. Reviewing others' changes is a good way to learn how the change process works and gain exposure to activity in various parts of the code. You can help by reviewing the changes and asking questions or pointing out issues – as simple as typos or small issues of style.

### The Review Process
* Other reviewers, including committers, may comment on the changes and suggest modifications. Changes can be added by simply pushing more commits to the same branch.
* Lively, polite, rapid technical debate is encouraged from everyone in the community. The outcome may be a rejection of the entire change.
* Reviewers can indicate that a change looks suitable for merging with a comment such as: "I think this patch looks good". The LGTM convention for indicating the strongest level of technical sign-off on a patch may be used: simply comment with the word "LGTM". It specifically means: "I've looked at this thoroughly and take as much ownership as if I wrote the patch myself". **If you comment LGTM you will be expected to help with bugs or follow-up issues on the patch. Consistent, judicious use of LGTMs is a great way to gain credibility as a reviewer with the broader community.**
* Sometimes, other changes will be merged which conflict with your pull request’s changes. The PR can’t be merged until the conflict is resolved. This can be resolved by, for example, adding a remote to keep up with upstream changes by `git remote add upstream https://github.com/kubenow/KubeNow.git`, running `git fetch upstream` followed by `git rebase upstream/master` and resolving the conflicts by hand, then pushing the result to your branch.
* Try to be responsive to the discussion rather than let days pass between replies

In addition to the above suggestions, reviewers should check code changes carefully and make sure that the PR fullfills the following review criteria:

### POSITIVES
* Has a nice, self-explanatory title
* Fixes the root cause of a bug in existing functionality
* Adds functionality or fixes a problem needed by a large number of users
* Simple, targeted
* Easily tested; has tests
* Reduces complexity and lines of code
* Change has already been discussed and is known to committers (open an issue first otherwise)

### NEGATIVES
* Makes lots of modifications in one "big bang" change
* Adds user-space functionality that does not need to be maintained in KubeNow, but could be hosted externally 
* Adds large dependencies
* Adds a large amount of code

### Merging a Pull Request by an external contributor
When a PR from an external contributor has been submitted, an owner needs to merge the PR following this workflow:

1. Make sure that no encrypted value is manipulated in the PR
2. Fetch the PR: `git fetch origin pull/<ID>/head:pr-<ID>`
3. Checkout the master and pull it: `git checkout master && git pull`
4. Checkout a new test branch from the master: `git checkout -b pr-test-<ID>`
5. Merge the PR in the new test branch: `git merge pr-<ID>`
6. Push the new test branch (so the CI can start):`git push -u origin pr-test-<ID>`
7. Repeat 2,5,6 for new PR commits, if necessary (so they get tested)
8. Merge the original PR if the CI for `pr-test-<ID>` passes

### Merging a Fixes into an Existing Stable Branch (if any)
It is often best practice to keep development of cutting-edge features not embedded into a stable branch, rather in the master. However, just as often hot fixies need to be merged both in the master and in the stable branch. While in the former case this will happen automatically via a related pull requested, in the latter scenario it is necessary to perform a manual merge of any fixes in the stable branch (unless an automated process is in place). Thus this section's goal is to provide a short useful workflow on how to merge any fixes into an existing stable branch:

1. Checkout the master and pull it: `git checkout master && git pull`
2. Checkout the fix branch in order to pull it locally if not present: `git checkout latest-fix-branch`
3. Mve into the stable branch by checking it out: `git checkout existing-stable-branch`
4. Merge the pulled fix branch inside the stable branch `git merge latest-fix-branch`
5. Make sure there are no unsolved conflicts and that the fix's code have been correctly embedded
6. Push the stable branch `git push`
7. Make sure that CI passes for the last push

> **Note:** Regarding step 6, it is important to keep in mind that, based on your local `push.default` behaviour, other commits from other branches may be pushed as well. Therefore, local customised tweakings may be necessary. Last but not least, even when pushing only the stable branch GitHub will still ask you whether a PR needs to be created. Given the scenario, such PR should not be necessary, thus the GitHub message can be ignored.

## Support Channels

Whether you are a user or contributor, official support channels include:

* GitHub issues: https://github.com/kubenow/KubeNow/issues
* Slack: https://kubenow.slack.com

Before opening a new issue or submitting a new pull request, it's helpful to search the project - it's likely that another user has already reported the issue you're facing, or it's a known issue that we're already aware of.

## If in Doubt

If you’re not sure about the right style for something, try to follow the style of the existing codebase. Look at whether there are other examples in the code that use your feature. Nevertheless feel free to ask on the GitHub repository by filling an issue marked by the label of "question".
