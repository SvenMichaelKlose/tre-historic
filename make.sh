#!/bin/sh

set -e

echo "Welcome to tré!"

git rev-parse --short=8 HEAD >environment/_git-revision
echo "Git revision is" `cat environment/_git-revision`
date >environment/_build-date
mkdir -p compiled

ARGS="$2 $3 $4 $5 $6 $7 $8 $9"

SBCL="sbcl --noinform"
TRE="./tre"
BINDIR="/usr/local/bin/"

SHCONFIG=`eval echo ~/.tre.sh`
if [ -e $SHCONFIG ]; then
    . $SHCONFIG
fi

clean_example_projects ()
{
	echo "Cleaning examples (requires root privileges to remove docker containers)…"
	sudo rm -rvf examples/project-js/compiled
	sudo rm -rvf examples/project-php/compiled
	sudo rm -rvf examples/project-js-php/compiled
}

clean ()
{
	echo "Cleaning…"
	rm -rvf compiled
	rm -vf *.core environment/transpiler/targets/c/native/$COMPILED_ENV image files.lisp
    rm -vf environment/_current-revision
    rm -vf environment/_build-date
	rm -vf log-jstests.lisp log-phptests.lisp log-make.lisp
    clean_example_projects
	echo "Checking out last working 'boot-common.lisp'…"
    git checkout -- boot-common.lisp
}

install_it ()
{
    sudo mkdir -p /usr/local/lib/tre
    echo "Installing SBCL image to '/usr/local/lib/tre/image'…"
    sudo cp -v image /usr/local/lib/tre/
    echo "Installing environment to '/usr/local/lib/tre/environment/'…"
    sudo cp -rv environment modules /usr/local/lib/tre/
    echo "Installing 'tre' to '$BINDIR'…"
	sudo cp tre $BINDIR
}

case $1 in
sbcl-image)
    echo "Booting SBCL image with 'boot-common.lisp'…"
    $SBCL --load boot-common.lisp --eval '(tre:dump-system "image")' --quit
	;;

genboot)
    echo "Compiling new 'boot-common.lisp'…"
    echo "(quit)" | $SBCL --core image makefiles/boot-common-lisp.lisp
	;;

reset)
    echo "Resetting boot code from repository…"
    git checkout -- boot-common.lisp
    sed -e s/QUASIQUOTE/UNQUOTE/g <boot-common.lisp >newboot.lisp
    mv newboot.lisp boot-common.lisp
	;;

boot)
    ./make.sh reset
    ./make.sh sbcl-image
    ./make.sh genboot
    ./make.sh sbcl-image
	;;

phptests)
    echo "PHP target tests…"
    echo "(compile-tests *php-transpiler*)" | $TRE tests/toplevel.lisp
    php compiled/test.php | tee log-phptests.lisp
    cmp tests/php.correct-output log-phptests.lisp || (diff tests/php.correct-output log-phptests.lisp; exit 1)
    for i in compiled/unit*.php; do printf "Running PHP unit test $i\n"; php $i; done
	;;

jstests)
    echo "JS target tests…"
    echo "(compile-tests *js-transpiler*)" | $TRE tests/toplevel.lisp
    node compiled/test.js | tee log-jstests.lisp
    #$BROWSER compiled/test.html
    cmp tests/js.correct-output log-jstests.lisp || (diff tests/js.correct-output log-jstests.lisp; exit 1)
    for i in compiled/unit*.js; do printf "Running JS unit test $i\n"; node $i; done
    echo "JS target tests passed in node.js."
	;;

updatetests)
    echo "(compile-tests *php-transpiler*)" | $TRE tests/toplevel.lisp
    echo "(compile-tests *js-transpiler*)" | $TRE tests/toplevel.lisp
    echo "Updating PHP target test data…"
    php compiled/test.php >tests/php.correct-output
    echo "Updating JS target test data (node.js only)…"
    node compiled/test.js >tests/js.correct-output || node compiled/test.js >tests/js.correct-output
    ;;

tests)
    echo "Making tests…"
	./make.sh phptests
	./make.sh jstests
	;;

nodeconsole)
    echo "Making defunct 'nodeconsole'…"
    $TRE makefiles/nodeconsole.lisp
	;;

webconsole)
    echo "Making defunct 'webconsole'…"
    $TRE makefiles/webconsole.lisp
	;;

examples)
    echo "Making directory 'examples'…"
    $TRE examples/make-standard-js.lisp
    $TRE examples/make-standard-node.lisp
    $TRE examples/make-standard-php.lisp
    $TRE examples/make-coreless-js.lisp
    echo "Making compiler dump for BUTLAST in examples/hello-world.lisp…"
#    $TRE examples/make-compiler-dumps-for-butlast.lisp > compiled/compiler-dumps-for-butlast.lisp
#   $TRE examples/make-obfuscated.lisp # TODO: Fix setting the current *PACKAGE*.
    ;;

all)
    echo "Making 'all'…"
    ./make.sh boot
    ./make.sh install
    ./make.sh tests
    ./make.sh examples
    echo
    echo "Successfully built target 'all'."
    ;;

projects)
    clean_example_projects
    cd examples/project-php && ./make.sh && cd -
    cd examples/project-js && ./make.sh && cd -
    cd examples/project-js-php && ./make.sh && cd -
    ;;

release)
    echo "Making release. Have your TRE_PATH set!" | tee log-make.lisp
    ./make.sh clean
    ./make.sh all
    ./make.sh projects
    echo "Release tests done." >>log-make.lisp
	;;

install)
	install_it
	;;

clean)
	clean
	;;
*)
	echo "Usage: make.sh [target]"
    echo ""
	echo "Targets:"
	echo "  genboot       Generate CL code for target 'sbcl-image'."
	echo "  reset         Check out boot-common.lisp from repository."
	echo "                (E.g. when 'genboot' went wrong.)"
	echo "  sbcl-image    Load environment from scratch."
	echo "  boot          Make 'sbcl-image', 'genboot' then 'sbcl-image' again."
    echo "  install       Install executable and environment image made"
    echo "                by 'sbcl-image' or 'boot',"
    echo "  clean         Remove built files, except 'genboot'."
    echo ""
	echo "  tests         Run tests defined in the environment."
    echo "  jstests       Only do 'tests' with Chromium browser and node.js."
    echo "  phptests      Only do 'tests' with command-line PHP."
    echo ""
    echo "  examples      Compile everything in directory 'examples'."
    echo "  all           Compile everything listed until here."
    echo "  projects      Make examples/project*."
    echo ""
    echo "  nodeconsole   Make node.js REPL. (defunct)"
    echo "  webconsole    Make web browser REPL. (defunct)"
    echo ""
    echo "  release       Pass this before initiating git pull requests."
    echo "  updatetests   Generate new reference files from current test."

    ;;
esac
