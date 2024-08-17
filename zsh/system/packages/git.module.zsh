#####################################################################

DEPENDENCIES+=(
	git
	make
)

REQUIRED_ENV+=()

#####################################################################

PACKAGE_INSTALL_DIR="$HOME/.local/share/source-packages"
[ ! -d "$PACKAGE_INSTALL_DIR" ] && mkdir -p "$PACKAGE_INSTALL_DIR"

#####################################################################

CLONE() {
	cd "$PACKAGE_INSTALL_DIR"
	STATUS "downloading $NAME"
	git clone "$TARGET" "$NAME" \
		&& SUCCESS "successfully downloaded '$NAME'" \
		|| FAIL 1 "failed to download '$NAME'" \
		;
}

PULL() {
	STATUS "updating '$NAME'"
	cd "$PACKAGE_INSTALL_DIR/$NAME"
	git pull origin $(git rev-parse --abbrev-ref HEAD) \
		&& SUCCESS "successfully updated '$NAME'" \
		|| FAIL 1 "failed to update '$NAME'" \
		;
}

#####################################################################

BUILD() {
	cd "$PACKAGE_INSTALL_DIR/$NAME"

	CHECK_MAKE    && { MAKE    && return 0 || return 1; }
	CHECK_MAKEPKG && { MAKEPKG && return 0 || return 2; }

	WARNING 'could not detect supported installation method'

	REMINDER 'complete manual installation in the directory below:'
	REMINDER "$PACKAGE_INSTALL_DIR/$NAME"
}

CHECK_MAKE()    { [ -f ./Makefile ]; }
CHECK_MAKEPKG() { [ -f ./PKGBUILD ]; }

MAKE() {
	[[ $CLEAN -eq 1 ]] && {
		STATUS "cleaning '$NAME'"
		make clean
	}

	STATUS "building '$NAME'"
	make \
		&& SUCCESS "finished building '$NAME'" \
		|| FAIL 1 "build failed for '$NAME' (see above)"\
		;

	STATUS "installing '$NAME'"
	GETSUDO
	sudo make install \
		&& SUCCESS "succesfully installed '$NAME'" \
		|| FAIL 2 "failed to install '$NAME' (see above)"\
		;
}

MAKEPKG() {
	STATUS "installing '$NAME'"
	yes | makepkg -si \
		&& SUCCESS "succesfully installed '$NAME'" \
		|| FAIL 1 "failed to install '$NAME' (see above)"\
		;
}
