use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::HTML::html;

use vars qw($VERSION);
$VERSION = '2.41';

package CORBA::HTML::htmlVisitor;

use File::Basename;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my ($parser) = @_;
	$self->{parser} = $parser;
	$self->{symbtab} = $parser->YYData->{symbtab};
	$self->{frameset} = exists $parser->YYData->{opt_f};
	$self->{html_name} = new CORBA::HTML::nameVisitor($parser);
	$self->{html_decl} = new CORBA::HTML::declVisitor($self);
	$self->{html_comment} = new CORBA::HTML::commentVisitor($self);
	$self->{scope} = '';
	$self->{css} = $parser->YYData->{opt_s};
	$self->{style} = q{
        a.index { font-weight : bold; }
        h2 { color : red; }
        p.comment { color : green; }
        span.comment { color : green; }
        span.decl { font-weight : bold; }
        span.tag { font-weight : bold; }
        hr { text-align : center; }
	};
	return $self;
}

sub _get_defn {
	my $self = shift;
	my($defn) = @_;
	if (ref $defn) {
		return $defn;
	} else {
		return $self->{symbtab}->Lookup($defn);
	}
}

sub _get_name {
	my $self = shift;
	my ($node) = @_;
	return $node->visit($self->{html_name}, $self->{scope});
}

sub _print_decl {
	my $self = shift;
	my ($node) = @_;
	$node->visit($self->{html_decl}, \*OUT);
}

sub _print_comment {
	my $self = shift;
	my ($node) = @_;
	$node->visit($self->{html_comment}, \*OUT);
	print OUT "  <p />\n";
}

sub _sep_line {
	my $self = shift;
	print OUT "    <hr />\n";
}

sub _format_head {
	my $self = shift;
	my ($title, $frameset, $target) = @_;
	my $now = localtime();
#	print OUT "<?xml version='1.0' encoding='ISO-8859-1'?>\n";
	if ($frameset) {
		print OUT "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Frameset//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd'>\n";
	} else {
		print OUT "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'>\n";
	}
	print OUT "<html xmlns='http://www.w3.org/1999/xhtml'>\n";
	print OUT "\n";
	print OUT "  <head>\n";
	print OUT "    <meta name='generator' content='idl2html ",$CORBA::HTML::html::VERSION," (Perl ",$],")' />\n";
	print OUT "    <meta name='date' content='",$now,"' />\n";
	print OUT "    <meta http-equiv='Content-Type' content='text/html; charset=ISO-8859-1' />\n";
	print OUT "    <title>",$title,"</title>\n" if ($title);
	unless ($frameset) {
		print OUT "    <base target='",$target,"' />\n" if (defined $target);
		if ($self->{css}) {
			print OUT "    <link href='",$self->{css},".css' rel='stylesheet' type='text/css'/>\n";
		} else {
			print OUT "    <style type='text/css'>\n";
			print OUT $self->{style},"\n";
			print OUT "    </style>\n";
		}
	}
	print OUT "  </head>\n";
	print OUT "\n";
}

sub _format_head_main {
	my $self = shift;
	my ($title) = @_;
	$self->_format_head($title, 0);
	print OUT "  <body>\n";
	print OUT "    <h1><a id='__Top__' name='__Top__'/>",$title,"</h1>\n";
	print OUT "    <p><a href='index.html'>Global index</a></p>\n"
			unless ($self->{frameset});
	print OUT "    <hr />\n";
}

sub _format_head_global_index {
	my $self = shift;
	my $title = "Global index";
	if ($self->{frameset}) {
		$self->_format_head($title, 0, "local");
		print OUT "  <body>\n";
	} else {
		$self->_format_head($title, 0);
		print OUT "  <body>\n";
		print OUT "    <h1><a id='__Top__' name='__Top__'/>",$title,"</h1>\n";
		print OUT "    <hr />\n";
	}
}

sub _format_head_index {
	my $self = shift;
	my ($title) = @_;
	$self->_format_head("Index " . $title, 0, "main");
	print OUT "  <body>\n";
	print OUT "    <h1><a href='_",$title,".html#__Top__'>",$title,"</a></h1>\n";
}

sub _format_tail {
	my $self = shift;
	my ($frameset) = @_;
	unless ($frameset) {
		print OUT "\n";
		print OUT "  </body>\n";
	}
	print OUT "\n";
	print OUT "</html>\n";
}

sub _format_index {
	my $self = shift;
	my ($node, $rlist) = @_;
	my $nb = 0;
	foreach (@{$rlist}) {
		my $idx = 'index_' . $_;
		if (keys %{$node->{$idx}}) {
			$nb ++;
			my $title = ucfirst $_;
			$title =~ s/_/ /g;
			print OUT "<h2>",$title," index.</h2>\n";
			print OUT "<dl>\n";
			foreach (sort keys %{$node->{$idx}}) {
				my $child = $node->{$idx}->{$_};
				print OUT "    <dt><a class='index' href='",$child->{file_html},"#",$_,"'>";
				print OUT $_,"</a></dt>\n";
			}
			print OUT "</dl>\n";
		}
	}
	unless ($self->{frameset}) {
		$self->_sep_line() if ($nb);
	}
}

sub _format_decl {
	my $self = shift;
	my ($node, $rlist) = @_;
	my $nb = 0;
	foreach (@{$rlist}) {
		my $idx = 'index_' . $_;
		if (keys %{$node->{$idx}}) {
			$nb ++;
			my $title = ucfirst $_;
			$title =~ s/_/ /g;
			print OUT "<h2>",$title,"s.</h2>\n";
			if (scalar keys %{$node->{$idx}}) {
				print OUT "<ul>\n";
				foreach (sort keys %{$node->{$idx}}) {
					my $child = $node->{$idx}->{$_};
					print OUT "    <li>\n";
					print OUT "      <h3><a id='",$_,"' name='",$_,"'/>",$_,"</h3>\n";
					$self->_print_decl($child);
					$self->_print_comment($child);
					print OUT "    </li>\n";
				}
				print OUT "</ul>\n";
			}
		}
	}
	$self->_sep_line() if ($nb);
	print OUT "    <div><cite>Generated by idl2html</cite></div>\n";
}

sub _format_decl_file {
	my $self = shift;
	my ($node, $rlist, $filename) = @_;
	my $nb = 0;
	foreach (@{$rlist}) {
		my $idx = 'index_' . $_;
		if (keys %{$node->{$idx}}) {
			$nb ++;
			my $title = ucfirst $_;
			$title =~ s/_/ /g;
			print OUT "<h2>",$title,"s.</h2>\n";
			if (scalar keys %{$node->{$idx}}) {
				my $n = 0;
				foreach (sort values %{$node->{$idx}}) {
					$n ++ if ($_->{filename} eq $filename);
				}
				if ($n) {
					print OUT "<ul>\n";
					foreach (sort keys %{$node->{$idx}}) {
						my $child = $node->{$idx}->{$_};
						next unless ($child->{filename} eq $filename);
						print OUT "    <li>\n";
						print OUT "      <h3><a id='",$_,"' name='",$_,"'/>",$_,"</h3>\n";
						$self->_print_decl($child);
						$self->_print_comment($child);
						print OUT "    </li>\n";
					}
					print OUT "</ul>\n";
				}
			}
		}
	}
	$self->_sep_line() if ($nb);
	print OUT "    <div><cite>Generated by idl2html</cite></div>\n";
}

sub _examine_index {
	my $self = shift;
	my ($node, $idx, $htree) = @_;

	while (my ($idf, $defn) = each %{$node->{index_module}}) {
		$htree->{$idf} = {}
				if (!exists $htree->{$idf} or $htree->{$idf} == 1);
		$self->_examine_index($defn, $idx, $htree->{$idf});
		delete $htree->{$idf}
				unless (scalar keys %{$htree->{$idf}});
	}
	foreach (keys %{$node->{$idx}}) {
		$htree->{$_} = 1
				unless (exists $htree->{$_});
	}
}

sub _format_global_index {
	my $self = shift;
	my ($idx, $htree, $basename) = @_;

	print OUT "<ul>\n";
	foreach (sort keys %{$htree}) {
		my $full = $basename ? $basename . "::" . $_ : $_;
		my $filename = $full;
		$filename =~ s/::/_/g;
		$self->{first_filename} = $filename
				unless (exists $self->{first_filename});
		if ($self->{frameset}) {
			print OUT "    <li><a class='index' href='index._",$filename,".html'>";
		} else {
			print OUT "    <li><a class='index' href='_",$filename,".html#__Top__'>";
		}
		if ($htree->{$_} == 1) {
			print OUT $full,"</a></li>\n";
		} else {
			print OUT $full,"</a>\n";
			$self->_format_global_index($idx, $htree->{$_}, $full);
			print OUT "</li>\n";
		}
	}
	print OUT "</ul>\n";
}

sub _format_toc {
	my $self = shift;
	my ($idx, $htree, $basename) = @_;

	print OUT "        <UL>\n";		# no XHTML
	foreach (sort keys %{$htree}) {
		my $full = $basename ? $basename . "::" . $_ : $_;
		my $filename = $full;
		$filename =~ s/::/_/g;
		print OUT "          <LI> <OBJECT type=\"text/sitemap\">\n";
		print OUT "              <param name=\"Name\" value=\"",$_,"\">\n";
		print OUT "              <param name=\"Local\" value=\"_",$filename,".html\">\n";
		print OUT "            </OBJECT>\n";
		unless ($htree->{$_} == 1) {
			$self->_format_toc($idx, $htree->{$_}, $full);
		}
	}
	print OUT "        </UL>\n";
}

#
#	3.5		OMG IDL Specification
#

sub visitSpecification {
	my $self = shift;
	my ($node) = @_;

	my @list_call = (
		'module',
		'interface',
		'value',
		'event',
		'component',
		'home'
	);
	foreach (@list_call) {
		my $idx = 'index_' . $_;
		foreach (values %{$node->{$idx}}) {
			$_->visit($self);
		}
	}

	my @list_decl = (
		'boxed_value',
		'type',
		'exception',
		'constant'
	);
	my %alone;
	foreach (@list_decl) {
		my $idx = 'index_' . $_;
		foreach (values %{$node->{$idx}}) {
			my $defn = $self->_get_defn($_);
			$alone{$defn->{filename}} = 1;
		}
	}
	foreach (keys %alone) {
		my $filename = "__" . basename($_, ".idl") . ".html";
		open OUT,"> $filename"
				or die "can't open $filename ($!).\n";

		$self->_format_head_main($filename);
		$self->_format_decl_file($node, \@list_decl, $_);
		$self->_format_tail(0);

		close OUT;
	}

	foreach (@list_call) {
		my $idx = 'index_' . $_;
		$self->_examine_index($node, $idx, $main::global->{$idx});
	}
	my $nb = 0;
	foreach (@list_call) {
		my $idx = 'index_' . $_;
		foreach (sort keys %{$main::global->{$idx}}) {
			$nb ++;
		}
	}
	if ($nb) {
		open OUT,"> index.html"
				or die "can't open index.html ($!).\n";
		$self->{out} = \*OUT;

		$self->_format_head_global_index();
		foreach (@list_call) {
			my $idx = 'index_' . $_;
			if (keys %{$main::global->{$idx}}) {
				my $title = ucfirst $_;
				print OUT "<h2>All ",$title," index.</h2>\n";
				$self->_format_global_index($idx, $main::global->{$idx}, "");
			}
		}
		unless ($self->{frameset}) {
			$self->_sep_line();
			print OUT "    <div><cite>Generated by idl2html</cite></div>\n";
		}
		$self->_format_tail(0);

		close OUT;
	}

	if ($self->{frameset}) {
		open OUT,"> frame.html"
				or die "can't open frame.html ($!).\n";
		$self->{out} = \*OUT;

		$self->_format_head("Global index", 1);
		print OUT "  <frameset cols='25%,75%'>\n";
		print OUT "    <frameset rows='40%,60%'>\n";
		print OUT "      <frame src='index.html' id='global' name='global'/>\n";
		print OUT "      <frame src='index._",$self->{first_filename},"' id='local' name='local'/>\n";
		print OUT "    </frameset>\n";
		print OUT "    <frame src='_",$self->{first_filename},"#__Top__' id='main' name='main'/>\n";
		print OUT "    <noframes>\n";
		print OUT "      <body>\n";
		print OUT "        <h1>Sorry!</h1>\n";
		print OUT "        <h3>This page must be viewed by a browser that is capable of viewing frames.</h3>\n";
		print OUT "      </body>\n";
		print OUT "    </noframes>\n";
		print OUT "  </frameset>\n";
		$self->_format_tail(1);

		close OUT;
	} else {
		my $outfile = $self->{parser}->YYData->{opt_o} || "htmlhelp";
		open OUT,"> $outfile.hhp"
				or die "can't open $outfile.hhp ($!).\n";

		my $title = $self->{parser}->YYData->{opt_t};
		print OUT "[OPTIONS]\n";
		print OUT "Binary TOC=Yes\n";
		print OUT "Compatibility=1.1 or later\n";
		print OUT "Compiled file=",$outfile,".chm\n";
		print OUT "Contents file=toc.hhc\n";
		print OUT "Default Window=Main\n";
		print OUT "Default topic=index.html\n";
		print OUT "Display compile progress=Yes\n";
		print OUT "Full-text search=Yes\n";
		print OUT "Index file=index.hhk\n";
		print OUT "Language=0x0409 English (UNITED STATES)\n";
		print OUT "Title=",$title,"\n" if ($title);
		print OUT "\n";
		print OUT "[WINDOWS]\n";
		print OUT "Main=,\"toc.hhc\",\"index.hhk\",\"index.html\",\"index.html\",,,,,0x22520,,0x603006,,,,,,,,0\n";
		print OUT "\n";
		print OUT "[FILES]\n";
		print OUT "index.html\n";
		foreach (@list_call) {
			my $idx = 'index_' . $_;
			foreach (sort keys %{$main::global->{$idx}}) {
				print OUT "_",$_,".html\n"
						if ($main::global->{$idx}->{$_} == 1 or $idx eq "index_module");
			}
		}

		close OUT;

		open OUT,"> toc.hhc"
				or die "can't open toc.hhc ($!).\n";

		print OUT "<HTML>\n";		# no XHTML
		print OUT "  <HEAD>\n";
		print OUT "    <meta name=\"generator\" content=\"idl2html ",$CORBA::HTML::html::VERSION," (Perl ",$],")\">\n";
		print OUT "  </HEAD>\n";
		print OUT "  <BODY>\n";
		print OUT "    <OBJECT type=\"text/site properties\">\n";
		print OUT "      <param name=\"ImageType\" value=\"Folder\">\n";
		print OUT "    </OBJECT>\n";
		print OUT "    <UL>\n";
		foreach (@list_call) {
			my $idx = 'index_' . $_;
			if (keys %{$main::global->{$idx}}) {
				my $title = ucfirst $_;
				print OUT "      <LI> <OBJECT type=\"text/sitemap\">\n";
				print OUT "          <param name=\"Name\" value=\"",$title,"\">\n";
				print OUT "          <param name=\"ImageNumber\" value=\"1\">\n";
				print OUT "        </OBJECT>\n";
				$self->_format_toc($idx, $main::global->{$idx}, "");
			}
		}
		print OUT "    </UL>\n";
		print OUT "  </BODY>\n";
		print OUT "</HTML>\n";

		close OUT;

		foreach my $scope (values %{$self->{symbtab}->{scopes}}) {
			foreach my $defn (values %{$scope->{entry}}) {
				next unless (exists $defn->{file_html});
				if (       $defn->isa('StateMember')
						or $defn->isa('Initializer')
						or $defn->isa('BoxedValue')
						or $defn->isa('Constant')
						or $defn->isa('TypeDeclarator')
						or $defn->isa('StructType')
						or $defn->isa('UnionType')
						or $defn->isa('EnumType')
						or $defn->isa('Enum')
						or $defn->isa('Exception')
						or $defn->isa('Provides')
						or $defn->isa('Uses')
						or $defn->isa('Emits')
						or $defn->isa('Publishes')
						or $defn->isa('Consumes')
						or $defn->isa('Factory')
						or $defn->isa('Finder') ) {
					my $anchor = $defn->{file_html} . "#" . $defn->{idf};
					$main::global->{index_entry}->{$anchor} = $defn->{idf};
				}
			}
		}

		open OUT,"> index.hhk"
				or die "can't open index.hhk ($!).\n";

		print OUT "<HTML>\n";		# no XHTML
		print OUT "  <HEAD>\n";
		print OUT "    <meta name=\"generator\" content=\"idl2html ",$CORBA::HTML::html::VERSION," (Perl ",$],")\">\n";
		print OUT "  </HEAD>\n";
		print OUT "  <BODY>\n";
		print OUT "    <UL>\n";
		while (my ($key, $val) = each %{$main::global->{index_entry}}) {
			print OUT "      <LI> <OBJECT type=\"text/sitemap\">\n";
			print OUT "          <param name=\"Name\" value=\"",$val,"\">\n";
			print OUT "          <param name=\"Local\" value=\"",$key,"\">\n";
			print OUT "        </OBJECT>\n";
		}
		print OUT "    </UL>\n";
		print OUT "  </BODY>\n";
		print OUT "</HTML>\n";

		close OUT;
	}
	if ($self->{css}) {
		my $outfile = $self->{css} . ".css";
		unless ( -e $outfile) {
			open OUT, "> $outfile"
					or die "can't open $outfile ($!)\n";
			print OUT $self->{style};
			close OUT;
		}
	}
}

#
#	3.7		Module Declaration
#

sub visitModules {
	my $self = shift;
	my ($node) = @_;
	my $scope_save = $self->{scope};
	$self->{scope} = $node->{full};
	$self->{scope} =~ s/^:://;
	my $title = $self->{scope};
	my @list_call = (
		'module',
		'interface',
		'value',
		'event',
		'component',
		'home'
	);
	my @list_idx = (
		'module',
		'interface',
		'value',
		'type',
		'exception',
		'constant',
		'event',
		'component',
		'home'
	);
	my @list_decl = (
		'boxed_value',
		'type',
		'exception',
		'constant'
	);

	foreach (@list_call) {
		my $idx = 'index_' . $_;
		foreach (values %{$node->{$idx}}) {
			$_->visit($self);
		}
	}

	foreach (keys %{$node->{index_boxed_value}}) {
		$node->{index_value}->{$_} = $node->{index_boxed_value}->{$_};
	}

	open OUT,"> $node->{file_html}"
			or die "can't open $node->{file_html} ($!).\n";

	$self->_format_head_main("Module " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node, \@list_idx)
			unless ($self->{frameset});
	$self->_format_decl($node, \@list_decl);
	$self->_format_tail(0);

	close OUT;

	if ($self->{frameset}) {
		open OUT,"> index.$node->{file_html}"
				or die "can't open index.$node->{file_html} ($!).\n";

		$self->_format_head_index($title);
		$self->_format_index($node, \@list_idx);
		$self->_format_tail(0);

		close OUT;
	}

	$self->{scope} = $scope_save;
}

#
#	3.8		Interface Declaration
#

sub visitRegularInterface {
	my $self = shift;
	my ($node) = @_;
	my $scope_save = $self->{scope};
	$self->{scope} = $node->{full};
	$self->{scope} =~ s/^:://;
	my $title = $self->{scope};
	my @list = (
		'operation',
		'attribute',
		'type',
		'exception',
		'constant'
	);
	open OUT,"> $node->{file_html}"
			or die "can't open $node->{file_html} ($!).\n";

	$self->_format_head_main("Interface " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node, \@list)
			unless ($self->{frameset});
	$self->_format_decl($node, \@list);
	$self->_format_tail(0);

	close OUT;

	if ($self->{frameset}) {
		open OUT,"> index.$node->{file_html}"
				or die "can't open index.$node->{file_html} ($!).\n";

		$self->_format_head_index($title);
		$self->_format_index($node, \@list);
		$self->_format_tail(0);

		close OUT;
	}

	$self->{scope} = $scope_save;
}

sub visitAbstractInterface {
	my $self = shift;
	my ($node) = @_;
	my $scope_save = $self->{scope};
	$self->{scope} = $node->{full};
	$self->{scope} =~ s/^:://;
	my $title = $self->{scope};
	my @list = (
		'operation',
		'attribute',
		'type',
		'exception',
		'constant'
	);
	open OUT,"> $node->{file_html}"
			or die "can't open $node->{file_html} ($!).\n";

	$self->_format_head_main("Abstract Interface " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node, \@list)
			unless ($self->{frameset});
	$self->_format_decl($node, \@list);
	$self->_format_tail(0);

	close OUT;

	if ($self->{frameset}) {
		open OUT,"> index.$node->{file_html}"
				or die "can't open index.$node->{file_html} ($!).\n";

		$self->_format_head_index($title);
		$self->_format_index($node, \@list);
		$self->_format_tail(0);

		close OUT;
	}

	$self->{scope} = $scope_save;
}

sub visitLocalInterface {
	my $self = shift;
	my ($node) = @_;
	my $scope_save = $self->{scope};
	$self->{scope} = $node->{full};
	$self->{scope} =~ s/^:://;
	my $title = $self->{scope};
	my @list = (
		'operation',
		'attribute',
		'type',
		'exception',
		'constant'
	);
	open OUT,"> $node->{file_html}"
			or die "can't open $node->{file_html} ($!).\n";

	$self->_format_head_main("Local Interface " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node, \@list)
			unless ($self->{frameset});
	$self->_format_decl($node, \@list);
	$self->_format_tail(0);

	close OUT;

	if ($self->{frameset}) {
		open OUT,"> index.$node->{file_html}"
				or die "can't open index.$node->{file_html} ($!).\n";

		$self->_format_head_index($title);
		$self->_format_index($node, \@list);
		$self->_format_tail(0);

		close OUT;
	}

	$self->{scope} = $scope_save;
}

#
#	3.9		Value Declaration
#

sub visitRegularValue {
	my $self = shift;
	my ($node) = @_;
	$self->{scope} = $node->{full};
	$self->{scope} =~ s/^:://;
	my $title = $self->{scope};
	my @list = (
		'operation',
		'attribute',
		'type',
		'exception',
		'constant',
		'state_member',
		'initializer'
	);
	open OUT,"> $node->{file_html}"
			or die "can't open $node->{file_html} ($!).\n";

	$self->_format_head_main("Value Type " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node, \@list)
			unless ($self->{frameset});
	$self->_format_decl($node, \@list);
	$self->_format_tail(0);

	close OUT;

	if ($self->{frameset}) {
		open OUT,"> index.$node->{file_html}"
				or die "can't open index.$node->{file_html} ($!).\n";

		$self->_format_head_index($title);
		$self->_format_index($node, \@list);
		$self->_format_tail(0);

		close OUT;
	}
}

sub visitAbstractValue {
	my $self = shift;
	my ($node) = @_;
	$self->{scope} = $node->{full};
	$self->{scope} =~ s/^:://;
	my $title = $self->{scope};
	my @list = (
		'operation',
		'attribute',
		'type',
		'exception',
		'constant'
	);
	open OUT,"> $node->{file_html}"
			or die "can't open $node->{file_html} ($!).\n";

	$self->_format_head_main("Abstract Value Type " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node, \@list)
			unless ($self->{frameset});
	$self->_format_decl($node, \@list);
	$self->_format_tail(0);

	close OUT;

	if ($self->{frameset}) {
		open OUT,"> index.$node->{file_html}"
				or die "can't open index.$node->{file_html} ($!).\n";

		$self->_format_head_index($title);
		$self->_format_index($node, \@list);
		$self->_format_tail(0);

		close OUT;
	}
}

#
#	3.16	Event Declaration
#

sub visitRegularEvent {
	my $self = shift;
	my ($node) = @_;
	$self->{scope} = $node->{full};
	$self->{scope} =~ s/^:://;
	my $title = $self->{scope};
	my @list = (
		'operation',
		'attribute',
		'type',
		'exception',
		'constant',
		'state_member',
		'initializer'
	);
	open OUT,"> $node->{file_html}"
			or die "can't open $node->{file_html} ($!).\n";

	$self->_format_head_main("Event Type " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node, \@list)
			unless ($self->{frameset});
	$self->_format_decl($node, \@list);
	$self->_format_tail(0);

	close OUT;

	if ($self->{frameset}) {
		open OUT,"> index.$node->{file_html}"
				or die "can't open index.$node->{file_html} ($!).\n";

		$self->_format_head_index($title);
		$self->_format_index($node, \@list);
		$self->_format_tail(0);

		close OUT;
	}
}

sub visitAbstractEvent {
	my $self = shift;
	my ($node) = @_;
	$self->{scope} = $node->{full};
	$self->{scope} =~ s/^:://;
	my $title = $self->{scope};
	my @list = (
		'operation',
		'attribute',
		'type',
		'exception',
		'constant'
	);
	open OUT,"> $node->{file_html}"
			or die "can't open $node->{file_html} ($!).\n";

	$self->_format_head_main("Abstract Event Type " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node, \@list)
			unless ($self->{frameset});
	$self->_format_decl($node, \@list);
	$self->_format_tail(0);

	close OUT;

	if ($self->{frameset}) {
		open OUT,"> index.$node->{file_html}"
				or die "can't open index.$node->{file_html} ($!).\n";

		$self->_format_head_index($title);
		$self->_format_index($node, \@list);
		$self->_format_tail(0);

		close OUT;
	}
}

#
#	3.17	Component Declaration
#

sub visitComponent {
	my $self = shift;
	my ($node) = @_;
	$self->{scope} = $node->{full};
	$self->{scope} =~ s/^:://;
	my $title = $self->{scope};
	my @list = (
		'provides',
		'uses',
		'publishes',
		'consumes',
		'attribute'
	);
	open OUT,"> $node->{file_html}"
			or die "can't open $node->{file_html} ($!).\n";

	$self->_format_head_main("Component " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node, \@list)
			unless ($self->{frameset});
	$self->_format_decl($node, \@list);
	$self->_format_tail(0);

	close OUT;

	if ($self->{frameset}) {
		open OUT,"> index.$node->{file_html}"
				or die "can't open index.$node->{file_html} ($!).\n";

		$self->_format_head_index($title);
		$self->_format_index($node, \@list);
		$self->_format_tail(0);

		close OUT;
	}
}

#
#	3.18	Home Declaration
#

sub visitHome {
	my $self = shift;
	my ($node) = @_;
	$self->{scope} = $node->{full};
	$self->{scope} =~ s/^:://;
	my $title = $self->{scope};
	my @list = (
		'operation',
		'attribute',
		'type',
		'exception',
		'constant',
		'factory',
		'finder'
	);
	open OUT,"> $node->{file_html}"
			or die "can't open $node->{file_html} ($!).\n";

	$self->_format_head_main("Home " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node, \@list)
			unless ($self->{frameset});
	$self->_format_decl($node, \@list);
	$self->_format_tail(0);

	close OUT;

	if ($self->{frameset}) {
		open OUT,"> index.$node->{file_html}"
				or die "can't open index.$node->{file_html} ($!).\n";

		$self->_format_head_index($title);
		$self->_format_index($node, \@list);
		$self->_format_tail(0);

		close OUT;
	}
}

##############################################################################

package CORBA::HTML::declVisitor;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	$self->{parent} = shift;
	return $self;
}

sub _get_defn {
	my $self = shift;
	my ($defn) = @_;
	if (ref $defn) {
		return $defn;
	} else {
		return $self->{parent}->{symbtab}->Lookup($defn);
	}
}

sub _get_name {
	my $self = shift;
	my ($node) = @_;
	unless (ref $node) {
		$node = $self->{parent}->{symbtab}->Lookup($node);
	}
	return $node->visit($self->{parent}->{html_name}, $self->{parent}->{scope});
}

sub _xp {
	my $self = shift;
	my ($node, $FH) = @_;
	if (exists $node->{declspec}) {
		print $FH "<em>__declspec(",$node->{declspec},")</em>\n";
		print $FH "  ";
	}
	if (exists $node->{props}) {
		print $FH "<em>[";
		my $first = 1;
		while (my ($key, $value) = each (%{$node->{props}})) {
			print $FH ", " unless ($first);
			print $FH $key;
			print $FH " (",$value,")" if (defined $value);
			$first = 0;
		}
		print $FH "]</em>\n";
		print $FH "  ";
	}
}

sub _xp_props {
	my $self = shift;
	my ($node, $FH) = @_;
	if (exists $node->{props}) {
		print $FH "<em>[";
		my $first = 1;
		while (my ($key, $value) = each (%{$node->{props}})) {
			print $FH ", " unless ($first);
			print $FH $key;
			print $FH " (",$value,")" if (defined $value);
			$first = 0;
		}
		print $FH "]</em> ";
	}
}

#
#	3.6		Module Declaration
#

sub visitModules {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "module <span class='decl'>",$node->{idf},"</span>\n";
	print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
			if (exists $node->{typeprefix});
	print $FH "</pre>\n";
}

#
#	3.8		Interface Declaration
#

sub visitRegularInterface {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "interface <span class='decl'>",$node->{idf},"</span>";
		if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
			print $FH " : ";
			my $first = 1;
			foreach (@{$node->{inheritance}->{list_interface}}) {
				print $FH ", " unless ($first);
				print $FH $self->_get_name($_);
				$first = 0;
			}
		}
		print $FH ";\n";
	print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
			if (exists $node->{typeprefix});
	print $FH "</pre>\n";
}

sub visitAbstractInterface {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "abstract interface <span class='decl'>",$node->{idf},"</span>";
		if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
			print $FH " : ";
			my $first = 1;
			foreach (@{$node->{inheritance}->{list_interface}}) {
				print $FH ", " unless ($first);
				print $FH $self->_get_name($_);
				$first = 0;
			}
		}
		print $FH ";\n";
	print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
			if (exists $node->{typeprefix});
	print $FH "</pre>\n";
}

sub visitLocalInterface {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "local interface <span class='decl'>",$node->{idf},"</span>";
		if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
			print $FH " : ";
			my $first = 1;
			foreach (@{$node->{inheritance}->{list_interface}}) {
				print $FH ", " unless ($first);
				print $FH $self->_get_name($_);
				$first = 0;
			}
		}
		print $FH ";\n";
	print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
			if (exists $node->{typeprefix});
	print $FH "</pre>\n";
}

#
#	3.9		Value Declaration
#
#	3.9.1	Regular Value Type
#

sub visitRegularValue {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "custom "
				if (exists $node->{modifier});
		print $FH "value <span class='decl'>",$node->{idf},"</span>";
		if (exists $node->{inheritance}) {
			my $inheritance = $node->{inheritance};
			print $FH " : ";
			if (exists $inheritance->{list_value}) {
				print $FH "truncatable " if (exists $inheritance->{modifier});
				my $first = 1;
				foreach (@{$inheritance->{list_value}}) {
					print $FH ", " if (! $first);
					print $FH $self->_get_name($_);
					$first = 0;
				}
				print $FH " ";
			}
			if (exists $inheritance->{list_interface}) {
				print $FH "support ";
				my $first = 1;
				foreach (@{$inheritance->{list_interface}}) {
					print $FH ", " if (! $first);
					print $FH $self->_get_name($_);
					$first = 0;
				}
			}
		}
		print $FH ";\n";
	print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
			if (exists $node->{typeprefix});
	print $FH "</pre>\n";
}

sub visitStateMember {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH $node->{modifier}," ";
		print $FH $self->_get_name($node->{type});
		print $FH " <span class='decl'>",$node->{idf},"</span>";
		if (exists $node->{array_size}) {
			foreach (@{$node->{array_size}}) {
				print $FH "[";
				$_->visit($self, $FH);			# expression
				print $FH "]";
			}
		}
		print $FH ";\n";
	print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

sub visitInitializer {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "factory <span class='decl'>",$node->{idf},"</span> (";
	my $first = 1;
	foreach (@{$node->{list_param}}) {	# parameter
		print $FH "," unless ($first);
		print $FH "\n";
		print $FH "    ";
		$self->_xp_props($_, $FH);
		print $FH $_->{attr}," ",$self->_get_name($_->{type})," ",$_->{idf};
		$first = 0;
	}
	print $FH "\n";
	print $FH "  )";
	if (exists $node->{list_raise}) {
		print $FH " raises(";
		my $first = 1;
		foreach (@{$node->{list_raise}}) {	# exception
			print $FH ", " unless ($first);
			print $FH $self->_get_name($_);
			$first = 0;
	    }
	    print $FH ")";
	}
	print $FH ";\n";
	print $FH "</pre>\n";
}

#	3.9.2	Boxed Value Type
#

sub visitBoxedValue {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "valuetype ";
		print $FH "<span class='decl'>",$node->{idf},"</span> ";
		print $FH $self->_get_name($node->{type});
		print $FH ";\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "  typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
			if (exists $node->{typeprefix});
	print $FH "</pre>\n";
}

#	3.9.3	Abstract Value Type
#

sub visitAbstractValue {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "abstract valuetype <span class='decl'>",$node->{idf},"</span>";
		if (exists $node->{inheritance}) {
			my $inheritance = $node->{inheritance};
			print $FH " : ";
			if (exists $inheritance->{list_value}) {
				print $FH "truncatable " if (exists $inheritance->{modifier});
				my $first = 1;
				foreach (@{$inheritance->{list_value}}) {
					print $FH ", " if (! $first);
					print $FH $self->_get_name($_);
					$first = 0;
				}
				print $FH " ";
			}
			if (exists $inheritance->{list_interface}) {
				print $FH "support ";
				my $first = 1;
				foreach (@{$inheritance->{list_interface}}) {
					print $FH ", " if (! $first);
					print $FH $self->_get_name($_);
					$first = 0;
				}
			}
		}
		print $FH ";\n";
	print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
			if (exists $node->{typeprefix});
	print $FH "</pre>\n";
}

#
#	3.10	Constant Declaration
#

sub visitConstant {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "constant ";
		print $FH $self->_get_name($node->{type});
		print $FH " <span class='decl'>",$node->{idf},"</span> = ";
		$node->{value}->visit($self, $FH);		# expression
		print $FH ";\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

sub visitExpression {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH $self->_get_name($node);
}

#
#	3.11	Type Declaration
#

sub visitTypeDeclarator {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "typedef ";
		print $FH $self->_get_name($node->{type});
		print $FH " <span class='decl'>",$node->{idf},"</span>";
		if (exists $node->{array_size}) {
			foreach (@{$node->{array_size}}) {
				print $FH "[";
				$_->visit($self, $FH);				# expression
				print $FH "]";
			}
		}
		print $FH ";\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

sub visitNativeType {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "native ";
		print $FH " <span class='decl'>",$node->{idf},"</span>";
		print $FH " (",$node->{native},")" if (exists $node->{native});	# XPIDL
		print $FH ";\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

#
#	3.11.2	Constructed Types
#
#	3.11.2.1	Structures
#

sub visitStructType {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "struct <span class='decl'>",$node->{html_name},"</span> {\n";
	foreach (@{$node->{list_expr}}) {
		$_->visit($self, $FH);				# members
	}
	print $FH "  };\n";
	print $FH "</pre>\n";
}

sub visitMembers {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "    ",$self->_get_name($node->{type});
	my $first = 1;
	foreach (@{$node->{list_member}}) {
		if ($first) {
			$first = 0;
		} else {
			print $FH ",";
		}
		$self->_get_defn($_)->visit($self, $FH);		# member
	}
	print $FH ";\n";
}

sub visitMember {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH " ",$node->{idf};
	if (exists $node->{array_size}) {
		foreach (@{$node->{array_size}}) {
			print $FH "[";
			$_->visit($self, $FH);				# expression
			print $FH "]";
		}
	}
}

#	3.11.2.2	Discriminated Unions
#

sub visitUnionType {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "union <span class='decl'>",$node->{html_name},"</span> switch(";
		print $FH $self->_get_name($node->{type});
		print $FH ") {\n";
	foreach (@{$node->{list_expr}}) {
		$_->visit($self, $FH);				# case
	}
	print $FH "  };\n";
	print $FH "</pre>\n";
}

sub visitCase {
	my $self = shift;
	my ($node, $FH) = @_;
	foreach (@{$node->{list_label}}) {
		if ($_->isa('Default')) {
			print $FH "    default:\n";
		} else {
			print $FH "    case ";
			$_->visit($self, $FH);			# expression
			print $FH ":\n";
		}
	}
	$node->{element}->visit($self, $FH);
}

sub visitElement {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "      ",$self->_get_name($node->{type});
	$self->_get_defn($node->{value})->visit($self, $FH);		# member
	print $FH ";\n";
}

#	3.11.2.4	Enumerations
#

sub visitEnumType {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "enum <span class='decl'>",$node->{html_name},"</span> {\n";
	my $first = 1;
	foreach (@{$node->{list_expr}}) {	# enum
		print $FH ",\n" unless ($first);
		print $FH "    <a id='",$_->{idf},"' name='",$_->{idf},"'/>",$_->{idf};
		$first = 0;
	}
	print $FH "\n";
	print $FH "  };\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

#
#	3.12	Exception Declaration
#

sub visitException {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "exception <span class='decl'>",$node->{idf},"</span> {\n";
	foreach (@{$node->{list_expr}}) {
		$_->visit($self, $FH);				# members
	}
	print $FH "  };\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

#
#	3.13	Operation Declaration
#

sub visitOperation {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "oneway " if (exists $node->{modifier});
		print $FH $self->_get_name($node->{type});
		print $FH " <span class='decl'>",$node->{idf},"</span> (";
	my $first = 1;
	foreach (@{$node->{list_param}}) {	# parameter
		print $FH "," unless ($first);
		print $FH "\n";
		print $FH "    ";
		if ($_->isa('Ellipsis')) {
			print $FH "...";
		} else {
			$self->_xp_props($_, $FH);
			print $FH $_->{attr}," ",$self->_get_name($_->{type})," ",$_->{idf};
		}
		$first = 0;
	}
	print $FH "\n";
	print $FH "  )";
	if (exists $node->{list_raise}) {
		print $FH " raises(";
		my $first = 1;
		foreach (@{$node->{list_raise}}) {	# exception
			print $FH ", " unless ($first);
			print $FH $self->_get_name($_);
			$first = 0;
	    }
	    print $FH ")";
	}
	print $FH ";\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

#
#	3.14	Attribute Declaration
#

sub visitAttribute {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		$self->_xp($node, $FH);
		print $FH "readonly " if (exists $node->{modifier});
		print $FH "attribute ";
		print $FH $self->_get_name($node->{type});
		print $FH " <span class='decl'>",$node->{idf},"</span>;";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

#
#	3.16	Event Declaration
#

sub visitRegularEvent {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
	print $FH "<pre>  ";
		print $FH "custom "
				if (exists $node->{modifier});
		print $FH "eventtype <span class='decl'>",$node->{idf},"</span>";
		if (exists $node->{inheritance}) {
			my $inheritance = $node->{inheritance};
			print $FH " : ";
			if (exists $inheritance->{list_value}) {
				print $FH "truncatable " if (exists $inheritance->{modifier});
				my $first = 1;
				foreach (@{$inheritance->{list_value}}) {
					print $FH ", " if (! $first);
					print $FH $self->_get_name($_);
					$first = 0;
				}
			}
			if (exists $inheritance->{list_interface}) {
				print $FH "support ";
				my $first = 1;
				foreach (@{$inheritance->{list_interface}}) {
					print $FH ", " if (! $first);
					print $FH $self->_get_name($_);
					$first = 0;
				}
			}
		}
		print $FH ";\n";
	print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
			if (exists $node->{typeprefix});
	print $FH "</pre>\n";
}

sub visitAbstractEvent {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
	print $FH "<pre>  abstract eventtype <span class='decl'>",$node->{idf},"</span>";
		if (exists $node->{inheritance}) {
			my $inheritance = $node->{inheritance};
			print $FH " : ";
			if (exists $inheritance->{list_value}) {
				print $FH "truncatable " if (exists $inheritance->{modifier});
				my $first = 1;
				foreach (@{$inheritance->{list_value}}) {
					print $FH ", " if (! $first);
					print $FH $self->_get_name($_);
					$first = 0;
				}
			}
			if (exists $inheritance->{list_interface}) {
				print $FH "support ";
				my $first = 1;
				foreach (@{$inheritance->{list_interface}}) {
					print $FH ", " if (! $first);
					print $FH $self->_get_name($_);
					$first = 0;
				}
			}
		}
		print $FH ";\n";
	print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
			if (exists $node->{typeprefix});
	print $FH "</pre>\n";
}

#
#	3.17	Component Declaration
#

sub visitComponent {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>";
	print $FH "<pre>  component <span class='decl'>",$node->{idf},"</span>";
		if (exists $node->{inheritance}) {
			print $FH " : ",$self->_get_name($node->{inheritance});
		}
		if (exists $node->{list_support}) {
			print $FH " support ";
			my $first = 1;
			foreach (@{$node->{list_support}}) {
				print $FH ", " if (! $first);
				print $FH $self->_get_name($_);
				$first = 0;
			}
		}
		print $FH ";\n";
	print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

sub visitProvides {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		print $FH "provides ";
		print $FH $self->_get_name($node->{type});
		print $FH " <span class='decl'>",$node->{idf},"</span>;\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

sub visitUses {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		print $FH "provides ";
		print $FH "multiple " if (exists $node->{modifier});
		print $FH $self->_get_name($node->{type});
		print $FH " <span class='decl'>",$node->{idf},"</span>;\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

sub visitPublishes {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		print $FH "publishes ";
		print $FH $self->_get_name($node->{type});
		print $FH " <span class='decl'>",$node->{idf},"</span>;\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

sub visitEmits {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		print $FH "emits ";
		print $FH $self->_get_name($node->{type});
		print $FH " <span class='decl'>",$node->{idf},"</span>;\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

sub visitConsumes {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  ";
		print $FH "consumes ";
		print $FH $self->_get_name($node->{type});
		print $FH " <span class='decl'>",$node->{idf},"</span>;\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

#
#	3.18	Home Declaration
#

sub visitHome {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>";
	print $FH "<pre>  home <span class='decl'>",$node->{idf},"</span>";
		if (exists $node->{inheritance}) {
			print $FH " : ",$self->_get_name($node->{inheritance});
		}
		if (exists $node->{list_support}) {
			print $FH " support ";
			my $first = 1;
			foreach (@{$node->{list_support}}) {
				print $FH ", " if (! $first);
				print $FH $self->_get_name($_);
				$first = 0;
			}
		}
		print $FH " manages ",$self->_get_name($node->{manage});
		if (exists $node->{primarykey}) {
			print $FH " primarykey ",$self->_get_name($node->{primarykey});
		}
		print $FH ";\n";
	print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

sub visitFactory {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  factory <span class='decl'>",$node->{idf},"</span> (";
	my $first = 1;
	foreach (@{$node->{list_param}}) {	# parameter
		print $FH "," unless ($first);
		print $FH "\n";
		print $FH "    ",$_->{attr}," ",$self->_get_name($_->{type})," ",$_->{idf};
		$first = 0;
	}
	print $FH "\n";
	print $FH "  )";
	if (exists $node->{list_raise}) {
		print $FH " raises(";
		my $first = 1;
		foreach (@{$node->{list_raise}}) {	# exception
			print $FH ", " unless ($first);
			print $FH $self->_get_name($_);
			$first = 0;
	    }
	    print $FH ")";
	}
	print $FH ";\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

sub visitFinder {
	my $self = shift;
	my ($node, $FH) = @_;
	print $FH "<pre>  finder <span class='decl'>",$node->{idf},"</span> (";
	my $first = 1;
	foreach (@{$node->{list_param}}) {	# parameter
		print $FH "," unless ($first);
		print $FH "\n";
		print $FH "    ",$_->{attr}," ",$self->_get_name($_->{type})," ",$_->{idf};
		$first = 0;
	}
	print $FH "\n";
	print $FH "  )";
	if (exists $node->{list_raise}) {
		print $FH " raises(";
		my $first = 1;
		foreach (@{$node->{list_raise}}) {	# exception
			print $FH ", " unless ($first);
			print $FH $self->_get_name($_);
			$first = 0;
	    }
	    print $FH ")";
	}
	print $FH ";\n";
	print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
			if (exists $node->{typeid});
	print $FH "</pre>\n";
}

##############################################################################

package CORBA::HTML::commentVisitor;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	$self->{parent} = shift;
	return $self;
}

sub _get_defn {
	my $self = shift;
	my ($defn) = @_;
	if (ref $defn) {
		return $defn;
	} else {
		return $self->{parent}->{symbtab}->Lookup($defn);
	}
}

sub _get_name {
	my $self = shift;
	my ($node) = @_;
	return $node->visit($self->{parent}->{html_name},$self->{parent}->{scope});
}

sub _extract_doc {
	my $self = shift;
	my ($node) = @_;
	my $doc = undef;
	my @tags = ();
	unless ($node->isa('Parameter')) {
		$self->{scope} = $node->{full};
		$self->{scope} =~ s/::[0-9A-Z_a-z]+$//;
	}
	if (exists $node->{doc}) {
		my @lines = split /\n/, $node->{doc};
		foreach (@lines) {
			if      (/^\s*@\s*([\s0-9A-Z_a-z]+):\s*(.*)/) {
				my $tag = $1;
				my $value = $2;
				$tag =~ s/\s*$//;
				push @tags, [$tag, $value];
			} elsif (/^\s*@\s*([A-Z_a-z][0-9A-Z_a-z]*)\s+(.*)/) {
				push @tags, [$1, $2];
			} else {
				$doc .= $_;
				$doc .= "\n";
			}
		}
	}
	# adds tag from pragma
	if (exists $node->{id}) {
		push @tags, ["Repository ID", $node->{id}];
	} else {
		if (exists $node->{version}) {
			push @tags, ["version", $node->{version}];
		}
	}
	return ($doc, \@tags);
}

sub _lookup {
	my $self = shift;
	my ($name) = @_;
	my $defn;
#	print "_lookup: '$name'\n";
	if      ($name =~ /^::/) {
		# global name
		return $self->{parent}->{parser}->YYData->{symbtab}->___Lookup($name);
	} elsif ($name =~ /^[0-9A-Z_a-z]+$/) {
		# identifier alone
		my $scope = $self->{scope};
		while (1) {
			# Section 3.15.3 Special Scoping Rules for Type Names
			my $g_name = $scope . '::' . $name;
			$defn = $self->{parent}->{parser}->YYData->{symbtab}->__Lookup($scope, $g_name, $name);
			last if (defined $defn || $scope eq '');
			$scope =~ s/::[0-9A-Z_a-z]+$//;
		};
		return $defn;
	} else {
		# qualified name
		my @list = split /::/, $name;
		return undef unless (scalar @list > 1);
		my $idf = pop @list;
		my $scoped_name = $name;
		$scoped_name =~ s/(::[0-9A-Z_a-z]+$)//;
#		print "qualified name : '$scoped_name' '$idf'\n";
		my $scope = $self->_lookup($scoped_name);		# recursive
		if (defined $scope) {
			$defn = $self->{parent}->{parser}->YYData->{symbtab}->___Lookup($scope->{full} . '::' . $idf);
		}
		return $defn;
	}
}

sub _process_text {
	my $self = shift;
	my ($text) = @_;

	# keep track of leading and trailing white-space
	my $lead  = ($text =~ s/\A(\s+)//s ? $1 : "");
	my $trail = ($text =~ s/(\s+)\Z//s ? $1 : "");

	# split at space/non-space boundaries
	my @words = split( /(?<=\s)(?=\S)|(?<=\S)(?=\s)/, $text );

	# process each word individually
	foreach my $word (@words) {
		# skip space runs
		next if $word =~ /^\s*$/;
		if ($word =~ /^[\w:]+$/) {
			# looks like a IDL identifier
			my $node = $self->_lookup($word);
			if (	    defined $node
					and exists $node->{file_html}
					and $word =~ /$node->{idf}/ ) {
				my $anchor = $node->{html_name} || $node->{idf};
				$word = "<a href='" . $node->{file_html} . "#" . $anchor . "'>" . $word . "</a>";
			}
		} elsif ($word =~ /^\w+:\/\/\w/) {
			# looks like a URL
			# Don't relativize it: leave it as the author intended
			$word = "<a href='" . $word . "'>" . $word . "</a>";
		} elsif ($word =~ /^[\w.-]+\@[\w.-]+/) {
			# looks like an e-mail address
			$word = "<a href='mailto:" . $word . "'>" . $word . "</a>";
		}
	}

	# put everything back together
	return $lead . join('', @words) . $trail;
}

sub _format_doc_bloc {
	my $self = shift;
	my ($doc, $FH) = @_;
	if (defined $doc) {
		$doc = $self->_process_text($doc);
		print $FH "    <p class='comment'>",$doc,"</p>\n";
	}
}

sub _format_doc_line {
	my $self = shift;
	my ($node, $doc, $FH) = @_;
	my $anchor = "";
	unless ($node->isa('Parameter')) {
		$anchor = "<a id='" . $node->{html_name} . "' name='" . $node->{html_name} . "'/>\n";
	}
	if (defined $doc) {
		$doc = $self->_process_text($doc);
		print $FH "    <li>",$anchor,$node->{idf}," : <span class='comment'>",$doc,"</span></li>\n";
	} else {
		print $FH "    <li>",$anchor,$node->{idf},"</li>\n";
	}
}

sub _format_tags {
	my $self = shift;
	my ($tags, $FH, $javadoc) = @_;
	print $FH "    <p>\n" if (scalar(@{$tags}));
	foreach (@{$tags}) {
		my $entry = ${$_}[0];
		my $doc = ${$_}[1];
		next if (defined $javadoc and lc($entry) eq "param");
		$doc = $self->_process_text($doc);
		print $FH "      <span class='tag'>",$entry," : </span><span class='comment'>",$doc,"</span>\n";
		print $FH "      <br />\n";
	}
	print $FH "    </p>\n" if (scalar(@{$tags}));
}

#
#	3.6		Module Declaration
#

sub visitModules {
	my $self = shift;
	my ($node, $FH) = @_;
	foreach (@{$node->{list_decl}}) {
		my ($doc, $tags) = $self->_extract_doc($_);
		$self->_format_doc_bloc($doc, $FH);
		$self->_format_tags($tags, $FH);
	}
}

#
#	3.8		Interface Declaration
#

sub visitBaseInterface {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	$self->_format_tags($tags, $FH);
}

#
#	3.9		Value Declaration
#
#	3.9.1	Regular Value Type
#

sub visitStateMember {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	$self->_format_tags($tags, $FH);
}

sub visitInitializer {
	shift->visitOperation(@_);
}

#
#	3.10	Constant Declaration
#

sub visitConstant {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	$self->_format_tags($tags, $FH);
}

#
#	3.11	Type Declaration
#

sub visitTypeDeclarator {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	$self->_format_tags($tags, $FH);
}

sub visitNativeType {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	$self->_format_tags($tags, $FH);
}

#	3.11.2	Constructed Types
#
#	3.11.2.1	Structures
#

sub visitStructType {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	my $doc_member = 0;
	foreach (@{$node->{list_member}}) {
		$doc_member ++
				if (exists $self->_get_defn($_)->{doc});
	}
	if ($doc_member) {
#		print $FH "  <br />\n";
		print $FH "  <ul>\n";
		foreach (@{$node->{list_member}}) {
			$self->_get_defn($_)->visit($self, $FH);		# member
		}
		print $FH "  </ul>\n";
	}
	$self->_format_tags($tags, $FH);
}

sub visitMember {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_line($node, $doc, $FH);
}

#	3.11.2.2	Discriminated Unions
#

sub visitUnionType {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	my $doc_member = 0;
	foreach (@{$node->{list_expr}}) {
		$doc_member ++
				if (exists $self->_get_defn($_->{element}->{value})->{doc});
	}
	if ($doc_member) {
#		print $FH "  <br />\n";
		print $FH "  <ul>\n";
		foreach (@{$node->{list_expr}}) {
			$self->_get_defn($_->{element}->{value})->visit($self, $FH);		# member
		}
		print $FH "  </ul>\n";
	}
	$self->_format_tags($tags, $FH);
}

#	3.11.2.4	Enumerations
#

sub visitEnumType {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	my $doc_member = 0;
	foreach (@{$node->{list_expr}}) {
		$doc_member ++
				if (exists $_->{doc});
	}
	if ($doc_member) {
#		print $FH "    <br />\n";
		print $FH "    <ul>\n";
		foreach (@{$node->{list_expr}}) {
			$_->visit($self, $FH);			# enum
		}
		print $FH "    </ul>\n";
	}
	$self->_format_tags($tags, $FH);
}

sub visitEnum {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_line($node, $doc, $FH);
}

#
#	3.12	Exception Declaration
#

sub visitException {
	shift->visitStructType(@_);
}

#
#	3.13	Operation Declaration
#

sub visitOperation {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	if (scalar(@{$node->{list_in}}) + scalar(@{$node->{list_inout}}) + scalar(@{$node->{list_out}})) {
#		print $FH "  <br />\n";
		print $FH "  <ul>\n";
		if (scalar(@{$node->{list_in}})) {
			if (scalar(@{$node->{list_in}}) > 1) {
				print $FH "    <li>Parameters IN :\n";
			} else {
				print $FH "    <li>Parameter IN :\n";
			}
			print $FH "      <ul>\n";
			foreach (@{$node->{list_in}}) {
				$self->_parameter($node, $_, $FH);
			}
			print $FH "      </ul>\n";
			print $FH "    </li>\n";
		}
		if (scalar(@{$node->{list_inout}})) {
			if (scalar(@{$node->{list_inout}}) > 1) {
				print $FH "    <li>Parameters INOUT :\n";
			} else {
				print $FH "    <li>Parameter INOUT :\n";
			}
			print $FH "      <ul>\n";
			foreach (@{$node->{list_inout}}) {
				$self->_parameter($node, $_, $FH);
			}
			print $FH "      </ul>\n";
			print $FH "    </li>\n";
		}
		if (scalar(@{$node->{list_out}})) {
			if (scalar(@{$node->{list_out}}) > 1) {
				print $FH "    <li>Parameters OUT :\n";
			} else {
				print $FH "    <li>Parameter OUT :\n";
			}
			print $FH "      <ul>\n";
			foreach (@{$node->{list_out}}) {
				$self->_parameter($node, $_, $FH);
			}
			print $FH "      </ul>\n";
			print $FH "    </li>\n";
		}
		print $FH "  </ul>\n";
	}
	$self->_format_tags($tags, $FH, 1);
}

sub _parameter {
	my $self = shift;
	my ($parent, $node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	unless (defined $doc) {
		($doc, $tags) = $self->_extract_doc($parent);
		foreach (@{$tags}) {
			my $entry = ${$_}[0];
			my $javadoc = ${$_}[1];
			if (lc($entry) eq "param" and $javadoc =~ /^$node->{idf}/) {
				$doc = $javadoc;
				$doc =~ s/^$node->{idf}//;
				last;
			}
		}
	}
	if (defined $doc) {
		$doc = $self->_process_text($doc);
		print $FH "    <li>",$node->{idf}," : <span class='comment'>",$doc,"</span></li>\n";
	} else {
		print $FH "    <li>",$node->{idf},"</li>\n";
	}
}

#
#	3.14	Attribute Declaration
#

sub visitAttribute {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	$self->_format_tags($tags, $FH);
}

#
#	3.17	Component Declaration
#

sub visitProvides {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	$self->_format_tags($tags, $FH);
}

sub visitUses {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	$self->_format_tags($tags, $FH);
}

sub visitPublishes {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	$self->_format_tags($tags, $FH);
}

sub visitEmits {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	$self->_format_tags($tags, $FH);
}

sub visitConsumes {
	my $self = shift;
	my ($node, $FH) = @_;
	my ($doc, $tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc, $FH);
	$self->_format_tags($tags, $FH);
}

#
#	3.18	Home Declaration
#

sub visitFactory {
	shift->visitOperation(@_);
}

sub visitFinder {
	shift->visitOperation(@_);
}

##############################################################################

package CORBA::HTML::nameVisitor;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my ($parser) = @_;
	$self->{symbtab} = $parser->YYData->{symbtab};
	return $self;
}

sub _get_name {
	my $self = shift;
	my ($node, $scope) = @_;
	my $full = $node->{full};
	$full =~ s/^:://;
	my @list_name = split /::/, $full;
	my @list_scope = split /::/, $scope;
	while (@list_scope) {
		last if ($list_scope[0] ne $list_name[0]);
		shift @list_name;
		shift @list_scope;
	}
	my $name = join '::', @list_name;
	my $fragment = $node->{idf};
	$fragment = $node->{html_name} if (exists $node->{html_name});
	if (exists $node->{file_html}) {
		my $a = "<a href='" . $node->{file_html} . "#" . $fragment . "'>" . $name . "</a>";
		return $a;
	} elsif ( $node->isa('BaseInterface') or $node->isa('ForwardBaseInterface') ) {
		my $filename = $node->{full};
		$filename =~ s/::/_/g;
		$filename .= '.html';
		my $a = "<a href='" . $filename . "#" . $fragment . "'>" . $name . "</a>";
		return $a;
	} else {
		return $name;
	}
}

sub _get_lexeme {
	my $self = shift;
	my ($node) = @_;
	my $value = $node->{lexeme};
	$value =~ s/&/"&amp;"/g;
	$value =~ s/</"&lt;"/g;
	$value =~ s/>/"&gt;"/g;
	return $value;
}

sub _get_defn {
	my $self = shift;
	my ($defn) = @_;
	if (ref $defn) {
		return $defn;
	} else {
		return $self->{symbtab}->Lookup($defn);
	}
}

#
#	3.8		Interface Declaration
#

sub visitBaseInterface {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub visitForwardBaseInterface {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

#
#	3.10	Constant Declaration
#

sub visitConstant {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub _Eval {
	my $self = shift;
	my ($list_expr, $scope, $type) = @_;
	my $elt = pop @{$list_expr};
	unless (ref $elt) {
		$elt = $self->{symbtab}->Lookup($elt);
	}
	if (       $elt->isa('BinaryOp') ) {
		my $right = $self->_Eval($list_expr, $scope, $type);
		my $left = $self->_Eval($list_expr, $scope, $type);
		return "(" . $left . " " . $elt->{op} . " " . $right . ")";
	} elsif (  $elt->isa('UnaryOp') ) {
		my $right = $self->_Eval($list_expr, $scope, $type);
		return $elt->{op} . $right;
	} elsif (  $elt->isa('Constant')
			or $elt->isa('Enum')
			or $elt->isa('Literal') ) {
		return $elt->visit($self, $scope, $type);
	} else {
		warn __PACKAGE__," _Eval: INTERNAL ERROR ",ref $elt,".\n";
		return undef;
	}
}

sub visitExpression {
	my $self = shift;
	my ($node, $scope) = @_;
	my @list_expr = @{$node->{list_expr}};		# create a copy
	return $self->_Eval(\@list_expr, $scope, $node->{type});
}

sub visitEnum {
	my $self = shift;
	my ($node, $attr) = @_;
	return $node->{idf};
}

sub visitIntegerLiteral {
	my $self = shift;
	my ($node) = @_;
	return $self->_get_lexeme($node);
}

sub visitStringLiteral {
	my $self = shift;
	my ($node) = @_;
	my @list = unpack "C*", $node->{value};
	my $str = "\"";
	foreach (@list) {
		if      ($_ < 32 or $_ >= 127) {
			$str .= sprintf "\\x%02x", $_;
		} elsif ($_ == ord '&') {
			$str .= "&amp;";
		} elsif ($_ == ord '<') {
			$str .= "&lt;";
		} elsif ($_ == ord '>') {
			$str .= "&gt;";
		} else {
			$str .= chr $_;
		}
	}
	$str .= "\"";
	return $str;
}

sub visitWideStringLiteral {
	my $self = shift;
	my ($node) = @_;
	my @list = unpack "C*", $node->{value};
	my $str = "L\"";
	foreach (@list) {
		if      ($_ < 32 or ($_ >= 128 and $_ < 256)) {
			$str .= sprintf "\\x%02x", $_;
		} elsif ($_ >= 256) {
			$str .= sprintf "\\u%04x", $_;
		} elsif ($_ == ord '&') {
			$str .= "&amp;";
		} elsif ($_ == ord '<') {
			$str .= "&lt;";
		} elsif ($_ == ord '>') {
			$str .= "&gt;";
		} else {
			$str .= chr $_;
		}
	}
	$str .= "\"";
	return $str;
}

sub visitCharacterLiteral {
	my $self = shift;
	my ($node) = @_;
	my @list = unpack "C", $node->{value};
	my $c = $list[0];
	my $str = "'";
	if      ($c < 32 or $c >= 128) {
		$str .= sprintf "\\x%02x", $c;
	} elsif ($c == ord '&') {
		$str .= "&amp;";
	} elsif ($c == ord '<') {
		$str .= "&lt;";
	} elsif ($c == ord '>') {
		$str .= "&gt;";
	} else {
		$str .= chr $c;
	}
	$str .= "'";
	return $str;
}

sub visitWideCharacterLiteral {
	my $self = shift;
	my ($node) = @_;
	my @list = unpack "C", $node->{value};
	my $c = $list[0];
	my $str = "L'";
	if      ($c < 32 or ($c >= 128 and $c < 256)) {
		$str .= sprintf "\\x%02x", $c;
	} elsif ($c >= 256) {
		$str .= sprintf "\\u%04x", $c;
	} elsif ($c == ord '&') {
		$str .= "&amp;";
	} elsif ($c == ord '<') {
		$str .= "&lt;";
	} elsif ($c == ord '>') {
		$str .= "&gt;";
	} else {
		$str .= chr $c;
	}
	$str .= "'";
	return $str;
}

sub visitFixedPtLiteral {
	my $self = shift;
	my ($node) = @_;
	return $self->_get_lexeme($node);
}

sub visitFloatingPtLiteral {
	my $self = shift;
	my ($node) = @_;
	return $self->_get_lexeme($node);
}

sub visitBooleanLiteral {
	my $self = shift;
	my ($node) = @_;
	return $node->{value};
}

#
#	3.11	Type Declaration
#

sub visitTypeDeclarator {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub visitNativeType {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub visitBasicType {
	my $self = shift;
	my ($node) = @_;
	return $node->{value};
}

sub visitAnyType {
	my $self = shift;
	my ($node) = @_;
	return $node->{value};
}

sub visitStructType {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub visitUnionType {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub visitEnumType {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub visitSequenceType {
	my $self = shift;
	my ($node, $scope) = @_;
	my $type = $self->_get_defn($node->{type});
	my $name = $node->{value} . "&lt;";
	$name .= $type->visit($self, $scope);
	if (exists $node->{max}) {
		$name .= ",";
		$name .= $node->{max}->visit($self, $scope);
	}
	$name .= "&gt;";
	return $name;
}

sub visitStringType {
	my $self = shift;
	my ($node, $scope) = @_;
	if (exists $node->{max}) {
		my $name = $node->{value} . "&lt;";
		$name .= $node->{max}->visit($self, $scope);
		$name .= "&gt;";
		return $name;
	} else {
		return $node->{value};
	}
}

sub visitWideStringType {
	my $self = shift;
	my ($node, $scope) = @_;
	if (exists $node->{max}) {
		my $name = $node->{value} . "&lt;";
		$name .= $node->{max}->visit($self, $scope);
		$name .= "&gt;";
		return $name;
	} else {
		return $node->{value};
	}
}

sub visitFixedPtType {
	my $self = shift;
	my ($node, $scope) = @_;
	my $name = $node->{value} . "&lt;";
	$name .= $node->{d}->visit($self, $scope);
	$name .= ",";
	$name .= $node->{s}->visit($self, $scope);
	$name .= "&gt;";
	return $name;
}

sub visitFixedPtConstType {
	my $self = shift;
	my ($node, $scope) = @_;
	return $node->{value};
}

sub visitVoidType {
	my $self = shift;
	my ($node) = @_;
	return $node->{value};
}

sub visitValueBaseType {
	my $self = shift;
	my ($node) = @_;
	return $node->{value};
}

#
#	3.12	Exception Declaration
#

sub visitException {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

#
#	3.13	Operation Declaration
#

sub visitOperation {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

#
#	3.14	Attribute Declaration
#

sub visitAttribute {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

#
#	3.17	Component Declaration
#

sub visitProvides {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub visitUses {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub visitPublishes {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub visitEmits {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub visitConsumes {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

#
#	3.18	Home Declaration
#

sub visitFactory {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

sub visitFinder {
	my $self = shift;
	my ($node, $scope) = @_;
	return $self->_get_name($node, $scope);
}

1;

