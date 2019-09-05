# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python{2_7,3_5,3_6,3_7} pypy )

inherit distutils-r1

DESCRIPTION="easy-to-use, pythonic, and complete IMAP client library"
HOMEPAGE="https://github.com/mjs/imapclient"
SRC_URI="https://github.com/mjs/imapclient/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc examples test"

RDEPEND="dev-python/six[${PYTHON_USEDEP}]"
DEPEND="${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
	doc? ( dev-python/sphinx[${PYTHON_USEDEP}] )
	test? ( $(python_gen_cond_dep 'dev-python/mock[${PYTHON_USEDEP}]' -2) )"

PATCHES=(
	# fix incorrect assumption about py3.6 behavior
	# https://github.com/mjs/imapclient/pull/384
	"${FILESDIR}"/imapclient-2.1.0-py36-tests.patch
)

python_compile_all () {
	use doc && esetup.py build_sphinx
}

python_test() {
	esetup.py test
}

python_install_all() {
	local DOCS=( AUTHORS.rst NEWS.rst README.rst )
	use doc && local HTML_DOCS=( doc/html/. )
	distutils-r1_python_install_all
	use examples && dodoc -r examples
}
