#!/bin/bash

OPENMONERO_BRANCH="master"

# Check for presence of monero code
if [ ! -d "openmonero" ] || [ ! -e "openmonero/.git" ]; then

    # Check out monero code
    echo "Openmonero tree not found in $PWD - cloning from github..."
    git clone -b $OPENMONERO_BRANCH --recursive https://github.com/moneroexamples/openmonero.git
    pushd openmonero > /dev/null 2>&1
    git branch --set-upstream-to=origin/$OPENMONERO_BRANCH $OPENMONERO_BRANCH
    popd > /dev/null 2>&1
fi

# Reset monero code to HEAD
pushd openmonero > /dev/null 2>&1
git checkout -b $OPENMONERO_BRANCH
git reset HEAD --hard
git pull -t
popd > /dev/null 2>&1

# Apply patches / whole files to the monero codebase
pushd patches > /dev/null 2>&1
echo "Applying patches to Openmonero codebase:"
find * -type f | while read line ; do
    echo -n -e "\t"
    if [[ $line =~ ".git/" ]]; then
        continue
    elif [[ $line =~ "^README.md$" ]]; then
        continue
    fi
    if [[ ${line: -6} == ".patch" ]]; then
        patchfile=$line
        filename=${patchfile//\.patch/}
        dstfilename="`dirname $PWD`/openmonero/$filename"
        #echo "Applying patch file $patchfile for target $dstfilename ...";
        patch -p0 -N $dstfilename < $patchfile
    else
        dstfilename="../openmonero/$line"
	foldername=${line%/*}
        echo "Copying file $line to $dstfilename ...";
	if [[ ! -d "../openmonero/$foldername" ]]; then
	    mkdir -p "../openmonero/$foldername"
	fi
        cp $line $dstfilename
    fi
done
popd > /dev/null 2>&1

export USE_SINGLE_BUILDDIR=1

echo "Compiling patched openmonero code..."
pushd openmonero > /dev/null 2>&1
mkdir build
pushd build > /dev/null 2>&1
cmake .. -DMONERO_DIR=~/haven-protocol/monero -DMONERO_BUILD_DIR=~/haven-protocol/monero/
make $@

popd > /dev/null 2>&1
echo "Done."
