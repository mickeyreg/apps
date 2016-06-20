AC_DEFUN([TUXBOX_APPS],[
AM_CONFIG_HEADER(config.h)
AM_MAINTAINER_MODE

AC_GNU_SOURCE
AC_SYS_LARGEFILE

AC_ARG_WITH(target,
	[  --with-target=TARGET    target for compilation [[native,cdk]]],
	[TARGET="$withval"],[TARGET="native"])

AC_ARG_WITH(targetprefix,
	[  --with-targetprefix=PATH  prefix relative to target root (only applicable in cdk mode)],
	[targetprefix="$withval"],[targetprefix="NONE"])

AC_ARG_WITH(debug,
	[  --without-debug         disable debugging code],
	[DEBUG="$withval"],[DEBUG="yes"])

if test "$DEBUG" = "yes"; then
	DEBUG_CFLAGS="-g3 -ggdb"
	AC_DEFINE(DEBUG,1,[Enable debug messages])
fi

AC_MSG_CHECKING(target)

if test "$TARGET" = "native"; then
	AC_MSG_RESULT(native)

	if test "$CFLAGS" = "" -a "$CXXFLAGS" = ""; then
		CFLAGS="-Wall -Os -pipe $DEBUG_CFLAGS"
		CXXFLAGS="-Wall -Os -pipe $DEBUG_CFLAGS"
	fi
	if test "$prefix" = "NONE"; then
		prefix=/usr/local
	fi
	targetprefix=$prefix
elif test "$TARGET" = "cdk"; then
	AC_MSG_RESULT(cdk)

	if test "$CC" = "" -a "$CXX" = ""; then
		CC=sh4-linux-gcc CXX=sh4-linux-g++
	fi
	if test "$CFLAGS" = "" -a "$CXXFLAGS" = ""; then
		CFLAGS="-Wall -Os -pipe $DEBUG_CFLAGS"
		CXXFLAGS="-Wall -Os -pipe $DEBUG_CFLAGS"
	fi
	if test "$prefix" = "NONE"; then
		AC_MSG_ERROR(invalid prefix, you need to specify one in cdk mode)
	fi
	if test "$targetprefix" = "NONE"; then
		targetprefix=""
	fi
	if test "$host_alias" = ""; then
		cross_compiling=yes
		host_alias=sh4-linux
	fi
else
	AC_MSG_RESULT(none)
	AC_MSG_ERROR([invalid target $TARGET, choose on from native,cdk]);
fi

AC_CANONICAL_BUILD
AC_CANONICAL_HOST

check_path () {
	return $(perl -e "if(\"$1\"=~m#^/usr/(local/)?bin#){print \"0\"}else{print \"1\";}")
}

])

AC_DEFUN([TUXBOX_APPS_DIRECTORY_ONE],[
AC_ARG_WITH($1,[  $6$7 [[PREFIX$4$5]]],[
	_$2=$withval
	if test "$TARGET" = "cdk"; then
		$2=`eval echo "${targetprefix}$withval"`
	else
		$2=$withval
	fi
	TARGET_$2=${$2}
],[
	$2="\${$3}$5"
	if test "$TARGET" = "cdk"; then
		_$2=`eval echo "${target$3}$5"`
	else
		_$2=`eval echo "${$3}$5"`
	fi
	TARGET_$2=$_$2
])

dnl automake <= 1.6 don't support this
dnl AC_SUBST($2)
AC_DEFINE_UNQUOTED($2,"$_$2",$7)
AC_SUBST(TARGET_$2)
])

AC_DEFUN([TUXBOX_APPS_DIRECTORY],[
AC_REQUIRE([TUXBOX_APPS])

if test "$TARGET" = "cdk"; then
	datadir="\${prefix}/share"
	sysconfdir="\${prefix}/etc"
	localstatedir="\${prefix}/var"
	libdir="\${prefix}/lib"
	targetdatadir="\${targetprefix}/share"
	targetsysconfdir="\${targetprefix}/etc"
	targetlocalstatedir="\${targetprefix}/var"
	targetlibdir="\${targetprefix}/lib"
fi

])

AC_DEFUN([TUXBOX_APPS_ENDIAN],[
AC_CHECK_HEADERS(endian.h)
AC_C_BIGENDIAN
])

AC_DEFUN([TUXBOX_APPS_DRIVER],[
AC_ARG_WITH(driver,
	[  --with-driver=PATH      path for driver sources [[NONE]]],
	[DRIVER="$withval"],[DRIVER=""])

if test "$DRIVER"; then
	AC_SUBST(DRIVER)
	CPPFLAGS="$CPPFLAGS -I$DRIVER/include"
fi
])

AC_DEFUN([TUXBOX_APPS_DVB],[
AC_ARG_WITH(dvbincludes,
	[  --with-dvbincludes=PATH  path for dvb includes [[NONE]]],
	[DVBINCLUDES="$withval"],[DVBINCLUDES=""])

if test "$DVBINCLUDES"; then
	CPPFLAGS="$CPPFLAGS -I$DVBINCLUDES"
fi

if test -z "$DVB_API_VERSION"; then
AC_CHECK_HEADERS(linux/dvb/version.h,[
	AC_LANG_PREPROC_REQUIRE()
	AC_REQUIRE([AC_PROG_EGREP])
	AC_LANG_CONFTEST([AC_LANG_SOURCE([[
	#include <linux/dvb/version.h>
	version DVB_API_VERSION
	]])])
	DVB_API_VERSION=`(eval "$ac_cpp conftest.$ac_ext") 2>&AS_MESSAGE_LOG_FD | $EGREP "^version" | sed "s,version\ ,,"`
	rm -f conftest*

	AC_MSG_NOTICE([found dvb version $DVB_API_VERSION])
])
fi

if test "$DVB_API_VERSION"; then
	AC_DEFINE(HAVE_DVB,1,[Define to 1 if you have the dvb includes])
	AC_DEFINE_UNQUOTED(HAVE_DVB_API_VERSION,$DVB_API_VERSION,[Define to the version of the dvb api])
else
	AC_MSG_ERROR([can't find dvb headers])
fi
])

AC_DEFUN([_TUXBOX_APPS_LIB_CONFIG],[
AC_PATH_PROG($1_CONFIG,$2,no)
if test "$$1_CONFIG" != "no"; then
	if test "$TARGET" = "cdk" && check_path "$$1_CONFIG"; then
		AC_MSG_$3([could not find a suitable version of $2]);
	else
		$1_CFLAGS=$($$1_CONFIG --cflags)
		$1_LIBS=$($$1_CONFIG --libs)
	fi
fi

AC_SUBST($1_CFLAGS)
AC_SUBST($1_LIBS)
])

AC_DEFUN([TUXBOX_APPS_LIB_CONFIG],[
_TUXBOX_APPS_LIB_CONFIG($1,$2,ERROR)
if test "$$1_CONFIG" = "no"; then
	AC_MSG_ERROR([could not find $2]);
fi
])

AC_DEFUN([TUXBOX_APPS_LIB_CONFIG_CHECK],[
_TUXBOX_APPS_LIB_CONFIG($1,$2,WARN)
])

AC_DEFUN([TUXBOX_APPS_PKGCONFIG],[
AC_PATH_PROG(PKG_CONFIG, pkg-config,no)
if test "$PKG_CONFIG" = "no" ; then
	AC_MSG_ERROR([could not find pkg-config]);
fi
])

AC_DEFUN([_TUXBOX_APPS_LIB_PKGCONFIG],[
AC_REQUIRE([TUXBOX_APPS_PKGCONFIG])
AC_MSG_CHECKING(for package $2)
if PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" $PKG_CONFIG --exists "$2" ; then
	AC_MSG_RESULT(yes)
	$1_CFLAGS=$(PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" $PKG_CONFIG --cflags "$2")
	$1_LIBS=$(PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" $PKG_CONFIG --libs "$2")
else
	AC_MSG_RESULT(no)
fi

AC_SUBST($1_CFLAGS)
AC_SUBST($1_LIBS)
])

AC_DEFUN([TUXBOX_APPS_LIB_PKGCONFIG],[
_TUXBOX_APPS_LIB_PKGCONFIG($1,$2)
if test -z "$$1_CFLAGS" ; then
	AC_MSG_ERROR([could not find package $2]);
fi
])

AC_DEFUN([TUXBOX_APPS_LIB_PKGCONFIG_CHECK],[
_TUXBOX_APPS_LIB_PKGCONFIG($1,$2)
])

AC_DEFUN([_TUXBOX_APPS_LIB_SYMBOL],[
AC_CHECK_LIB($2,$3,HAVE_$1="yes",HAVE_$1="no")
if test "$HAVE_$1" = "yes"; then
	$1_LIBS=-l$2
fi

AC_SUBST($1_LIBS)
])

AC_DEFUN([TUXBOX_APPS_LIB_SYMBOL],[
_TUXBOX_APPS_LIB_SYMBOL($1,$2,$3,ERROR)
if test "$HAVE_$1" = "no"; then
	AC_MSG_ERROR([could not find $2]);
fi
])

AC_DEFUN([TUXBOX_APPS_LIB_CONFIG_SYMBOL],[
_TUXBOX_APPS_LIB_SYMBOL($1,$2,$3,WARN)
])

AC_DEFUN([TUXBOX_APPS_GETTEXT],[
AC_PATH_PROG(MSGFMT, msgfmt, no)
AC_PATH_PROG(GMSGFMT, gmsgfmt, $MSGFMT)
AC_PATH_PROG(XGETTEXT, xgettext, no)
AC_PATH_PROG(MSGMERGE, msgmerge, no)

AC_MSG_CHECKING([whether NLS is requested])
AC_ARG_ENABLE(nls,
	[  --disable-nls           do not use Native Language Support],
	USE_NLS=$enableval, USE_NLS=yes)
AC_MSG_RESULT($USE_NLS)
AC_SUBST(USE_NLS)

if test "$USE_NLS" = "yes"; then
	AC_CACHE_CHECK([for GNU gettext in libc], gt_cv_func_gnugettext_libc,[
		AC_TRY_LINK([
			#include <libintl.h>
			#ifndef __GNU_GETTEXT_SUPPORTED_REVISION
			#define __GNU_GETTEXT_SUPPORTED_REVISION(major) ((major) == 0 ? 0 : -1)
			#endif
			extern int _nl_msg_cat_cntr;
			extern int *_nl_domain_bindings;
			],[
			bindtextdomain ("", "");
			return (int) gettext ("") + _nl_msg_cat_cntr + *_nl_domain_bindings;
			], gt_cv_func_gnugettext_libc=yes, gt_cv_func_gnugettext_libc=no
		)]
	)

	if test "$gt_cv_func_gnugettext_libc" = "yes"; then
		AC_DEFINE(ENABLE_NLS, 1, [Define to 1 if translation of program messages to the user's native language is requested.])
		gt_use_preinstalled_gnugettext=yes
	else
		USE_NLS=no
	fi
fi

if test -f "$srcdir/po/LINGUAS"; then
	ALL_LINGUAS=$(sed -e "/^#/d" "$srcdir/po/LINGUAS")
fi

POFILES=
GMOFILES=
UPDATEPOFILES=
DUMMYPOFILES=
for lang in $ALL_LINGUAS; do
	POFILES="$POFILES $srcdirpre$lang.po"
	GMOFILES="$GMOFILES $srcdirpre$lang.gmo"
	UPDATEPOFILES="$UPDATEPOFILES $lang.po-update"
	DUMMYPOFILES="$DUMMYPOFILES $lang.nop"
done
INST_LINGUAS=
if test -n "$ALL_LINGUAS"; then
	for presentlang in $ALL_LINGUAS; do
		useit=no
		if test -n "$LINGUAS"; then
			desiredlanguages="$LINGUAS"
		else
			desiredlanguages="$ALL_LINGUAS"
		fi
		for desiredlang in $desiredlanguages; do
			case "$desiredlang" in
				"$presentlang"*) useit=yes;;
			esac
		done
		if test $useit = yes; then
			INST_LINGUAS="$INST_LINGUAS $presentlang"
		fi
	done
fi
CATALOGS=
if test -n "$INST_LINGUAS"; then
	for lang in $INST_LINGUAS; do
		CATALOGS="$CATALOGS $lang.gmo"
	done
fi
AC_SUBST(POFILES)
AC_SUBST(GMOFILES)
AC_SUBST(UPDATEPOFILES)
AC_SUBST(DUMMYPOFILES)
AC_SUBST(CATALOGS)
])


AC_DEFUN([TUXBOX_BOXTYPE],[
AC_ARG_WITH(boxtype,
	[  --with-boxtype    valid values: ufs910, ufs912, ufs913, ufs922, ufc960
                             valid values: ipbox55, ipbox99, ipbox9900, cuberevo, cuberevo_mini, cuberevo_mini2, cuberevo_mini_fta, cuberevo_250hd, cuberevo_2000hd, cuberevo_9500hd, cuberevo_3000hd
                             valid values: tf7700, fortis_hdbox, octagon1008, atevio7500, spark, spark7162, hl101, hs7110, hs7810a, hs7119, hs7819, adb_box, atemio520, atemio530, vip, homecast5101
                             valid values: vitamin_hd5000, sagemcom88, arivalink200, fortis_dp7000, adb5800, adb2850, dsi87],
	[case "${withval}" in
		ufs910|ufs912|ufs913|ufs922|ufc960|ipbox55|ipbox99|ipbox9900|cuberevo|cuberevo_mini|cuberevo_mini2|cuberevo_mini_fta|cuberevo_250hd|cuberevo_2000hd|cuberevo_9500hd|cuberevo_3000hd|tf7700|fortis_hdbox|octagon1008|atevio7500|spark|spark7162|hl101|hs7110|hs7810a|hs7119|hs7819|adb_box|atemio520|atemio530|vip|homecast5101|vitamin_hd5000|sagemcom88|arivalink200|fortis_dp7000)
			BOXTYPE="$withval"
			;;
		*)
			AC_MSG_ERROR([bad value $withval for --with-boxtype]) ;;
	esac], [BOXTYPE="ufs912"])

AC_SUBST(BOXTYPE)

AM_CONDITIONAL(BOXTYPE_UFS910, test "$BOXTYPE" = "ufs910")
AM_CONDITIONAL(BOXTYPE_UFS912, test "$BOXTYPE" = "ufs912")
AM_CONDITIONAL(BOXTYPE_UFS913, test "$BOXTYPE" = "ufs913")
AM_CONDITIONAL(BOXTYPE_UFS922, test "$BOXTYPE" = "ufs922")
AM_CONDITIONAL(BOXTYPE_UFC960, test "$BOXTYPE" = "ufc960")
AM_CONDITIONAL(BOXTYPE_IPBOX55, test "$BOXTYPE" = "ipbox55")
AM_CONDITIONAL(BOXTYPE_IPBOX99, test "$BOXTYPE" = "ipbox99")
AM_CONDITIONAL(BOXTYPE_IPBOX9900, test "$BOXTYPE" = "ipbox9900")
AM_CONDITIONAL(BOXTYPE_CUBEREVO, test "$BOXTYPE" = "cuberevo")
AM_CONDITIONAL(BOXTYPE_CUBEREVO_MINI, test "$BOXTYPE" = "cuberevo_mini")
AM_CONDITIONAL(BOXTYPE_CUBEREVO_MINI2, test "$BOXTYPE" = "cuberevo_mini2")
AM_CONDITIONAL(BOXTYPE_CUBEREVO_MINI_FTA, test "$BOXTYPE" = "cuberevo_mini_fta")
AM_CONDITIONAL(BOXTYPE_CUBEREVO_250HD, test "$BOXTYPE" = "cuberevo_250hd")
AM_CONDITIONAL(BOXTYPE_CUBEREVO_2000HD, test "$BOXTYPE" = "cuberevo_2000hd")
AM_CONDITIONAL(BOXTYPE_CUBEREVO_9500HD, test "$BOXTYPE" = "cuberevo_9500hd")
AM_CONDITIONAL(BOXTYPE_CUBEREVO_3000HD, test "$BOXTYPE" = "cuberevo_3000hd")
AM_CONDITIONAL(BOXTYPE_TF7700, test "$BOXTYPE" = "tf7700")
AM_CONDITIONAL(BOXTYPE_FORTIS_HDBOX, test "$BOXTYPE" = "fortis_hdbox")
AM_CONDITIONAL(BOXTYPE_OCTAGON1008, test "$BOXTYPE" = "octagon1008")
AM_CONDITIONAL(BOXTYPE_ATEVIO7500, test "$BOXTYPE" = "atevio7500")
AM_CONDITIONAL(BOXTYPE_SPARK, test "$BOXTYPE" = "spark")
AM_CONDITIONAL(BOXTYPE_SPARK7162, test "$BOXTYPE" = "spark7162")
AM_CONDITIONAL(BOXTYPE_HL101, test "$BOXTYPE" = "hl101")
AM_CONDITIONAL(BOXTYPE_HS7110, test "$BOXTYPE" = "hs7110")
AM_CONDITIONAL(BOXTYPE_HS7810A, test "$BOXTYPE" = "hs7810a")
AM_CONDITIONAL(BOXTYPE_HS7119, test "$BOXTYPE" = "hs7119")
AM_CONDITIONAL(BOXTYPE_HS7819, test "$BOXTYPE" = "hs7819")
AM_CONDITIONAL(BOXTYPE_ADB_BOX, test "$BOXTYPE" = "adb_box")
AM_CONDITIONAL(BOXTYPE_ATEMIO520, test "$BOXTYPE" = "atemio520")
AM_CONDITIONAL(BOXTYPE_ATEMIO530, test "$BOXTYPE" = "atemio530")
AM_CONDITIONAL(BOXTYPE_VIP, test "$BOXTYPE" = "vip")
AM_CONDITIONAL(BOXTYPE_HOMECAST5101, test "$BOXTYPE" = "homecast5101")
AM_CONDITIONAL(BOXTYPE_VITAMIN_HD5000, test "$BOXTYPE" = "vitamin_hd5000")
AM_CONDITIONAL(BOXTYPE_SAGEMCOM88, test "$BOXTYPE" = "sagemcom88")
AM_CONDITIONAL(BOXTYPE_ARIVALINK200, test "$BOXTYPE" = "arivalink200")
AM_CONDITIONAL(BOXTYPE_FORTIS_DP7000, test "$BOXTYPE" = "fortis_dp7000")
AM_CONDITIONAL(BOXTYPE_ADB5800, test "$BOXTYPE" = "adb5800")
AM_CONDITIONAL(BOXTYPE_ADB2850, test "$BOXTYPE" = "adb2850")
AM_CONDITIONAL(BOXTYPE_DSI87, test "$BOXTYPE" = "dsi87")

if test "$BOXTYPE" = "ufs910"; then
	AC_DEFINE(HAVE_UFS910_HARDWARE, 1, [building for a ufs910])
elif test "$BOXTYPE" = "ufs912"; then
	AC_DEFINE(HAVE_UFS912_HARDWARE, 1, [building for a ufs912])
elif test "$BOXTYPE" = "ufs913"; then
	AC_DEFINE(HAVE_UFS913_HARDWARE, 1, [building for a ufs913])
elif test "$BOXTYPE" = "ufs922"; then
	AC_DEFINE(HAVE_UFS922_HARDWARE, 1, [building for an ufs922])
elif test "$BOXTYPE" = "ufc960"; then
	AC_DEFINE(HAVE_UFC960_HARDWARE, 1, [building for an ufc960])
elif test "$BOXTYPE" = "ipbox55"; then
	AC_DEFINE(HAVE_IPBOX55_HARDWARE, 1, [building for a ipbox55])
elif test "$BOXTYPE" = "ipbox99"; then
	AC_DEFINE(HAVE_IPBOX99_HARDWARE, 1, [building for a ipbox99])
elif test "$BOXTYPE" = "ipbox9900"; then
	AC_DEFINE(HAVE_IPBOX9900_HARDWARE, 1, [building for a ipbox9900])
elif test "$BOXTYPE" = "cuberevo"; then
	AC_DEFINE(HAVE_CUBEREVO_HARDWARE, 1, [building for a cuberevo])
elif test "$BOXTYPE" = "cuberevo_mini"; then
	AC_DEFINE(HAVE_CUBEREVO_MINI_HARDWARE, 1, [building for an cuberevo_mini])
elif test "$BOXTYPE" = "cuberevo_mini2"; then
	AC_DEFINE(HAVE_CUBEREVO_MINI2_HARDWARE, 1, [building for a cuberevo_mini2])
elif test "$BOXTYPE" = "cuberevo_mini_fta"; then
	AC_DEFINE(HAVE_CUBEREVO_MINI_FTA_HARDWARE, 1, [building for a cuberevo_mini_fta])
elif test "$BOXTYPE" = "cuberevo_250hd"; then
	AC_DEFINE(HAVE_CUBEREVO_250HD_HARDWARE, 1, [building for a cuberevo_250hd])
elif test "$BOXTYPE" = "cuberevo_2000hd"; then
	AC_DEFINE(HAVE_CUBEREVO_2000HD_HARDWARE, 1, [building for a cuberevo_2000hd])
elif test "$BOXTYPE" = "cuberevo_9500hd"; then
	AC_DEFINE(HAVE_CUBEREVO_9500HD_HARDWARE, 1, [building for an cuberevo_9500hd])
elif test "$BOXTYPE" = "cuberevo_3000hd"; then
	AC_DEFINE(HAVE_CUBEREVO_3000HD_HARDWARE, 1, [building for an cuberevo_3000hd])
elif test "$BOXTYPE" = "tf7700"; then
	AC_DEFINE(HAVE_TF7700_HARDWARE, 1, [building for a tf7700])
elif test "$BOXTYPE" = "fortis_hdbox"; then
	AC_DEFINE(HAVE_FORTIS_HDBOX_HARDWARE, 1, [building for a fortis_hdbox])
elif test "$BOXTYPE" = "octagon1008"; then
	AC_DEFINE(HAVE_OCTAGON1008_HARDWARE, 1, [building for a octagon1008])
elif test "$BOXTYPE" = "atevio7500"; then
	AC_DEFINE(HAVE_ATEVIO7500_HARDWARE, 1, [building for a atevio7500])
elif test "$BOXTYPE" = "spark"; then
	AC_DEFINE(HAVE_SPARK_HARDWARE, 1, [building for an spark])
elif test "$BOXTYPE" = "spark7162"; then
	AC_DEFINE(HAVE_SPARK7162_HARDWARE, 1, [building for a spark7162])
elif test "$BOXTYPE" = "hl101"; then
	AC_DEFINE(HAVE_HL101_HARDWARE, 1, [building for a hl101])
elif test "$BOXTYPE" = "hs7110"; then
	AC_DEFINE(HAVE_HS7110_HARDWARE, 1, [building for a hs7110])
elif test "$BOXTYPE" = "hs7810a"; then
	AC_DEFINE(HAVE_HS7810A_HARDWARE, 1, [building for a hs7810a])
elif test "$BOXTYPE" = "hs7119"; then
	AC_DEFINE(HAVE_HS7119_HARDWARE, 1, [building for a hs7119])
elif test "$BOXTYPE" = "hs7819"; then
	AC_DEFINE(HAVE_HS7819_HARDWARE, 1, [building for a hs7819])
elif test "$BOXTYPE" = "adb_box"; then
	AC_DEFINE(HAVE_ADB_BOX_HARDWARE, 1, [building for a adb_box])
elif test "$BOXTYPE" = "atemio520"; then
	AC_DEFINE(HAVE_ATEMIO520_HARDWARE, 1, [building for a atemio520])
elif test "$BOXTYPE" = "atemio530"; then
	AC_DEFINE(HAVE_ATEMIO530_HARDWARE, 1, [building for a atemio530])
elif test "$BOXTYPE" = "vip"; then
	AC_DEFINE(HAVE_VIP_HARDWARE, 1, [building for an vip])
elif test "$BOXTYPE" = "homecast5101"; then
	AC_DEFINE(HAVE_HOMECAST5101_HARDWARE, 1, [building for a homecast5101])
elif test "$BOXTYPE" = "vitamin_hd5000"; then
	AC_DEFINE(HAVE_VITAMIN_HD5000_HARDWARE, 1, [building for a vitamin_hd5000])
elif test "$BOXTYPE" = "sagemcom88"; then
	AC_DEFINE(HAVE_SAGEMCOM88_HARDWARE, 1, [building for a sagemcom88])
elif test "$BOXTYPE" = "arivalink200"; then
	AC_DEFINE(HAVE_ARIVALINK200_HARDWARE, 1, [building for a arivalink200])
elif test "$BOXTYPE" = "fortis_dp7000"; then
	AC_DEFINE(HAVE_FORTIS_DP7000_HARDWARE, 1, [building for a fortis_dp7000])
elif test "$BOXTYPE" = "adb5800"; then
	AC_DEFINE(HAVE_ADB5800_HARDWARE, 1, [building for a adb5800])
elif test "$BOXTYPE" = "adb2850"; then
	AC_DEFINE(HAVE_ADB2850_HARDWARE, 1, [building for a adb2850])
elif test "$BOXTYPE" = "dsi87"; then
	AC_DEFINE(HAVE_DSI87_HARDWARE, 1, [building for a dsi87])
fi

])

dnl backward compatiblity
AC_DEFUN([AC_GNU_SOURCE],
[AH_VERBATIM([_GNU_SOURCE],
[/* Enable GNU extensions on systems that have them.  */
#ifndef _GNU_SOURCE
# undef _GNU_SOURCE
#endif])dnl
AC_BEFORE([$0], [AC_COMPILE_IFELSE])dnl
AC_BEFORE([$0], [AC_RUN_IFELSE])dnl
AC_DEFINE([_GNU_SOURCE])
])

AC_DEFUN([AC_PROG_EGREP],
[AC_CACHE_CHECK([for egrep], [ac_cv_prog_egrep],
   [if echo a | (grep -E '(a|b)') >/dev/null 2>&1
    then ac_cv_prog_egrep='grep -E'
    else ac_cv_prog_egrep='egrep'
    fi])
 EGREP=$ac_cv_prog_egrep
 AC_SUBST([EGREP])
])
