# meta-redux
A reworking of the main meta project to add additional package management facilities, similar to utilities like apt, dpkg, yum, yast2, emerge .... just written in pure shell script (and a tiny bit of REXX) to remove any pre-reqs (like python/perl/bash etc).
This fork is designed for everyday usage of the zos Open Tools ports within the USS environment or for those who wish to download the tools; users who are interested in building and/or porting packages from scratch should use the main release of meta at this time.

## Installation
Clone the repo or download/expand a release pax.  From the bin directory run the following command, answering the questions appropriately:
'''
zopen init
'''


## Restrictions
Currently, the zopen build capability DOES NOT work with the fork due to the way package dependencies and post-built installation occurs.  This is on the roadmap...



# Sample usage
./zopen init
. $HOME/.zopen-config
./zopen list --installed
zopen install xz
zopen list --installed
zopen upgrade

## Important usage notes
On first run, _zopen init_ will copy this forked version of meta into the "package" area of zopen (ie. where packages are expanded and accessed from).  It will also be pinned to the release to prevent any possible updates from the "real" meta package. Removing the .pinned file from the meta-dt directory will allow for the main meta port to be installed however this will cause incompatabilities if run

# Problem resolution
If the meta package does get updated to a non-dt version, then running "./zopen alt meta -s" from the meta-dt/bin directory within the zopen filesystem should allow selection of the dt-forked meta; running any other non-forked zopen commands might break 




View the main Meta documentation at https://zosopentools.github.io/meta/.

## Background

There are some key 'foundational' Open Source technologies needed to port software. The goal of this set of repositories is to provide minimal 'port' repositories
that can be used to get a foundational software package building on z/OS.
We are starting with what we view as some 'foundational' technologies. One is the stack of technology to be able to build [zsh](https://sourceforge.net/projects/zsh/postdownload). Another is to 
be able to build [protocol buffers](https://github.com/protocolbuffers/protobuf/releases). 

But - there is a _transitive closure_ problem to address with porting a software package, namely understanding what packages are pre-requisites 
for the software package you want to port. As an example, for zsh, we see the following:

zsh requires autoconf to configure the build scripts, GNU make to run Makefiles, ncurses
zsh is easier to develop (but doesn't require) curl and git natively on z/OS, and GNU techinfo for documentation

autoconf requires m4, automake, GNU make
m4 requires a c99 compiler with c11 features, so ensure you have the latest C/C++ compilers installed on your system

GNU make requires GNU m4, automake, autoconf, Perl, and a C compiler that is gcc compatible

Perl requires a c89 compiler
ncurses requires an ANSI C compiler 

## Order to Build _from scratch_

If you want to build the tools from scratch and not use the binary pax files available, you will want 
to tackle this in a particular order. 
First, you need to have some tools installed on your system:

### System Pre-reqs:

| Project | License | Download link |
|---------|---------|------------------------|
| [gnu make 4.1](https://www.gnu.org/software/make/) | [GPL V3 ](https://www.gnu.org/licenses/gpl-3.0.html) | [z/OS Open Tools release](https://github.com/ZOSOpenTools/makeport/releases/tag/boot) |
| [IBM XL C/C++ V2.4.1](https://www-40.ibm.com/servers/resourcelink/svc00100.nsf/pages/xlCC++V241ForZOsV24) | IBM [^ibm] | [ibm.com web download](https://www.ibm.com/marketing/iwm/iwm/web/dispatcher.do?source=swg-zosxlcc) |
| [git](https://git.kernel.org/pub/scm/git/git.git/) | [LGPL V2.1](https://git.kernel.org/pub/scm/git/git.git/tree/LGPL-2.1) | [z/OS Open Tools release](https://github.com/ZOSOpenTools/gitport/releases/tag/boot)  |
| [curl](https://github.com/curl/curl) | [curl-license](https://github.com/curl/curl/blob/master/COPYING) | [z/OS Open Tools release](https://github.com/ZOSOpenTools/curlport/releases/tag/boot) |
| [gunzip](https://www.gnu.org/software/gzip/) | [GPL V3 ](https://www.gnu.org/licenses/gpl-3.0.html) | [z/OS Open Tools release](https://github.com/ZOSOpenTools/unzipport/releases/tag/boot) |

[^ibm]: a no-charge add-on feature for clients that have enabled the XL C/C++ compiler (an optionally priced feature) on z/OS
### Recommended software:

| Project | License | Download link |
|---------|---------|------------------------|
| [bash](https://www.gnu.org/software/bash/) | [GPL V3 ](https://www.gnu.org/licenses/gpl-3.0.html) | [z/OS Open Tools release](https://github.com/ZOSOpenTools/bashport/releases/) |

Both IBM and Rocket provide supported versions of the software above for a fee.

Taking the defaults will mean there are less variables for you to configure. We recommend you structure your sandbox as follows:

 - Have the root of your development file system be `$HOME/zopen` (you will want to have several gigabytes of storage for use - we recommend at least 15GB)
 - Have sub-directories called _boot_, _prod_, _dev_.
    - _boot_: sub-directory for each tool required to bootstrap (make, git, curl, gunzip, m4)
    - _prod_: sub-directory for tools to be installed once built. These tools will be used by downstream software, e.g. make build process will use the Perl prod build
    - _dev_: sub-directory for tools you are building

### Order to build:
The tools have dependencies on other tools, and there are also typically 2 ways the tools are packaged:
 - one that is pre-configured and therefore doesn't need autoconf/automake and associated tools
 - one that is not pre-reconfigured and therefore does require autoconf/automake and associated tools

To build from scratch, start with the tarballs of the following tools:

| Project | License | Pre-requisites |
|---------|---------|------------------------|
| [m4](https://www.gnu.org/software/m4/m4.html) | [GPL V3 ](https://www.gnu.org/licenses/gpl-3.0.html) | m4, curl in boot and xlclang installed on the system |
| [perl](https://dev.perl.org/) | [GPL V3 ](https://www.gnu.org/licenses/gpl-3.0.html) | additionally requires make, git in boot and m4 in prod |
| [make](https://www.gnu.org/software/make/) | [GPL V3 ](https://www.gnu.org/licenses/gpl-3.0.html) | perl in prod for running test cases |
| [zlib](https://zlib.net/) | [zlib license](https://zlib.net/zlib_license.html) | make in prod |
| [autoconf](https://www.gnu.org/software/autoconf/) | [GPL V3 ](https://www.gnu.org/licenses/gpl-3.0.html) | libz in prod |
| [automake](https://www.gnu.org/software/automake/) | [GPL V3 ](https://www.gnu.org/licenses/gpl-3.0.html) | autoconf in prod |
 
Once you either have these tools built, or have downloaded a pre-built pax file for the build, you may want to build other tools.
Each tool has a _buildenv_ file and one of the entries will describe the tools it requires to build, depending
on where the source is from (currently TARBALL or GIT clone). So for example m4 requires:
 - ZOPEN_TARBALL_DEPS="curl gzip make m4"
and:
 - ZOPEN_GIT_DEPS="git make m4 help2man perl makeinfo xz autoconf automake gettext"

If you want to build from the GIT clone, you can see you will need to have more software pre-installed.
