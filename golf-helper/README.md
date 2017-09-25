# Code Golf Helper Sample Application

This sample demonstrates the use of Perl 6's reactive programming features in
the context of a simple GUI application. It depends on the `GTK::Simple`
module, which in turn depends on the GTK libraries. On a Debian-based Linux,
those can be installed with:

    sudo apt-get install libgtk-3-dev

On Windows, pre-compiled DLLs are included as part of the Perl 6 module
installation. See the [GTK::Simple README](https://github.com/perl6/gtk-simple#gtksimple--)
for more information.

A `META6.json` file is included to install the `GTK::Simple` dependency; just
run:

    zef install --depsonly
