# Getting Started with z/OS Open Source

Are you ready to start building or consuming z/OS Open Source tools? Before you begin, make sure you have access to a z/OS UNIX environment and that your environment is correctly configured.

## Set up your z/OS environment

z/OS Open Source tools leverage the [z/OS Enhanced ASCII support](https://www.ibm.com/docs/en/zos/2.1.0?topic=pages-using-enhanced-ascii). This support enables automatic conversion between codepages for tagged files. To take advantage of this support, you need to set the following environment variables:

```
export _BPXK_AUTOCVT=ON
export _CEE_RUNOPTS="$_CEE_RUNOPTS FILETAG(AUTOCVT,AUTOTAG) POSIX(ON)"
export _TAG_REDIR_ERR=txt
export _TAG_REDIR_IN=txt
export _TAG_REDIR_OUT=txt
```

We recommend adding these environment variables to your `.profile` or `.bashrc` startup script.

## Required Tools

To consume z/OS Open Tools, all you need is a z/OS UNIX system and unrestricted access to github.com.

### If you want to contribute and improve the z/OS Open Source Tools 

You will need the IBM C/C++ compiler on your system. There are two options:
- You can download a web deliverable add-on feature to your XL C/C++ compiler 
[here](https://www.ibm.com/servers/resourcelink/svc00100.nsf/pages/xlCC++V241ForZOsV24).
- Alternatively, you can install and manage _C/C++ for Open Enterprise Languages on z/OS_ using _RedHat OpenShift Container Platform_ and _IBM Z and Cloud Modernization Stack_ 

In addition, to use the zopen framework set of tools like `zopen-build` and `zopen-install`, you will need git, tar, gzip, make installed. All of these tools are available from [ZOSOpenTools](https://github.com/ZOSOpenTools?tab=repositories), but instead of downloading them one at a time, there is an easier way. 
Download [zopen-setup](https://github.com/ZOSOpenTools/meta/releases/tag/v1.0.0) to z/OS and then run it, [following the instructions](https://github.com/ZOSOpenTools/meta/releases/tag/v1.0.0)

`zopen-setup` will create your own development environment with a `boot`, `prod`, and `dev` set of directories. The `boot` directory has everything you need to get started with porting.

For more details on porting, visit the [porting to z/OS guide](Porting.md).

## Installing tools to z/OS

Once you have your development environment set up, you can install tools directly to z/OS with `zopen install`.

Prior to installing tools, you need to initialize your z/OS Open Tools environment:
```bash
zopen init
```

To download and install the latest software packages, enter the command `zopen install`.

To download and install specific packages, specify them as a comma delimited list as follows:
```bash
zopen install make,curl,gzip
```

To download the available packages, specify the --all option as follows:

```bash
zopen install --all
```
For more details, see the section on [zopen tools](zopen.md).
