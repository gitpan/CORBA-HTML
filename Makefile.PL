use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::HTML',
    'VERSION_FROM'  => 'html.pm',
    'ABSTRACT'      => 'HTML generator from IDL file',
    'PREREQ_PM'     => {
                        'CORBA::IDL::node'  => 2.00,
    },
    'PM'            => {
                        'html.pm'       => '$(INST_LIBDIR)/HTML/html.pm',
                        'index.pm'      => '$(INST_LIBDIR)/HTML/index.pm',
    },
    'EXE_FILES'     => ['idl2html.pl'],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);
