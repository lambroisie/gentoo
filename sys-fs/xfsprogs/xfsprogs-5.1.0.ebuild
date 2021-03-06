# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs multilib systemd usr-ldscript

DESCRIPTION="xfs filesystem utilities"
HOMEPAGE="https://xfs.wiki.kernel.org/"
SRC_URI="https://www.kernel.org/pub/linux/utils/fs/xfs/${PN}/${P}.tar.xz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="icu libedit nls readline static-libs"

LIB_DEPEND=">=sys-apps/util-linux-2.17.2[static-libs(+)]
	icu? ( dev-libs/icu:=[static-libs(+)] )
	readline? ( sys-libs/readline:0=[static-libs(+)] )
	!readline? ( libedit? ( dev-libs/libedit[static-libs(+)] ) )"
RDEPEND="${LIB_DEPEND//\[static-libs(+)]}
	!<sys-fs/xfsdump-3"
DEPEND="${RDEPEND}"
BDEPEND="
	nls? ( sys-devel/gettext )
"

PATCHES=(
	"${FILESDIR}"/${PN}-4.9.0-underlinking.patch
	"${FILESDIR}"/${PN}-4.15.0-sharedlibs.patch
	"${FILESDIR}"/${PN}-4.15.0-docdir.patch
)

pkg_setup() {
	if use readline && use libedit ; then
		ewarn "You have USE='readline libedit' but these are exclusive."
		ewarn "Defaulting to readline; please disable this USE flag if you want libedit."
	fi
}

src_prepare() {
	default

	# Clear out -static from all flags since we want to link against dynamic xfs libs.
	sed -i \
		-e "/^PKG_DOC_DIR/s:@pkg_name@:${PF}:" \
		include/builddefs.in || die
	# Don't install compressed docs
	sed 's@\(CHANGES\)\.gz[[:space:]]@\1 @' -i doc/Makefile || die
	find -name Makefile -exec \
		sed -i -r -e '/^LLDFLAGS [+]?= -static(-libtool-libs)?$/d' {} +
}

src_configure() {
	export DEBUG=-DNDEBUG
	export OPTIMIZER=${CFLAGS}
	unset PLATFORM # if set in user env, this breaks configure

	local myconf=(
		--disable-lto #655638
		--enable-blkid
		--with-crond-dir="${EPREFIX}/etc/cron.d"
		--with-systemd-unit-dir="$(systemd_get_systemunitdir)"
		$(use_enable icu libicu)
		$(use_enable nls gettext)
		$(use_enable readline)
		$(usex readline --disable-editline $(use_enable libedit editline))
		$(use_enable static-libs static)
	)

	econf "${myconf[@]}"

	MAKEOPTS+=" V=1"
}

src_install() {
	emake DIST_ROOT="${ED}" install
	# parallel install fails on this target for >=xfsprogs-3.2.0
	emake -j1 DIST_ROOT="${ED}" install-dev

	# handle is for xfsdump, the rest for xfsprogs
	gen_usr_ldscript -a handle xcmd xfs xlog frog
	# removing unnecessary .la files if not needed
	if ! use static-libs ; then
		find "${ED}" -type f -name '*.la' -delete || die
	fi
}
