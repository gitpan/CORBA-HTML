use strict;
use UNIVERSAL;

package indexVisitor;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser) = @_;
	my $filename = $parser->YYData->{srcname};
	$filename =~ s/^([^\/]+\/)+//;
	$filename =~ s/\.idl$//i;
	$self->{file_html} = '__' . $filename . '.html';
	$self->{done_hash} = {};
	return $self;
}

sub _get_name {
	my $self = shift;
	my($node) = @_;
	my @list_name = split /::/,$node->{coll};
	my @list_scope = split /::/,$self->{scope};
	shift @list_name;
	shift @list_scope;
	while (@list_scope) {
		last if ($list_scope[0] ne $list_name[0]);
		shift @list_name;
		shift @list_scope;
	}
	my $name = join '::',@list_name;
	return $name;
}

#
#	3.5		OMG IDL Specification
#

sub visitSpecification {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$self->{scope} = '::';
	# init
	$self->{index_module} = {};
	$self->{index_interface} = {};
	$self->{index_operation} = {};
	$self->{index_attribute} = {};
	$self->{index_constant} = {};
	$self->{index_exception} = {};
	$self->{index_type} = {};
	$self->{index_value} = {};
	$self->{index_boxed_value} = {};
	$self->{index_state_member} = {};
	$self->{index_initializer} = {};
	foreach (@{$node->{list_decl}}) {
		$_->visit($self);
	}
	# save
	$node->{index_module} = $self->{index_module};
	$node->{index_interface} = $self->{index_interface};
	$node->{index_operation} = $self->{index_operation};
	$node->{index_attribute} = $self->{index_attribute};
	$node->{index_constant} = $self->{index_constant};
	$node->{index_exception} = $self->{index_exception};
	$node->{index_type} = $self->{index_type};
	$node->{index_value} = $self->{index_value};
	$node->{index_boxed_value} = $self->{index_boxed_value};
	$node->{index_state_member} = $self->{index_state_member};
	$node->{index_initializer} = $self->{index_initializer};
}

#
#	3.6		Module Declaration
#

sub visitModule {
	my $self = shift;
	my($node) = @_;
	$self->{scope} = $node->{coll};
	my $filename = $node->{coll};
	$filename =~ s/::/_/g;
	$filename .= '.html';
	$self->{index_module}->{$node->{idf}} = $node;
	# local save
	my $file_html = $self->{file_html};
	my $module = $self->{index_module};
	my $interface = $self->{index_interface};
	my $operation = $self->{index_operation};
	my $attribute = $self->{index_attribute};
	my $constant = $self->{index_constant};
	my $exception = $self->{index_exception};
	my $type = $self->{index_type};
	my $value = $self->{index_value};
	my $boxed_value = $self->{index_boxed_value};
	my $state_member = $self->{index_state_member};
	my $initializer = $self->{index_initializer};
	# re init
	$self->{file_html} = $filename;
	$self->{index_module} = {};
	$self->{index_interface} = {};
	$self->{index_operation} = {};
	$self->{index_attribute} = {};
	$self->{index_constant} = {};
	$self->{index_exception} = {};
	$self->{index_type} = {};
	$self->{index_value} = {};
	$self->{index_boxed_value} = {};
	$self->{index_state_member} = {};
	$self->{index_initializer} = {};
	foreach (@{$node->{list_decl}}) {
		$_->visit($self);
	}
	$node->{file_html} = $self->{file_html};
	$node->{index_module} = $self->{index_module};
	$node->{index_interface} = $self->{index_interface};
	$node->{index_operation} = $self->{index_operation};
	$node->{index_attribute} = $self->{index_attribute};
	$node->{index_constant} = $self->{index_constant};
	$node->{index_exception} = $self->{index_exception};
	$node->{index_type} = $self->{index_type};
	$node->{index_value} = $self->{index_value};
	$node->{index_boxed_value} = $self->{index_boxed_value};
	$node->{index_state_member} = $self->{index_state_member};
	$node->{index_initializer} = $self->{index_initializer};
	# restore
	$self->{file_html} = $file_html;
	$self->{index_module} = $module;
	$self->{index_interface} = $interface;
	$self->{index_operation} = $operation;
	$self->{index_attribute} = $attribute;
	$self->{index_constant} = $constant;
	$self->{index_exception} = $exception;
	$self->{index_type} = $type;
	$self->{index_value} = $value;
	$self->{index_boxed_value} = $boxed_value;
	$self->{index_state_member} = $state_member;
	$self->{index_initializer} = $initializer;
}

#
#	3.7		Interface Declaration
#

sub visitInterface {
	my $self = shift;
	my($node) = @_;
	$self->{scope} = $node->{coll};
	my $filename = $node->{coll};
	$filename =~ s/::/_/g;
	$filename .= '.html';
	$node->{file_html} = $filename;
	$self->{index_interface}->{$node->{idf}} = $node;
	# local save
	my $file_html = $self->{file_html};
	my $module = $self->{index_module};
	my $interface = $self->{index_interface};
	my $operation = $self->{index_operation};
	my $attribute = $self->{index_attribute};
	my $constant = $self->{index_constant};
	my $exception = $self->{index_exception};
	my $type = $self->{index_type};
	my $value = $self->{index_value};
	my $boxed_value = $self->{index_boxed_value};
	my $state_member = $self->{index_state_member};
	my $initializer = $self->{index_initializer};
	# re init
	$self->{file_html} = $filename;
	$self->{index_module} = {};
	$self->{index_interface} = {};
	$self->{index_operation} = {};
	$self->{index_attribute} = {};
	$self->{index_constant} = {};
	$self->{index_exception} = {};
	$self->{index_type} = {};
	$self->{index_value} = {};
	$self->{index_boxed_value} = {};
	$self->{index_state_member} = {};
	$self->{index_initializer} = {};
	foreach (@{$node->{list_decl}}) {
		$_->visit($self);
	}
	$node->{file_html} = $self->{file_html};
	$node->{index_module} = $self->{index_module};
	$node->{index_interface} = $self->{index_interface};
	$node->{index_operation} = $self->{index_operation};
	$node->{index_attribute} = $self->{index_attribute};
	$node->{index_constant} = $self->{index_constant};
	$node->{index_exception} = $self->{index_exception};
	$node->{index_type} = $self->{index_type};
	$node->{index_value} = $self->{index_value};
	$node->{index_boxed_value} = $self->{index_boxed_value};
	$node->{index_state_member} = $self->{index_state_member};
	$node->{index_initializer} = $self->{index_initializer};
	# restore
	$self->{file_html} = $file_html;
	$self->{index_module} = $module;
	$self->{index_interface} = $interface;
	$self->{index_operation} = $operation;
	$self->{index_attribute} = $attribute;
	$self->{index_constant} = $constant;
	$self->{index_exception} = $exception;
	$self->{index_type} = $type;
	$self->{index_value} = $value;
	$self->{index_boxed_value} = $boxed_value;
	$self->{index_state_member} = $state_member;
	$self->{index_initializer} = $initializer;
}

sub visitForwardInterface {
	my $self = shift;
	my($node) = @_;
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
	my $filename = $node->{coll};
	$filename =~ s/::/_/g;
	$filename .= '.html';
	$node->{file_html} = $filename;
	$self->{index_value}->{$node->{idf}} = $node;
	# local save
	my $file_html = $self->{file_html};
	my $module = $self->{index_module};
	my $interface = $self->{index_interface};
	my $operation = $self->{index_operation};
	my $attribute = $self->{index_attribute};
	my $constant = $self->{index_constant};
	my $exception = $self->{index_exception};
	my $type = $self->{index_type};
	my $value = $self->{index_value};
	my $boxed_value = $self->{index_boxed_value};
	my $state_member = $self->{index_state_member};
	my $initializer = $self->{index_initializer};
	# init
	$self->{file_html} = $filename;
	$self->{index_module} = {};
	$self->{index_interface} = {};
	$self->{index_operation} = {};
	$self->{index_attribute} = {};
	$self->{index_constant} = {};
	$self->{index_exception} = {};
	$self->{index_type} = {};
	$self->{index_value} = {};
	$self->{index_boxed_value} = {};
	$self->{index_state_member} = {};
	$self->{index_initializer} = {};
	foreach (@{$node->{list_decl}}) {
		$_->visit($self);
	}
	$node->{file_html} = $self->{file_html};
	$node->{index_module} = $self->{index_module};
	$node->{index_interface} = $self->{index_interface};
	$node->{index_operation} = $self->{index_operation};
	$node->{index_attribute} = $self->{index_attribute};
	$node->{index_constant} = $self->{index_constant};
	$node->{index_exception} = $self->{index_exception};
	$node->{index_type} = $self->{index_type};
	$node->{index_value} = $self->{index_value};
	$node->{index_boxed_value} = $self->{index_boxed_value};
	$node->{index_state_member} = $self->{index_state_member};
	$node->{index_initializer} = $self->{index_initializer};
	# restore
	$self->{file_html} = $file_html;
	$self->{index_module} = $module;
	$self->{index_interface} = $interface;
	$self->{index_operation} = $operation;
	$self->{index_attribute} = $attribute;
	$self->{index_constant} = $constant;
	$self->{index_exception} = $exception;
	$self->{index_type} = $type;
	$self->{index_value} = $value;
	$self->{index_boxed_value} = $boxed_value;
	$self->{index_state_member} = $state_member;
	$self->{index_initializer} = $initializer;
}

sub visitStateMembers {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_value}}) {
		$_->visit($self);
	}
}

sub visitStateMember {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$self->{index_state_member}->{$node->{idf}} = $node;
}

sub visitFactory {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$self->{index_initializer}->{$node->{idf}} = $node;
}

#
#	3.8.2	Boxed Value Type
#

sub visitBoxedValue {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$self->{index_boxed_value}->{$node->{idf}} = $node;
}

#
#	3.8.3	Abstract Value Type
#

sub visitAbstractValue {
	my $self = shift;
	my($node) = @_;
	$self->{scope} = $node->{coll};
	my $filename = $node->{coll};
	$filename =~ s/::/_/g;
	$filename .= '.html';
	$node->{file_html} = $filename;
	$self->{index_value}->{$node->{idf}} = $node;
	# local save
	my $file_html = $self->{file_html};
	my $module = $self->{index_module};
	my $interface = $self->{index_interface};
	my $operation = $self->{index_operation};
	my $attribute = $self->{index_attribute};
	my $constant = $self->{index_constant};
	my $exception = $self->{index_exception};
	my $type = $self->{index_type};
	my $value = $self->{index_value};
	my $boxed_value = $self->{index_boxed_value};
	my $state_member = $self->{index_state_member};
	my $initializer = $self->{index_initializer};
	# init
	$self->{file_html} = $filename;
	$self->{index_module} = {};
	$self->{index_interface} = {};
	$self->{index_operation} = {};
	$self->{index_attribute} = {};
	$self->{index_constant} = {};
	$self->{index_exception} = {};
	$self->{index_type} = {};
	$self->{index_value} = {};
	$self->{index_boxed_value} = {};
	$self->{index_state_member} = {};
	$self->{index_initializer} = {};
	foreach (@{$node->{list_decl}}) {
		$_->visit($self);
	}
	$node->{file_html} = $self->{file_html};
	$node->{index_module} = $self->{index_module};
	$node->{index_interface} = $self->{index_interface};
	$node->{index_operation} = $self->{index_operation};
	$node->{index_attribute} = $self->{index_attribute};
	$node->{index_constant} = $self->{index_constant};
	$node->{index_exception} = $self->{index_exception};
	$node->{index_type} = $self->{index_type};
	$node->{index_value} = $self->{index_value};
	$node->{index_boxed_value} = $self->{index_boxed_value};
	$node->{index_state_member} = $self->{index_state_member};
	$node->{index_initializer} = $self->{index_initializer};
	# restore
	$self->{file_html} = $file_html;
	$self->{index_module} = $module;
	$self->{index_interface} = $interface;
	$self->{index_operation} = $operation;
	$self->{index_attribute} = $attribute;
	$self->{index_constant} = $constant;
	$self->{index_exception} = $exception;
	$self->{index_type} = $type;
	$self->{index_value} = $value;
	$self->{index_boxed_value} = $boxed_value;
	$self->{index_state_member} = $state_member;
	$self->{index_initializer} = $initializer;
}

#
#	3.8.4	Value Forward Declaration
#

sub visitForwardRegularValue {
	my $self = shift;
	my($node) = @_;
}

sub visitForwardAbstractValue {
	my $self = shift;
	my($node) = @_;
}

#
#	3.9		Constant Declaration
#

sub visitConstant {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$self->{index_constant}->{$node->{idf}} = $node;
}

#
#	3.10	Type Declaration
#

sub visitTypeDeclarators {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_value}}) {
		$_->visit($self);
	}
}

sub visitTypeDeclarator {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$self->{index_type}->{$node->{idf}} = $node;
	return if (exists $node->{modifier});	# native IDL2.2
	if (	   $node->{type}->isa('StructType')
			or $node->{type}->isa('UnionType')
			or $node->{type}->isa('EnumType') ) {
		$node->{type}->visit($self);
	}
}

#
#	3.10.2	Constructed Types
#

sub visitStructType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{coll}});
	$self->{done_hash}->{$node->{coll}} = 1;
	my $name = $self->_get_name($node);
	$self->{index_type}->{$name} = $node;
	$node->{html_name} = $name;
	$node->{file_html} = $self->{file_html};
	foreach (@{$node->{list_expr}}) {
		if (	   $_->{type}->isa('StructType')
				or $_->{type}->isa('UnionType') ) {
			$_->{type}->visit($self);
		}
	}
	foreach (@{$node->{list_value}}) {
		$_->visit($self);				# single or array
	}
}

sub visitArray {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$node->{html_name} = $self->_get_name($node);
}

sub visitSingle {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$node->{html_name} = $self->_get_name($node);
}

sub visitUnionType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{coll}});
	$self->{done_hash}->{$node->{coll}} = 1;
	my $name = $self->_get_name($node);
	$self->{index_type}->{$name} = $node;
	$node->{html_name} = $name;
	$node->{file_html} = $self->{file_html};
	if ($node->{type}->isa('EnumType')) {
		$node->{type}->visit($self);
	}
	foreach (@{$node->{list_expr}}) {	# case
		if (	   $_->{element}->{type}->isa('StructType')
				or $_->{element}->{type}->isa('UnionType') ) {
			$_->{element}->{type}->visit($self);
		}
		$_->{element}->{value}->visit($self);	# array or single
	}
}

sub visitEnumType {
	my $self = shift;
	my($node) = @_;
	my $name = $self->_get_name($node);
	$self->{index_type}->{$name} = $node;
	$node->{html_name} = $name;
	$node->{file_html} = $self->{file_html};
	foreach (@{$node->{list_expr}}) {
		$_->visit($self);				# enum
	}
}

sub visitEnum {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$node->{html_name} = $self->_get_name($node);
}

#
#	3.10.3	Constructed Recursive Types and Forward Declarations
#

sub visitForwardStructType {
	my $self = shift;
	my($node) = @_;
}

sub visitForwardUnionType {
	my $self = shift;
	my($node) = @_;
}

#
#	3.11	Exception Declaration
#

sub visitException {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$self->{index_exception}->{$node->{idf}} = $node;
	foreach (@{$node->{list_value}}) {
		$_->visit($self);				# single or array
	}
}

#
#	3.12	Operation Declaration
#

sub visitOperation {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$self->{index_operation}->{$node->{idf}} = $node;
}

#
#	3.13	Attribute Declaration
#

sub visitAttributes {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_value}}) {
		$_->visit($self);				# attribute
	}
}

sub visitAttribute {
	my $self = shift;
	my($node) = @_;
	$node->{file_html} = $self->{file_html};
	$self->{index_attribute}->{$node->{idf}} = $node;
}

1;

