# Common Issues and their solutions

## C pipe, C open do not tag newly created file descriptors

Note: in most cases you can use the zoslibport package for ASCII/EBCDIC issues. See [zoslib](https://github.com/ZOSOpenTools/zoslibport) for details.

A common problem when porting code to z/OS and building with ASCII is that when files are created, the contents are written out in ASCII
but by default the files are not tagged to indicate the content is in ASCII. Subsequently, other tools have to _guess_ what codepage the contents are in, and often the tools _guess_ EBCDIC. 
There are many ways that people describe an encoding:
- ASCII, EBCDIC, Single-byte, Double-byte, Multi-byte are fairly generic terms. When people refer to an ASCII encoding, it represents a small number of the complete 256 single-byte character mappings, and typically refers to one of the ISO8859 code pages. The same is true when people refer to an EBCDIC encoding. There are a small number of the complete single-byte character mappings that are constant across the EBCDIC code pages. 
- When specifying an ASCII or EBCDIC format, the more precise _coded character set identifier_ (CCSID) is used. We code to CCSID _ISO8859-1_, also known as _819_, because z/OS is optimized for this particular ASCII CCSID, and it is consistent with what people on other platforms equate to _ASCII_. 

The following C code tags a file when it is opened for write as 819 (ISO8859-1):

```
fd = open(...); /* open new file for WRITE */
if (fd < 0) { ... } /* unable to open file */
#ifdef __MVS__
  #if (__CHARSET_LIB ==	1)
    setccsid(fd, 819);
  #endif
#endif
```

You can also tag a file as 819 using the shell as follows:

```
chtag -tc819 <file>
```

or alternately:

```
chtag -tcISO8859-1 <file>
```

The z/OS specific code needs to be double-protected. The `#ifdef __MVS__` ensures that this is specific to z/OS. 
The `#if (__CHARSET_LIB == 1)` ensures that this code is only active when being built with `-qascii`, so that if others want to build with 
EBCDIC, they won't get this behaviour.
The function `setccsid` is also required. This can be either a static function if all the calls to setccsid are in one file, or an external function.
Here is a simple version - you may need something more complex if you want to check how the file is opened first (e.g. to prevent setting the CCSID if the file is being opened for READ):

```
#ifdef __MVS__
 #if (__CHARSET_LIB == 1)
#   include <stdio.h>
#   include <stdlib.h>
 
    static int setccsid(int fd, int ccsid)
    {
      attrib_t attr;
      int rc;

      memset(&attr, 0, sizeof(attr));
      attr.att_filetagchg = 1;
      attr.att_filetag.ft_ccsid = ccsid;
      attr.att_filetag.ft_txtflag = 1;

      rc = __fchattr(fd, &attr, sizeof(attr));
      return rc;
    }
  #endif
#endif
```

Further reading:
- [chtag - Change file tag information](https://www.ibm.com/docs/en/zos/latest?topic=descriptions-chtag-change-file-tag-information)
- [ASCII and EBCDIC on z/OS](https://makingdeveloperslivesbetter.wordpress.com/2022/01/07/is-z-os-ascii-or-ebcdic-yes/)
- [Character sets](https://www.ibm.com/docs/en/ztpf/latest?topic=support-character-sets) 
- [CCSID](https://en.wikipedia.org/wiki/CCSID)
- [ASCII 8859-1](https://en.wikipedia.org/wiki/ISO/IEC_8859-1)

## FSUM7327 signal number XX not conventional

Note: If you are seeing this error in a source file from gnulib tools package, a fix for this has been [upstreamed](https://git.savannah.gnu.org/gitweb/?p=gnulib.git;a=commit;h=835b3ea801782fcf72ef1f9397bb112cac0e2f50) on November 26, 2022 and so the 'fix' is probably to get the software package to pick up a new version of gnulib tools.

See: [FSUM7327](https://tech.mikefulton.ca/FSUM7327) which is relatively cryptic and [kill](https://tech.mikefulton.ca/POSIXSignalNumbers).

Only _some_ signals have a well-defined number that can be used when specifying an action (such as kill or trap). In particular, signal number 13 (which is PIPE) is _not_ a well-defined signal number.
As such, code that specifies signal 13 gets the cryptic error message above and can be re-coded to use PIPE instead (see signal.h if the signal number in question isn't 13, 
in which case you will need to see what a Linux signal XX is and then re-code it with a name. Note that you need to drop the _SIG_ part at the start of the name to be conformant).

Here is a common code sequence you might see in a shell script for testing or configuring:

```
do_exit='rm -f $log_file $trs_file; (exit $st); exit $st'
trap "st=129; $do_exit" 1
trap "st=130; $do_exit" 2
trap "st=141; $do_exit" 13
trap "st=143; $do_exit" 15
```

The trap lines might vary as might the variables and exit codes. The thing to change, which is _no less portable than the 13, but not required to work_, is to instead say:

```
do_exit='rm -f $log_file $trs_file; (exit $st); exit $st'
trap "st=129; $do_exit" 1
trap "st=130; $do_exit" 2
trap "st=141; $do_exit" PIPE
trap "st=143; $do_exit" 15
```

For Linux, the signal numbers can be found under [signal(7)](https://www.man7.org/linux/man-pages/man7/signal.7.html).
For POSIX, a number of signals (but not SIGPIPE) have well-defined names: [POSIX trap](https://www.unix.com/man-page/POSIX/1posix/trap/).
For Linux, here is a similar doc: [Linux trap](https://www.man7.org/linux/man-pages/man1/trap.1p.html).
Note that _HUP_ is a POSIX supported name, but _SIGHUP_ might also work. Also note that neither _PIPE_ nor 13 is officially supported... 

This will make z/OS happy and is arguably more clear. Ideally, you could change the other trap values as well to use their names, e.g.

```
do_exit='rm -f $log_file $trs_file; (exit $st); exit $st'
trap "st=129; $do_exit" HUP
trap "st=130; $do_exit" INT
trap "st=141; $do_exit" PIPE
trap "st=143; $do_exit" TERM 
```

On z/OS, you can find these values in `/usr/include/le/signals.h`

## CEE3728S The use of a function, which is not supported by this release of Language Environment was detected.

LE provides stubs for some functions that are not yet implemented. This means that they exist in the DLL and side deck, but if you call them they just put out the CEE3728S error message. This causes a problem for builds which detect the available functions on the target OS and conditionally include source based on the detected fuctions. Since these stub fuctions are detected, the built component will try to use them.

The issue can be addressed with a workaround which removes the stub functions from the side deck so that the builds fail to detect them. Changing the side deck in the system library is not advisable, so the following steps allow a copy to be used.

- Clone the https://github.com/MikeFultonDev/sbin repository to your z/OS system.
- Run the rmceertfm script to produce an edited side deck in /tmp.
- Take your own copy of the CEE.SCEELIB dataset with all members.
- Replace the CELQS003 member with the modified version created by rmceertfm.
```
cp /tmp/celqs003.x "//'FRED.ZOPEN.ZOS204.SCEELIB(CELQS003)'"
```
- Take your own copy of the xlclang configuration file.
```
cp /usr/lpp/cbclib/xlclang/etc/xlclang.cfg /u/fred/xlclang.cfg.zos204.noceertfm
```
- Edit the copy of the config file, updating exportlist_c_64 and exportlist_cpp_64 to point to the modified SCEELIB dataset.
```
              exportlist_c_64   = fred.zopen.zos204.sceelib(celqs003)
              exportlist_cpp_64 = fred.zopen.zos204.sceelib(celqs003,celqscpp,cxxrt64)
```
- Tell the compiler to use the modified config file.
```
export CLC_CONFIG=/u/fred/xlclang.cfg.zos204.noceertfm
```

## S_TYPEISSHM macro gives an error when compiled

The error might be something like: `called object type 'int' is not a function or function pointer`

This is due to a bug in the LE header file `sys/modes.h` which defines the macros as follows:

```
       #ifdef __SUSV3_POSIX                                  /*#5@D1A*/
         #define S_TYPEISMQ  (0)         /* Test for a message queue */
         #define S_TYPEISSEM (0)         /* Test for a semaphore     */
         #define S_TYPEISSHM (0)         /* Test for a shared memory */
                                         /* object                   */
       #endif /* __SUSV3_POSIX */
```

This is unfortunately wrong because the macro expects a parameter to be passed to it
(the z/OS team has been notified and hopefully a fix will be provided soon).

The simplest work-around is to provide a patch to the open source package. `findutils` currently has a patch 
for this:

```
+#ifdef __MVS__
+  /* z/OS incorrectly defined these macros - if they are present,
+   * redefined them
+   */
+  #ifdef S_TYPEISSEM
+     #undef S_TYPEISSEM
+     #define S_TYPEISSEM(x) (0)
+  #endif
+  #ifdef S_TYPEISMQ
+     #undef S_TYPEISMQ
+     #define S_TYPEISMQ(x) (0)
+  #endif
+  #ifdef S_TYPEISSHM
+     #undef S_TYPEISSHM
+     #define S_TYPEISSHM(x) (0)
+  #endif
+  #ifdef S_TYPEISTMO
+     #undef S_TYPEISTMO
+     #define S_TYPEISTMO(x) (0)
+  #endif
+#endif
```

# Libtool complains that passing .o object files as libraries is not allowed
By default, projects that use libtool during the build phase will complain about the use of .o files as libraries when they are passed in via the LIBS variable. Here's an example of the error message:

```
libtool:   error: cannot build libtool library 'liblzma.la' from non-libtool objects on this host: /home/itodoro/zopen-data/prod/zoslib-autocvt_tty/lib/celquopt.s.o
```

When zoslib is included as a dependency, it automatically adds .o files to the `ZOPEN_EXTRA_LIBS` environment variable, which will eventually be passed as the LIBS variable.

To override this, you can modify the configure script as follows:

```
+openedition)
+  lt_cv_deplibs_check_method=pass_all
+  ;;
```

Here's an example pull request that was done for man-db: https://github.com/ZOSOpenTools/man-dbport/pull/23/files

# Displaying compile commands in the build output
When building projects, it can be helpful to see the actual compile commands being executed. This can aid in understanding the build process, diagnosing issues, or debugging. The zopen build tool provides an option, -vv, for very verbose output. By using this option with the zopen build command, you can enable the display of the compile commands.

Internally, zopen sets the `V` and `VERBOSE` environment variables to 1 when the -vv option is specified. GNU Make, and other build systems, respects these variables and display the executed commands during the build process.

```
zopen build -vv
```
