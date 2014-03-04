#!/bin/sh
# --------------------------------------------------------------------------- #
# link  : Linker script for use in make (customized for hardware and          #
#         optimization. Note that this script will not be replaced if part    #
#         of WAVEWATCH III is re-installed.                                   #
#                                                                             #
# use   : link name [name ... ]                                               #
#           name: name of source code file without the extension.             #
#                 the first name will become the program name.                #
#                                                                             #
# error codes :  all error output directly to screen.                         #
#                                                                             #
# remarks :                                                                   #
#                                                                             #
#  - Upon (first) installation of WAVEWATCH III the user needs to check the   #
#    following parts of this scripts :                                        #
#      sec. 3 : Provide correct link command                                  #
#                                                                             #
#  - This version is made for the GNU compilers on any architecture.          #
#                                                                             #
#                                                      Timothy J. Campbell    #
#                                                      October 2009           #
# --------------------------------------------------------------------------- #
# 1. Preparations                                                             #
# --------------------------------------------------------------------------- #
# 1.a Check and process input

  if [ "$#" -lt '1' ]
  then
    echo "usage: link name [name]" ; exit 1
  fi

  prog=$1
  echo "      Linking $prog"
  input="$*"

# 1.b Internal variables - - - - - - - - - - - - - - - - - - - - - - - - - - -

  ww3_env="${HOME}/.wwatch3.env"                           # setup file
# The following line must not be removed: it is a switch for local install
# so that all bin scripts point to the local wwatch3.env
# WW3ENV
# For manual install (without install_ww3_tar or install_ww3_svn) make sure to
# either use the generic ww3_env or to add your own ww3_env="${my_directory}"

  if [ ${WWATCH3_ENV} ]; then ww3_env="${WWATCH3_ENV}"; fi # alternate setup file

# 1.c Read data from the environment file  - - - - - - - - - - - - - - - - - -

  if [ -f $ww3_env ]
  then
    set `grep WWATCH3_DIR $ww3_env` ; shift
    main_dir="$*"
  else
    echo "*** Set-up file $ww3_env not found ***"
    exit 2
  fi

# 1.d Initial clean-up - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

  rm -f $main_dir/exe/$prog

# --------------------------------------------------------------------------- #
# 2. Check objects                                                            #
# --------------------------------------------------------------------------- #

  cd $main_dir/obj
  objects=$NULL
  error='n'
  set $input

  while [ "$#" -gt '0' ]
  do
    file=$1.o
    if [ -f "$file" ]
    then
      objects="$objects $file"
    else
      echo "      *** file $file not found ***"
      error='y'
    fi
    shift
  done
  if [ "$error" = 'y' ]
  then
    echo "*** Missing object files ***"
    exit 3
  fi

# --------------------------------------------------------------------------- #
# 3. Link all things                                                          #
# --------------------------------------------------------------------------- #
# Add here the correct linker call including switches

# 3.a Build options and determine compiler name
#     No GRIB libraries for this one

# libs="-L/opt/local/lib -L$HOME/g2lib -lg2 -lw3 -lpng -ljasper"
  opt="-o $prog"

  if [ "$mpi_mod" = 'yes' ]
  then
    comp=mpif90
  else
    comp=gfortran
  fi

  if [ "$omp_mod" = 'yes' ]
  then
    opt="$opt -fopenmp"
  fi

  if [ "$netcdf_compile" = 'yes' ]
  then
    case $WWATCH3_NETCDF in
      NC3) libs="$libs -L$NETCDF_LIBDIR -lnetcdff -lnetcdf" ;;
      NC4) if [ "$mpi_mod" = 'no' ]; then comp="`$NETCDF_CONFIG --fc`"; fi
           libs="$libs `$NETCDF_CONFIG --flibs`" ;;
    esac
  fi

# 3.b Link

  $comp $opt $objects $libs                         > link.out 2> link.err
  OK="$?"

# --------------------------------------------------------------------------- #
# 4. Postprocessing                                                           #
# --------------------------------------------------------------------------- #

  if [ "$OK" != '0' ]
  then
    echo "      *** error in linking ***"
    echo ' '
    cat link.out
    echo ' '
    cat link.err
    echo ' '
    rm -f link.???
    rm -f $prog
    exit $OK
  else
    if [ ! -f $prog ]
    then
      echo "      *** program $prog not found ***"
      echo ' '
      cat link.out
      echo ' '
      cat link.err
      echo ' '
      rm -f link.???
      exit 1
    else
      mv $prog $main_dir/exe/.
      rm -f link.???
    fi
  fi

# end of link --------------------------------------------------------------- #
