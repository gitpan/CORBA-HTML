use strict;
use UNIVERSAL;

package HTMLnameVisitor;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	return $self;
}

sub _get_name {
	my $self = shift;
	my($node,$scope) = @_;
	my $coll = $node->{coll};
	$coll =~ s/^:://;
	my @list_name = split /::/,$coll;
	my @list_scope = split /::/,$scope;
	while (@list_scope) {
		last if ($list_scope[0] ne $list_name[0]);
		shift @list_name;
		shift @list_scope;
	}
	my $name = join '::',@list_name;
	my $fragment = $node->{idf};
	$fragment = $node->{html_name} if (exists $node->{html_name});
	my $a = "<a href='" . $node->{file_html} . "#" . $fragment . "'>" . $name . "</a>";
	return $a;
}

sub _get_lexeme {
	my $self = shift;
	my($node) = @_;
	my $value = $node->{lexeme};
	$value =~ s/&/"&amp;"/g;
	$value =~ s/</"&lt;"/g;
	$value =~ s/>/"&gt;"/g;
	return $value;
}

sub visitNameInterface {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

sub visitNameForwardInterface {
	my $self = shift;
	my($node,$scope) = @_;
	return $node->{fwd}->visitName($self,$scope);
}

sub visitNameRegularValue {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

sub visitNameForwardRegularValue {
	my $self = shift;
	my($node,$scope) = @_;
	return $node->{fwd}->visitName($self,$scope);
}

sub visitNameBoxedValue {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

sub visitNameAbstractValue {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

sub visitNameForwardAbstractValue {
	my $self = shift;
	my($node,$scope) = @_;
	return $node->{fwd}->visitName($self,$scope);
}

sub visitNameConstant {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

sub visitNameTypeDeclarator {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

sub visitNameBasicType {
	my $self = shift;
	my($node) = @_;
	return $node->{value};
}

sub visitNameAnyType {
	my $self = shift;
	my($node) = @_;
	return $node->{value};
}

sub visitNameStructType {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

sub visitNameUnionType {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

sub visitNameEnumType {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

sub visitNameForwardStructType {
	my $self = shift;
	my($node,$scope) = @_;
	return $node->{fwd}->visitName($self,$scope);
}

sub visitNameForwardUnionType {
	my $self = shift;
	my($node,$scope) = @_;
	return $node->{fwd}->visitName($self,$scope);
}

sub visitNameSequenceType {
	my $self = shift;
	my($node,$scope) = @_;
	my $type = $node->{type};
	my $name = $node->{value} . "&lt;";
	$name .= $type->visitName($self,$scope);
	if (exists $node->{max}) {
		$name .= ",";
		$name .= $node->{max}->visitName($self,$scope);
	}
	$name .= "&gt;";
	return $name;
}

sub visitNameStringType {
	my $self = shift;
	my($node,$scope) = @_;
	if (exists $node->{max}) {
		my $name = $node->{value} . "&lt;";
		$name .= $node->{max}->visitName($self,$scope);
		$name .= "&gt;";
		return $name;
	} else {
		return $node->{value};
	}
}

sub visitNameWideStringType {
	my $self = shift;
	my($node,$scope) = @_;
	if (exists $node->{max}) {
		my $name = $node->{value} . "&lt;";
		$name .= $node->{max}->visitName($self,$scope);
		$name .= "&gt;";
		return $name;
	} else {
		return $node->{value};
	}
}

sub visitNameFixedPtType {
	my $self = shift;
	my($node,$scope) = @_;
	if (exists $node->{d}) {
		my $name = $node->{value} . "&lt;";
		$name .= $node->{d}->visitName($self,$scope);
		$name .= ",";
		$name .= $node->{s}->visitName($self,$scope);
		$name .= "&gt;";
		return $name;
	} else {
		return $node->{value};
	}
}

sub visitNameVoidType {
	my $self = shift;
	my($node) = @_;
	return $node->{value};
}

sub visitNameException {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

sub visitNameValueBaseType {
	my $self = shift;
	my($node) = @_;
	return $node->{value};
}

sub visitNameOperation {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

sub visitNameAttribute {
	my $self = shift;
	my($node,$scope) = @_;
	return $self->_get_name($node,$scope);
}

#
#

sub visitNameEnum {
	my $self = shift;
	my($node, $attr) = @_;
	return $node->{idf};
}

sub visitNameIntegerLiteral {
	my $self = shift;
	my($node) = @_;
	return $self->_get_lexeme($node);
}

sub visitNameStringLiteral {
	my $self = shift;
	my($node) = @_;
	my @list = unpack "C*",$node->{value};
	my $str = "\"";
	foreach (@list) {
		if      ($_ < 32 or $_ >= 127) {
			$str .= sprintf "\\x%02x",$_;
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

sub visitNameWideStringLiteral {
	my $self = shift;
	my($node) = @_;
	my @list = unpack "C*",$node->{value};
	my $str = "L\"";
	foreach (@list) {
		if      ($_ < 32 or ($_ >= 128 and $_ < 256)) {
			$str .= sprintf "\\x%02x",$_;
		} elsif ($_ >= 256) {
			$str .= sprintf "\\u%04x",$_;
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

sub visitNameCharacterLiteral {
	my $self = shift;
	my($node) = @_;
	my @list = unpack "C",$node->{value};
	my $c = $list[0];
	my $str = "'";
	if      ($c < 32 or $c >= 128) {
		$str .= sprintf "\\x%02x",$c;
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

sub visitNameWideCharacterLiteral {
	my $self = shift;
	my($node) = @_;
	my @list = unpack "C",$node->{value};
	my $c = $list[0];
	my $str = "L'";
	if      ($c < 32 or ($c >= 128 and $c < 256)) {
		$str .= sprintf "\\x%02x",$c;
	} elsif ($c >= 256) {
		$str .= sprintf "\\u%04x",$c;
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

sub visitNameFixedPtLiteral {
	my $self = shift;
	my($node) = @_;
	return $self->_get_lexeme($node);
}

sub visitNameFloatingPtLiteral {
	my $self = shift;
	my($node) = @_;
	return $self->_get_lexeme($node);
}

sub visitNameBooleanLiteral {
	my $self = shift;
	my($node) = @_;
	return $node->{value};
}

sub _Eval {
	my $self = shift;
	my($list_expr,$scope,$type) = @_;
	my $elt = pop @{$list_expr};
	if (       $elt->isa('BinaryOp') ) {
		my $right = $self->_Eval($list_expr,$scope,$type);
		my $left = $self->_Eval($list_expr,$scope,$type);
		return "(" . $left . " " . $elt->{op} . " " . $right . ")";
	} elsif (  $elt->isa('UnaryOp') ) {
		my $right = $self->_Eval($list_expr,$scope,$type);
		return $elt->{op} . $right;
	} elsif (  $elt->isa('Constant')
			or $elt->isa('Enum')
			or $elt->isa('Literal') ) {
		return $elt->visitName($self,$scope,$type);
	} else {
		warn __PACKAGE__," _Eval: INTERNAL ERROR ",ref $elt,".\n";
		return undef;
	}
}

sub visitNameExpression {
	my $self = shift;
	my($node,$scope) = @_;
	my @list_expr = @{$node->{list_expr}};		# create a copy
	return $self->_Eval(\@list_expr,$scope,$node->{type});
}

1;

