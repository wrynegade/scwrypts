_DEPENDENCIES+=()
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh
#####################################################################

PACKAGE_INSTALL_DIR="$HOME/.local/share/source-packages"

#####################################################################

CLONE() {
	cd "$PACKAGE_INSTALL_DIR"
	__STATUS "downloading $NAME"
	git clone "$TARGET" "$NAME" \
		&& __SUCCESS "successfully downloaded '$NAME'" \
		|| __FAIL 1 "failed to download '$NAME'" \
		;
}

PULL() {
	__STATUS "updating '$NAME'"
	cd "$PACKAGE_INSTALL_DIR/$NAME"
	git pull origin $(git rev-parse --abbrev-ref HEAD) \
		&& __SUCCESS "successfully updated '$NAME'" \
		|| __FAIL 1 "failed to update '$NAME'" \
		;
}

#####################################################################

BUILD() {
	cd "$PACKAGE_INSTALL_DIR/$NAME"

	CHECK_MAKE    && { MAKE    && return 0 || return 1; }
	CHECK_MAKEPKG && { MAKEPKG && return 0 || return 2; }

	__WARNING 'could not detect supported installation method'

	__REMINDER 'complete manual installation in the directory below:'
	__REMINDER "$PACKAGE_INSTALL_DIR/$NAME"
}

CHECK_MAKE()    { [ -f ./Makefile ]; }
CHECK_MAKEPKG() { [ -f ./PKGBUILD ]; }

MAKE() {
	[[ $CLEAN -eq 1 ]] && {
		__STATUS "cleaning '$NAME'"
		make clean
	}

	__STATUS "building '$NAME'"
	make \
		&& __SUCCESS "finished building '$NAME'" \
		|| __FAIL 1 "build failed for '$NAME' (see above)"\
		;

	__STATUS "installing '$NAME'"
	__GETSUDO
	sudo make install \
		&& __SUCCESS "succesfully installed '$NAME'" \
		|| __FAIL 2 "failed to install '$NAME' (see above)"\
		;
}

MAKEPKG() {
	__STATUS "installing '$NAME'"
	yes | makepkg -si \
		&& __SUCCESS "succesfully installed '$NAME'" \
		|| __FAIL 1 "failed to install '$NAME' (see above)"\
		;
}

#####################################################################
