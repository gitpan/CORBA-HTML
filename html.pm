use strict;
use UNIVERSAL;

package htmlVisitor;
use CORBA::HTML::name;

use vars qw($VERSION);
$VERSION = '1.0';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my ($parser) = @_;
	$self->{parser} = $parser;
	$self->{html_name} = new HTMLnameVisitor();
	$self->{html_decl} = new HTMLdeclVisitor($self);
	$self->{html_comment} = new HTMLcommentVisitor($self);
	$self->{scope} = '';
	return $self;
}

sub _get_name {
	my $self = shift;
	my($node) = @_;
	return $node->visitName($self->{html_name},$self->{scope});
}

sub _print_decl {
	my $self = shift;
	my($node) = @_;
	$node->visit($self->{html_decl},\*OUT);
}

sub _print_comment {
	my $self = shift;
	my($node) = @_;
	$node->visit($self->{html_comment},\*OUT);
	print OUT "  <p>&nbsp;<p/>\n";
}

sub _sep_line {
	my $self = shift;
	print OUT "    <hr align='center'/>\n";
}

sub _format_head {
	my $self = shift;
	my($title) = @_;
	print OUT "<?xml version='1.0' encoding='ISO-8859-1'?>\n";
	print OUT "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'xhtml1-transitional.dtd'>\n";
	print OUT "<html xmlns='http://www.w3.org/1999/xhtml'>\n";
	print OUT "\n";
	print OUT "  <head>\n";
	print OUT "    <meta name='generator' content='idl2html' />\n";
	print OUT "    <meta http-equiv='Content-Type' content='text/html; charset=ISO-8859-1' />\n";
	print OUT "    <title>",$title,"</title>\n";
	print OUT "  </head>\n";
	print OUT "\n";
	print OUT "  <body>\n";
	print OUT "    <a name='__Top__'></a>\n";
	print OUT "    <h1>",$title,"</h1>\n";
	print OUT "    <p><a href='index.html'>Global index</a></p>\n"
			unless ($title eq "Global index");
	print OUT "    <hr align='center'/>\n";
}

sub _format_tail {
	my $self = shift;
	print OUT "    <i>Generated by idl2html</i>\n";
	print OUT "\n";
	print OUT "  </body>\n";
	print OUT "\n";
	print OUT "</html>\n";
}

sub _format_index {
	my $self = shift;
	my($node,$rlist) = @_;
	my $nb = 0;
	foreach (@{$rlist}) {
		my $idx = 'index_' . $_;
		if (keys %{$node->{$idx}}) {
			$nb ++;
			my $title = ucfirst $_;
			$title =~ s/_/ /g;
			print OUT "<h2><font color='#800080'>",$title," index.</font></h2>\n";
			print OUT "<dl>\n";
			foreach (sort keys %{$node->{$idx}}) {
				my $child = $node->{$idx}->{$_};
				print OUT "    <dt><a href='",$child->{file_html},"#",$_,"'>";
					print OUT "<b>",$_,"</b></a></dt>\n";
			}
			print OUT "</dl>\n";
		}
	}
	$self->_sep_line() if ($nb);
}

sub _format_decl {
	my $self = shift;
	my($node,$rlist) = @_;
	my $nb = 0;
	foreach (@{$rlist}) {
		my $idx = 'index_' . $_;
		if (keys %{$node->{$idx}}) {
			$nb ++;
			my $title = ucfirst $_;
			$title =~ s/_/ /g;
			print OUT "<h2><font color='#FF0000'>",$title,"s.</font></h2>\n";
			if (scalar keys %{$node->{$idx}}) {
				print OUT "<ul>\n";
				foreach (sort keys %{$node->{$idx}}) {
					my $child = $node->{$idx}->{$_};
					print OUT "    <li>\n";
					print OUT "      <h3><a name='",$_,"'></a>",$_,"</h3>\n";
					$self->_print_decl($child);
					$self->_print_comment($child);
					print OUT "    </li>\n";
				}
				print OUT "</ul>\n";
			}
		}
	}
	$self->_sep_line() if ($nb);
}

#
#	3.5		OMG IDL Specification
#

sub visitSpecification {
	my $self = shift;
	my($node) = @_;
	my @list_call = (
		'module',
		'interface',
		'value'
	);
	foreach (@list_call) {
		my $idx = 'index_' . $_;
		foreach (keys %{$node->{$idx}}) {
			my $child = $node->{$idx}->{$_};
			$child->visit($self);
		}
	}

	my @list_decl = (
		'boxed_value',
		'type',
		'exception',
		'constant'
	);
	my $nb = 0;
	foreach (@list_decl) {
		my $idx = 'index_' . $_;
		foreach (keys %{$node->{$idx}}) {
			$nb ++;
		}
	}
	if ($nb) {
		open OUT,"> $node->{file_html}"
				or die "can't open $node->{file_html} ($!).\n";

		$self->_format_head($node->{file_html});
		$self->_format_decl($node,\@list_decl);
		$self->_format_tail();

		close OUT;
	}

	foreach (@list_call) {
		my $idx = 'index_' . $_;
		foreach (keys %{$node->{$idx}}) {
			$main::global->{$idx}->{$_} = 1;
		}
	}
	$nb = 0;
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

		$self->_format_head("Global index");
		foreach (@list_call) {
			my $idx = 'index_' . $_;
			if (keys %{$main::global->{$idx}}) {
				my $title = ucfirst $_;
				print OUT "<h2><font color='#800080'>All ",$title," index.</font></h2>\n";
				print OUT "<dl>\n";
				foreach (sort keys %{$main::global->{$idx}}) {
					my $filename = $_;
					$filename =~ s/::/_/g;
					$filename .= '.html';
					print OUT "    <dt><a href='_",$filename,"#__Top__'>";
						print OUT "<b>",$_,"</b></a></dt>\n";
				}
				print OUT "</dl>\n";
			}
		}
		$self->_sep_line();
		$self->_format_tail();

		close OUT;
	}
}

#
#	3.6		Module Declaration
#

sub visitModule {
	my $self = shift;
	my($node) = @_;
	my $scope_save = $self->{scope};
	$self->{scope} = $node->{coll};
	$self->{scope} =~ s/^:://;
	my $title = $self->{scope};
	my @list_call = (
		'module',
		'interface',
		'value'
	);
	my @list_idx = (
		'module',
		'interface',
		'value',
		'type',
		'exception',
		'constant'
	);
	my @list_decl = (
		'boxed_value',
		'type',
		'exception',
		'constant'
	);

	foreach (@list_call) {
		my $idx = 'index_' . $_;
		foreach (keys %{$node->{$idx}}) {
			my $child = $node->{$idx}->{$_};
			$child->visit($self);
		}
	}

	foreach (keys %{$node->{index_boxed_value}}) {
		$node->{index_value}->{$_} = $node->{index_boxed_value}->{$_};
	}

	open OUT,"> $node->{file_html}"
			or die "can't open $node->{file_html} ($!).\n";

	$self->_format_head("Module " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node,\@list_idx);
	$self->_format_decl($node,\@list_decl);
	$self->_format_tail();

	close OUT;
	$self->{scope} = $scope_save;
}

#
#	3.7		Interface Declaration
#

sub visitInterface {
	my $self = shift;
	my($node) = @_;
	my $scope_save = $self->{scope};
	$self->{scope} = $node->{coll};
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

	$self->_format_head("Interface " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node,\@list);
	$self->_format_decl($node,\@list);
	$self->_format_tail();

	close OUT;
	$self->{scope} = $scope_save;
}

#
#	3.8		Value Declaration
#
#	3.8.1	Regular Value Type
#

sub visitRegularValue {
	my $self = shift;
	my($node) = @_;
	$self->{scope} = $node->{coll};
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

	$self->_format_head("Value Type " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node,\@list);
	$self->_format_decl($node,\@list);
	$self->_format_tail();

	close OUT;
}

#
#	3.8.3	Abstract Value Type
#

sub visitAbstractValue {
	my $self = shift;
	my($node) = @_;
	$self->{scope} = $node->{coll};
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

	$self->_format_head("Abstract Value Type " . $title);
	$self->_print_decl($node);
	$self->_print_comment($node);
	$self->_sep_line();
	$self->_format_index($node,\@list);
	$self->_format_decl($node,\@list);
	$self->_format_tail();

	close OUT;
}

##############################################################################

package HTMLdeclVisitor;
use CORBA::HTML::name;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	$self->{parent} = shift;
	return $self;
}

sub _get_name {
	my $self = shift;
	my($node) = @_;
	return $node->visitName($self->{parent}->{html_name},$self->{parent}->{scope});
}

#
#	3.6		Module Declaration
#

sub visitModule {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<p><a name='",$node->{idf},"'></a>module <b>",$node->{idf},"</b></p>\n";
}

#
#	3.7		Interface Declaration
#

sub visitInterface {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<p><a name='",$node->{idf},"'></a>";
		print $FH $node->{modifier}," "
				if (exists $node->{modifier});
		print $FH "interface <b>",$node->{idf},"</b>";
		if (exists $node->{list_inheritance}) {
			print $FH " : ";
			my $first = 1;
			foreach (@{$node->{list_inheritance}}) {
				print $FH ", " unless ($first);
				print $FH $self->_get_name($_);
				$first = 0;
			}
		}
		print $FH "</p>\n";
}

#
#	3.8		Value Declaration
#
#	3.8.1	Regular Value Type
#

sub visitRegularValue {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<p><a name='",$node->{idf},"'></a>";
		print $FH "custom "
				if (exists $node->{modifier});
		print $FH "valuetype <b>",$node->{idf},"</b>";
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
		print $FH "</p>\n";
}

sub visitStateMember {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<pre>  ",$node->{modifier}," ";
		print $FH $self->_get_name($node->{type});
		print $FH " <b>",$node->{idf},"</b>";
		if (exists $node->{array_size}) {
			foreach (@{$node->{array_size}}) {
				print $FH "[";
				$_->visit($self,$FH);			# expression
				print $FH "]";
			}
		}
		print $FH ";\n";
	print $FH "</pre>\n";
}

sub visitFactory {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<pre>  factory <b>",$node->{idf},"</b> (";
	my $first = 1;
	foreach (@{$node->{list_param}}) {	# parameter
		print $FH "," unless ($first);
		print $FH "\n";
		print $FH "    ",$_->{attr}," ",$self->_get_name($_->{type})," ",$_->{idf};
		$first = 0;
	}
	print $FH "\n";
	print $FH "  )";
	print $FH "</pre>\n";
}

#
#	3.8.2	Boxed Value Type
#

sub visitBoxedValue {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<pre>  valuetype ";
		print $FH "<b>",$node->{idf},"</b> ";
		print $FH $self->_get_name($node->{expr});
		print $FH ";\n";
	print $FH "</pre>\n";
}

#
#	3.8.3	Abstract Value Type
#

sub visitAbstractValue {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<p><a name='",$node->{idf},"'></a>";
		print $FH "abstract valuetype <b>",$node->{idf},"</b>";
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
		print $FH "</p>\n";
}

#
#	3.9		Constant Declaration
#

sub visitConstant {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<pre>  constant ";
		print $FH $self->_get_name($node->{type});
		print $FH " <b>",$node->{idf},"</b> = ";
		$node->{value}->visit($self,$FH);		# expression
		print $FH ";\n";
	print $FH "</pre>\n";
}

sub visitExpression {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH $self->_get_name($node);
}

#
#	3.10	Type Declaration
#

sub visitTypeDeclarator {
	my $self = shift;
	my($node,$FH) = @_;
	if (exists $node->{modifier}) {
		print $FH "<pre>  native ";
			print $FH " <b>",$node->{idf},"</b>;\n";
	} else {
		print $FH "<pre>  typedef ";
			print $FH $self->_get_name($node->{type});
			print $FH " <b>",$node->{idf},"</b>";
			if (exists $node->{array_size}) {
				foreach (@{$node->{array_size}}) {
					print $FH "[";
					$_->visit($self,$FH);				# expression
					print $FH "]";
				}
			}
			print $FH ";\n";
	}
	print $FH "</pre>\n";
}

#
#	3.10.2	Constructed Types
#
#	3.10.2.1	Structures
#

sub visitStructType {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<pre>  struct <b>",$node->{html_name},"</b> {\n";
	foreach (@{$node->{list_expr}}) {
		$_->visit($self,$FH);				# members
	}
	print $FH "  };\n";
	print $FH "</pre>\n";
}

sub visitMembers {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "    ",$self->_get_name($node->{type});
	my $first = 1;
	foreach (@{$node->{list_value}}) {
		if ($first) {
			$first = 0;
		} else {
			print $FH ",";
		}
		$_->visit($self,$FH);				# single or array
	}
	print $FH ";\n";
}

sub visitArray {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH " ",$node->{idf};
	foreach (@{$node->{array_size}}) {
		print $FH "[";
		$_->visit($self,$FH);				# expression
		print $FH "]";
	}
}

sub visitSingle {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH " ",$node->{idf};
}

#	3.10.2.2	Discriminated Unions
#

sub visitUnionType {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<pre>  union <b>",$node->{html_name},"</b> switch(";
		print $FH $self->_get_name($node->{type});
		print $FH ") {\n";
	foreach (@{$node->{list_expr}}) {
		$_->visit($self,$FH);				# case
	}
	print $FH "  };\n";
	print $FH "</pre>\n";
}

sub visitCase {
	my $self = shift;
	my($node,$FH) = @_;
	foreach (@{$node->{list_label}}) {
		if ($_->isa('Default')) {
			print $FH "    default:\n";
		} else {
			print $FH "    case ";
			$_->visit($self,$FH);			# expression
			print $FH ":\n";
		}
	}
	$node->{element}->visit($self,$FH);
}

sub visitElement {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "      ",$self->_get_name($node->{type});
	$node->{value}->visit($self,$FH);		# array or single
	print $FH ";\n";
}

#	3.10.2.3	Enumerations
#

sub visitEnumType {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<pre>  enum <b>",$node->{html_name},"</b> {\n";
	my $first = 1;
	foreach (@{$node->{list_expr}}) {	# enum
		print $FH ",\n" unless ($first);
		print $FH "    ",$_->{idf};
		$first = 0;
	}
	print $FH "\n";
	print $FH "  };\n";
	print $FH "</pre>\n";
}

#
#	3.11	Exception Declaration
#

sub visitException {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<pre>  exception <b>",$node->{idf},"</b> {\n";
	foreach (@{$node->{list_expr}}) {
		$_->visit($self,$FH);				# members
	}
	print $FH "  };\n";
	print $FH "</pre>\n";
}

#
#	3.12	Operation Declaration
#

sub visitOperation {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<pre>  ";
		print $FH "oneway " if (exists $node->{modifier});
		print $FH $self->_get_name($node->{type});
		print $FH " <b>",$node->{idf},"</b> (";
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
	print $FH "</pre>\n";
}

#
#	3.13	Attribute Declaration
#

sub visitAttribute {
	my $self = shift;
	my($node,$FH) = @_;
	print $FH "<pre>  ";
		print $FH "readonly " if (exists $node->{modifier});
		print $FH "attribute ";
		print $FH $self->_get_name($node->{type});
		print $FH " <b>",$node->{idf},"</b>;";
	print $FH "</pre>\n";
}

##############################################################################

package HTMLcommentVisitor;
use CORBA::HTML::name;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	$self->{parent} = shift;
	return $self;
}

sub _get_name {
	my $self = shift;
	my($node) = @_;
	return $node->visitName($self->{parent}->{html_name},$self->{parent}->{scope});
}

sub _extract_doc {
	my $self = shift;
	my($node) = @_;
	my $doc = undef;
	my @tags = ();
	unless ($node->isa('Parameter')) {
		$self->{scope} = $node->{coll};
		$self->{scope} =~ s/::[0-9A-Z_a-z]+$//;
	}
	if (exists $node->{doc}) {
		my @lines = split /\n/,$node->{doc};
		foreach (@lines) {
			if      (/^\s*@\s*([\s0-9A-Z_a-z]+):\s*(.*)/) {
				my $tag = $1;
				my $value = $2;
				$tag =~ s/\s*$//;
				push @tags,[$tag,$value];
			} elsif (/^\s*@\s*([A-Z_a-z][0-9A-Z_a-z]*)\s+(.*)/) {
				push @tags,[$1,$2];
			} else {
				$doc .= $_;
			}
		}
	}
	# adds tag from pragma
	if (exists $node->{repos_id}) {
		push @tags, ["Repository ID", $node->{repos_id}];
	} else {
		if (exists $node->{version}) {
			push @tags, ["version", $node->{version}];
		}
	}
	return ($doc,\@tags);
}

sub _lookup {
	my $self = shift;
	my($name) = @_;
	my $defn;
	if      ($name =~ /^::/) {
		# global name
		return $self->{parent}->{parser}->YYData->{symbtab}->___Lookup($name);
	} elsif ($name =~ /^[0-9A-Z_a-z]+$/) {
		# identifier alone
		my $scope = $self->{scope};
		while (1) {
			# Section 3.15.3 Special Scoping Rules for Type Names
			my $g_name = $scope . '::' . $name;
			$defn = $self->{parent}->{parser}->YYData->{symbtab}->__Lookup($scope,$g_name,$name);
			last if (defined $defn || $scope eq '');
			$scope =~ s/::[0-9A-Z_a-z]+$//;
		};
		return $defn;
	} else {
		# qualified name
		my @list = split /::/,$name;
		return undef unless (scalar @list > 1);
		my $idf = pop @list;
		my $scoped_name = $name;
		$scoped_name =~ s/(::[0-9A-Z_a-z]+$)//;
		my $scope = $self->_lookup($scoped_name);		# recursive
		if (defined $scope) {
			$defn = $self->{parent}->{parser}->YYData->{symbtab}->___Lookup($scope->{coll} . '::' . $idf);
		}
		return $defn;
	}
}

sub _process_text {
	my $self = shift;
	my($text) = @_;

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
				$word = "<a href='" . $node->{file_html} . "#" . $node->{idf} . "'>" . $word . "</a>";
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
	my($doc,$FH) = @_;
	if (defined $doc) {
		$doc = $self->_process_text($doc);
		print $FH "  <dl>\n";
		print $FH "    <dt><font color='#009900'>",$doc,"</font></dt>\n";
		print $FH "  </dl>\n";
	}
}

sub _format_doc_line {
	my $self = shift;
	my($node,$doc,$FH) = @_;
	if (defined $doc) {
		$doc = $self->_process_text($doc);
		print $FH "    <li>",$node->{idf}," : <font color='#009900'>",$doc,"</font></li>\n";
	} else {
		print $FH "    <li>",$node->{idf},"</li>\n"
				if ($node->isa('Parameter'));
	}
}

sub _format_tags {
	my $self = shift;
	my($tags,$FH) = @_;
	foreach (@{$tags}) {
		my $entry = ${$_}[0];
		my $doc = ${$_}[1];
		$doc = $self->_process_text($doc);
		print $FH "      <br><b>",$entry,"</b> : <font color='#009900'>",$doc,"</font></br>\n";
	}
}

#
#	3.6		Module Declaration
#

sub visitModule {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	$self->_format_tags($tags,$FH);
}

#
#	3.7		Interface Declaration
#

sub visitInterface {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	$self->_format_tags($tags,$FH);
}

#
#	3.8		Value Declaration
#
#	3.8.1	Regular Value Type
#

sub visitRegularValue {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	$self->_format_tags($tags,$FH);
}

sub visitStateMember {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	$self->_format_tags($tags,$FH);
}

sub visitFactory {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	if (scalar(@{$node->{list_in}}) + scalar(@{$node->{list_inout}}) + scalar(@{$node->{list_out}})) {
		print $FH "  <ul>\n";
		if (scalar(@{$node->{list_in}})) {
			print $FH "    <li>Parameter(s) IN :\n";
			print $FH "      <ul>\n";
			foreach (@{$node->{list_in}}) {
				$_->visit($self,$FH);			# parameter
			}
			print $FH "      </ul>\n";
			print $FH "    </li>\n";
		}
		if (scalar(@{$node->{list_inout}})) {
			print $FH "    <li>Parameter(s) INOUT :\n";
			print $FH "      <ul>\n";
			foreach (@{$node->{list_inout}}) {
				$_->visit($self,$FH);			# parameter
			}
			print $FH "      </ul>\n";
			print $FH "    </li>\n";
		}
		if (scalar(@{$node->{list_out}})) {
			print $FH "    <li>Parameter(s) OUT :\n";
			print $FH "      <ul>\n";
			foreach (@{$node->{list_out}}) {
				$_->visit($self,$FH);			# parameter
			}
			print $FH "      </ul>\n";
			print $FH "    </li>\n";
		}
		print $FH "  </ul>\n";
	}
	$self->_format_tags($tags,$FH);
}

#
#	3.8.2	Boxed Value Type
#

sub visitBoxedValue {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	$self->_format_tags($tags,$FH);
}

#
#	3.8.3	Abstract Value Type
#

sub visitAbstractValue {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	$self->_format_tags($tags,$FH);
}

#
#	3.9		Constant Declaration
#

sub visitConstant {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	$self->_format_tags($tags,$FH);
}

#
#	3.10	Type Declaration
#

sub visitTypeDeclarator {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	$self->_format_tags($tags,$FH);
}

#
#	3.10.2	Constructed Types
#
#	3.10.2.1	Structures
#

sub visitStructType {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	my $doc_member = 0;
	foreach (@{$node->{list_value}}) {
		$doc_member ++ if (exists $_->{doc});
	}
	if ($doc_member) {
		print $FH "  <ul>\n";
		foreach (@{$node->{list_value}}) {
			$_->visit($self,$FH);			# single or array
		}
		print $FH "  </ul>\n";
	}
	$self->_format_tags($tags,$FH);
}

sub visitArray {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_line($node,$doc,$FH);
}

sub visitSingle {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_line($node,$doc,$FH);
}

#	3.10.2.2	Discriminated Unions
#

sub visitUnionType {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	my $doc_member = 0;
	foreach (@{$node->{list_value}}) {
		$doc_member ++ if (exists $_->{doc});
	}
	if ($doc_member) {
		print $FH "  <ul>\n";
		foreach (@{$node->{list_expr}}) {
			$_->visit($self,$FH);			# case
		}
		print $FH "  </ul>\n";
	}
	$self->_format_tags($tags,$FH);
}

sub visitCase {
	my $self = shift;
	my($node,$FH) = @_;
	$node->{element}->visit($self,$FH);		# element
}

sub visitElement {
	my $self = shift;
	my($node,$FH) = @_;
	$node->{value}->visit($self,$FH);		# array or single
}

#	3.10.2.3	Enumerations
#

sub visitEnumType {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	my $doc_member = 0;
	foreach (@{$node->{list_value}}) {
		$doc_member ++ if (exists $_->{doc});
	}
	if ($doc_member) {
		print $FH "    <ul>\n";
		foreach (@{$node->{list_expr}}) {
			$_->visit($self,$FH);			# enum
		}
		print $FH "    </ul>\n";
	}
	$self->_format_tags($tags,$FH);
}

sub visitEnum {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_line($node,$doc,$FH);
}

#
#	3.11	Exception Declaration
#

sub visitException {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	my $doc_member = 0;
	foreach (@{$node->{list_value}}) {
		$doc_member ++
				if (exists $_->{doc});
	}
	if ($doc_member) {
		print $FH "  <ul>\n";
		foreach (@{$node->{list_value}}) {
			$_->visit($self,$FH);			# single or array
		}
		print $FH "  </ul>\n";
	}
	$self->_format_tags($tags,$FH);
}

#
#	3.12	Operation Declaration
#

sub visitOperation {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	if (scalar(@{$node->{list_in}}) + scalar(@{$node->{list_inout}}) + scalar(@{$node->{list_out}})) {
		print $FH "  <ul>\n";
		if (scalar(@{$node->{list_in}})) {
			if (scalar(@{$node->{list_in}}) > 1) {
				print $FH "    <li>Parameters IN :\n";
			} else {
				print $FH "    <li>Parameter IN :\n";
			}
			print $FH "      <ul>\n";
			foreach (@{$node->{list_in}}) {
				$_->visit($self,$FH);			# parameter
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
				$_->visit($self,$FH);			# parameter
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
				$_->visit($self,$FH);			# parameter
			}
			print $FH "      </ul>\n";
			print $FH "    </li>\n";
		}
		print $FH "  </ul>\n";
	}
	$self->_format_tags($tags,$FH);
}

sub visitParameter {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_line($node,$doc,$FH);
}

#
#	3.13	Attribute Declaration
#

sub visitAttribute {
	my $self = shift;
	my($node,$FH) = @_;
	my($doc,$tags) = $self->_extract_doc($node);
	$self->_format_doc_bloc($doc,$FH);
	$self->_format_tags($tags,$FH);
}

1;

