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
	echo.status "downloading $NAME"
	git clone "$TARGET" "$NAME" \
		&& echo.success "successfully downloaded '$NAME'" \
		|| utils.fail 1 "failed to download '$NAME'" \
		;
}

PULL() {
	echo.status "updating '$NAME'"
	cd "$PACKAGE_INSTALL_DIR/$NAME"
	git pull origin $(git rev-parse --abbrev-ref HEAD) \
		&& echo.success "successfully updated '$NAME'" \
		|| utils.fail 1 "failed to update '$NAME'" \
		;
}

#####################################################################

BUILD() {
	cd "$PACKAGE_INSTALL_DIR/$NAME"

	CHECK_MAKE    && { MAKE    && return 0 || return 1; }
	CHECK_MAKEPKG && { MAKEPKG && return 0 || return 2; }

	echo.warning 'could not detect supported installation method'

	echo.reminder 'complete manual installation in the directory below:'
	echo.reminder "$PACKAGE_INSTALL_DIR/$NAME"
}

CHECK_MAKE()    { [ -f ./Makefile ]; }
CHECK_MAKEPKG() { [ -f ./PKGBUILD ]; }

MAKE() {
	[[ $CLEAN -eq 1 ]] && {
		echo.status "cleaning '$NAME'"
		make clean
	}

	echo.status "building '$NAME'"
	make \
		&& echo.success "finished building '$NAME'" \
		|| utils.fail 1 "build failed for '$NAME' (see above)"\
		;

	echo.status "installing '$NAME'"
	GETSUDO
	sudo make install \
		&& echo.success "succesfully installed '$NAME'" \
		|| utils.fail 2 "failed to install '$NAME' (see above)"\
		;
}

MAKEPKG() {
	echo.status "installing '$NAME'"
	yes | makepkg -si \
		&& echo.success "succesfully installed '$NAME'" \
		|| utils.fail 1 "failed to install '$NAME' (see above)"\
		;
}
