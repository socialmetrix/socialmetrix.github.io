---
layout: post
title: Code Versioning and Branch Model
tags: [git, semver, gitflow]
author: arjones
---

This is our vision how we think code should be versioned and branches maintained, we would like to bring this to discussion and push this recommendation as further as possible.

These recommendations are heavily inspired on [Git Flow](http://nvie.com/posts/a-successful-git-branching-model/) and [Semantic Versioning v2.0.0](http://semver.org/spec/v2.0.0.html)

We believe that combining both technics will achieve a simple and yet powerful model to understand software version, publishing and usage


___
## Defining Initial Version

A package version is define as **PACKAGE_NAME-MAJOR.MINOR.PATCH**  

The initial version of any new software **MUST BE** `0.1.0`

The version **MUST BE** increased (bumped) as follows: 

### * When you make incompatible API changes: 

Increase **MAJOR**, reset **MINOR** and **PATCH**.

		1.13.56 --> 2.0.0


### * When you add functionality in a backwards-compatible manner: 

Increase **MINOR**, reset **PATCH**

		1.13.56 --> 1.14.0


### * When you make bug fixes: 

Increase **PATCH**

		1.13.56 --> 1.13.57


___
## Branching Model

### Ground rules about branchs:

* **master**: Never commit to this branch. It must contains only the releases.
* **develop**: Never commit to this branch. It contains the team tree.
* **feature**: This is your working branch, all your NEW work comes here.
* **hotfix**: This is your working branch for fixing, all your BUG FIX comes here.
* **support**: NOT USED

### PREPARATION

Install git-flow package:

	$ apt-get update && apt-get upgrade
	$ apt-get install git-flow

### Using git-flow

1. Initiate your git-flow repository with `git flow init`:   

  Any repository must be initiate even those that already have `git` and have been used by another `git flow` user, `git flow` is a repository and machine configuration.

1. Use standards answers for all branches:

		smx:~/Projects/tardis$ git flow init
		Initialized empty Git repository in /Users/arjones/Projects/tardis/.git/
		No branches exist yet. Base branches must be created now.
		Branch name for production releases: [master]
		Branch name for "next release" development: [develop]  
    
		How to name your supporting branch prefixes?
		Feature branches? [feature/]
		Release branches? [release/]
		Hotfix branches? [hotfix/]
		Support branches? [support/]
		Version tag prefix? []

1. To initiate a new project, create a feature branch:

		smx:~/Projects/tardis (develop)$ git flow feature start skeleton
		Switched to a new branch 'feature/skeleton'

		Summary of actions:
		- A new branch 'feature/skeleton' was created, based on 'develop'
		- You are now on branch 'feature/skeleton'

		Now, start committing on your feature. When done, use:
				git flow feature finish skeleton
		 

1. Work as usual, make frequent commits
1. When you're done with this feature, ie: all tests green, you can finish this feature:

		smx:~/Projects/tardis (feature/skeleton)$ git flow feature finish skeleton
		Switched to branch 'develop'
		Updating ea27d78..4154296
		Fast-forward
		 README.md      | 0
		 SuperCode.java | 0
		 2 files changed, 0 insertions(+), 0 deletions(-)
		 create mode 100644 README.md
		 create mode 100644 SuperCode.java
		Deleted branch feature/skeleton (was 4154296).

		Summary of actions:
		- The feature branch 'feature/skeleton' was merged into 'develop'
		- Feature branch 'feature/skeleton' has been removed
		- You are now on branch 'develop'

1. You can go back and forward creating features because they all will converge to branch `develop`.

1. Once you're ready for your first release, begin your processo of `git flow release`:

		smx:~/Projects/tardis (develop)$ git flow release start 0.1.0
		Switched to a new branch 'release/0.1.0'

		Summary of actions:
		- A new branch 'release/0.1.0' was created, based on 'develop'
		- You are now on branch 'release/0.1.0'

		Follow-up actions:
		- Bump the version number now!
		- Start committing last-minute fixes in preparing your release
		- When done, run:
				git flow release finish '0.1.0'

1. Create/Increase the version on your package definition:

  ```xml
  --- pom.xml ---
  ...
  <groupId>io.smx</groupId>
  <artifactId>tardis</artifactId>
  <version>0.1.0</version>
  <name>Doctor Who Tardis for Java</name>
  <packaging>jar</packaging>
  ...
  --- /pom.xml ---
  ```

1. Commit your changes on package version, as recommendation an standard message would be `"Release 0.1.0"`:

		smx:~/Projects/tardis (release/0.1.0 +)$ git commit -m"Release 0.1.0"		

1. Once you're done finish your release with `git flow release`:  
You will be asked to include a tag and a comment, in both cases use the target version.

		smx:~/Projects/tardis (release/0.1.0)$ git flow release finish 0.1.0
		Switched to branch 'master'
		Merge made by the 'recursive' strategy.
		 README.md      |   0
		 SuperCode.java |   0
		 pom.xml        | 4 ++++
		 3 files changed, 4 insertions(+)
		 create mode 100644 README.md
		 create mode 100644 SuperCode.java
		 create mode 100644 pom.xml
		Switched to branch 'develop'
		Merge made by the 'recursive' strategy.
		 pom.xml | 224 ++++
		 1 file changed, 224 insertions(+)
		 create mode 100644 pom.xml
		Deleted branch release/0.1.0 (was 21c9ce0).

		Summary of actions:
		- Latest objects have been fetched from 'origin'
		- Release branch has been merged into 'master'
		- The release was tagged '0.1.0'
		- Release branch has been back-merged into 'develop'
		- Release branch 'release/0.1.0' has been deleted

1. Now you can push to `origin` both `develop` and `master` with the correct tags:

		smx:~/Projects/tardis (develop)$ git push --tags origin develop
		Counting objects: 11, done.
		Delta compression using up to 4 threads.
		Compressing objects: 100% (9/9), done.
		Writing objects: 100% (11/11), 2.08 KiB | 0 bytes/s, done.
		Total 11 (delta 4), reused 0 (delta 0)
		To git@github.com:arjones/tardis.git
		 * [new branch]      develop -> develop
		 * [new tag]         0.1.0 -> 0.1.0
 
		smx:~/Projects/tardis (master)$ git push --tags origin master
		Total 0 (delta 0), reused 0 (delta 0)
		To git@github.com:arjones/tardis.git
		* [new branch]      master -> master

1. You'll notice `master` is tagged with correct version

  ![gitk branches view](/img/posts/gitk-1.png)

1. When you have to a bug fix, start it as `git flow hotfix`:  
Don't forget to bump the **PATCH** version

		smx:~/Projects/tardis (develop)$ git flow hotfix start 0.1.1
		Switched to a new branch 'hotfix/0.1.1'

		Summary of actions:
		- A new branch 'hotfix/0.1.1' was created, based on 'master'
		- You are now on branch 'hotfix/0.1.1'

		Follow-up actions:
		- Bump the version number now!
		- Start committing your hot fixes
		- When done, run:
		     git flow hotfix finish '0.1.1'

1. Fix your code, and finish your hotfix:
 
		 smx:~/Projects/tardis (hotfix/0.1.1)$ git flow hotfix finish 0.1.1
		 Switched to branch 'master'
		 Merge made by the 'recursive' strategy.
		  SuperCode.java | 1 +
		  1 file changed, 1 insertion(+)
		 Switched to branch 'develop'
		 Merge made by the 'recursive' strategy.
		  SuperCode.java | 1 +
		  1 file changed, 1 insertion(+)
		 Deleted branch hotfix/0.1.1 (was 94fe39b).

		 Summary of actions:
		 - Latest objects have been fetched from 'origin'
		 - Hotfix branch has been merged into 'master'
		 - The hotfix was tagged '0.1.1'
		 - Hotfix branch has been back-merged into 'develop'
		 - Hotfix branch 'hotfix/0.1.1' has been deleted
 
1. Now you can push `master` to `origin` again (there is no release process as in feature release):

		smx:~/Projects/tardis (develop)$ git checkout master
		Switched to branch 'master'
		smx:~/Projects/tardis (master)$ git push --tags origin master
		Counting objects: 7, done.
		Delta compression using up to 4 threads.
		Compressing objects: 100% (4/4), done.
		Writing objects: 100% (5/5), 562 bytes | 0 bytes/s, done.
		Total 5 (delta 1), reused 0 (delta 0)
		To git@github.com:arjones/tardis.git
		   4879dcd..c91a8bd  master -> master
		 * [new tag]         0.1.1 -> 0.1.1

1. Checking `master` branch you'll find a clean and nice branch only with release tags:

  ![master view with gitk](/img/posts/gitk-2.png)

1. THE END

## What do you think?

We would love to hear your opinion and how we can make it better. How do you work? Does it seems to be much overhead?