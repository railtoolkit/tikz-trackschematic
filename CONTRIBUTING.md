# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue,
email, or any other method with the owners of this repository before making a change. 

Please note we have a code of conduct, please follow it in all your interactions with the project.

# Enhancing and developing the tikz-trackschematic library

1. The tikz-trackschematic should be regularly installed via TeX Live to modify the library. The distributed package comes with a development switch.
2. Run the build script with `sudo ./build.sh --install-dev`. This will soft link the local files out of src folder into your TeX Live installation.
3. The TeX command `\usepackage[dev]{tikz-trackschematic}` will load the linked src folder instead of the distributed package from TeX Live.
4. After implementing your modification run `./build.sh --test` to check for any breaking changes.

# Pull Request Process

1. Ensure any install or build dependencies are removed before the end of the layer when doing a 
   build.
2. Update the CHANGELOG.md with details of changes to the interface, this includes new environment 
   variables, exposed ports, useful file locations and container parameters.
3. The versioning scheme we use is [SemVer](http://semver.org/). Increase the version numbers in the following files to the new version that this Pull Request would represent:
    1. CHANGELOG.md
    2. doc/versionhistory.tex
    3. CITATION.cff
4. You may merge the Pull Request in once you have the sign-off of two other developers, or if you 
   do not have permission to do that, you may request the second reviewer to merge it for you.
5. The following versioning steps will be taken care of by the maintainer:
    1. git repo with tag
    2. sync Overleaf project
