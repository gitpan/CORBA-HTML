#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use CORBA::IDL::parser30;
use CORBA::IDL::symbtab;
# visitors
use CORBA::IDL::repos_id;
use CORBA::HTML::index;
use CORBA::HTML::html;

use vars qw ($global);
unless (do "index.lst") {
	$global->{index_module} = {};
	$global->{index_interface} = {};
	$global->{index_value} = {};
}

my $parser = new Parser;
$parser->YYData->{verbose_error} = 1;		# 0, 1
$parser->YYData->{verbose_warning} = 1;		# 0, 1
$parser->YYData->{verbose_info} = 1;		# 0, 1
$parser->YYData->{verbose_deprecated} = 1;	# 0, 1 (concerns only version '2.4' and upper)
$parser->YYData->{symbtab} = new Symbtab($parser);
my $cflags = '-D__idl2html';
if ($Parser::IDL_version lt '3.0') {
	$cflags .= ' -D_PRE_3_0_COMPILER_';
}
# preprocessor must preserve comments
if ($^O eq 'MSWin32') {
	$parser->YYData->{preprocessor} = 'cpp -C ' . $cflags;
#	$parser->YYData->{preprocessor} = 'CL /E /C /nologo ' . $cflags;	# Microsoft VC
} else {
	$parser->YYData->{preprocessor} = 'cpp -C ' . $cflags;
}
$parser->getopts("fi:x");
$parser->Run(@ARGV);
$parser->YYData->{symbtab}->CheckForward();
$parser->YYData->{symbtab}->CheckRepositoryID();

if (exists $parser->YYData->{nb_error}) {
	my $nb = $parser->YYData->{nb_error};
	print "$nb error(s).\n"
}
if (        $parser->YYData->{verbose_warning}
		and exists $parser->YYData->{nb_warning} ) {
	my $nb = $parser->YYData->{nb_warning};
	print "$nb warning(s).\n"
}
if (        $parser->YYData->{verbose_info}
		and exists $parser->YYData->{nb_info} ) {
	my $nb = $parser->YYData->{nb_info};
	print "$nb info(s).\n"
}
if (        $parser->YYData->{verbose_deprecated}
		and exists $parser->YYData->{nb_deprecated} ) {
	my $nb = $parser->YYData->{nb_deprecated};
	print "$nb deprecated(s).\n"
}

if (        exists $parser->YYData->{root}
		and ! exists $parser->YYData->{nb_error} ) {
	$parser->YYData->{root}->visitName(new repositoryIdVisitor($parser));	# ?
	if (        $Parser::IDL_version ge '3.0'
			and $parser->YYData->{opt_x} ) {
		$parser->YYData->{symbtab}->Export();
	}
	$parser->YYData->{root}->visit(new indexVisitor($parser));
	$parser->YYData->{root}->visit(new htmlVisitor($parser));
}

if (open PERSISTANCE,"> index.lst") {
	print PERSISTANCE Data::Dumper->Dump([$global], [qw(global)]);
	close PERSISTANCE;
} else {
	warn "can't open index.lst.\n";
}

__END__

=head1 NAME

idl2html - Generates HTML documentation from IDL source files.

=head1 SYNOPSYS

idl2html [options] I<spec>.idl

=head1 OPTIONS

All options are forwarded to C preprocessor, except -f -i -x.

With the GNU C Compatible Compiler Processor, useful options are :

=over 8

=item B<-D> I<name>

=item B<-D> I<name>=I<definition>

=item B<-I> I<directory>

=item B<-I->

=item B<-nostdinc>

=back

Specific options :

=over 8

=item B<-f>

Enable the frameset mode.

=item B<-i> I<directory>

Specify a path for import (only for version 3.0).

=item B<-x>

Enable export (only for version 3.0).

=back

=head1 DESCRIPTION

B<idl2html> parses the declarations and doc comments in a IDL source file and
formats these into a set of HTML pages.

B<idl2html> works like B<javadoc>.

Within doc comments, B<idl2html> supports the use of special doc tags to
augment the documentation. B<idl2html> also supports standard HTML within doc
comments. This is useful for formatting text.

B<idl2html> reformats and displays declaration for:

=over 8

=item Modules, interfaces and value types

=item Operations (with parameters) and attributes

=item Types (typedef, enum, struct, union with members)

=item Exceptions (with members)

=item Constants

=item Pragma (ID, version as tag)

=back

=head2 Doc Comments

IDL source files can include doc comments. Doc comments begin  with /** and
indicate text to be included automatically in generated documentation.

Doc comments immediately preceed the entity being documented.

Single line comments beginning with /// are also included.

=head2 Standard HTML

You can embed standard HTML tags within a doc comment. However, don't use tags
heading tags like E<lt>h1E<gt> or E<lt>hrE<gt>. B<idl2html> creates an entire
structured document and these structural tags interfere with formatting of
the generated document.

=head2 idl2html Tags

B<idl2html> parses special tags that are recognized when they are embedded
within an IDL doc comment. These doc tags enable you to autogenerate a
complete, well-formatted document from your source code. The tags start with
an @.

Tags must start at the beginning of a line.

=head1 SPECIAL REQUIREMENTS

B<idl2html> needs Math::BigInt and Math::BigFloat modules.

B<idl2html> needs a B<cpp> executable or B<CL.EXE> for Microsoft Windows.

CORBA Specifications, including IDL (Interface Definition Language)
 are available on E<lt>http://www.omg.org/E<gt>.

=head1 SEE ALSO

cpp, javadoc

=head1 COPYRIGHT

(c) 2001-2003 Francois PERRAD, France. All rights reserved.

This program and all CORBA::HTML modules are distributed
under the terms of the Artistic Licence.

=head1 AUTHOR

Francois PERRAD, francois.perrad@gadz.org

=cut

