Nonterminals

Exprs
Expr
Vecs
Vector
Scalar
Let
Value
Var
Fn
Fns
Dyadic
Monadic
Int
Rank
Args

.

Terminals

let_op
var
int
float
unary_negate
seperator
complex_number
maybe_complex_number
open_bracket
close_bracket
open_sq
close_sq
ambivalent
dyadic
monadic
monadic_ranked
hybrid
stdlib

.

Rootsymbol Exprs.
Endsymbol  '$end'.

Left 100 Vector.
Left 200 Expr.
Left 300 Scalar.
Left 400 open_bracket.
Left 400 open_sq.

Exprs -> Expr                  : ['$1'].
Exprs -> Exprs seperator Exprs : '$1' ++ '$3'.

Expr -> Dyadic      : '$1'.
Expr -> Monadic     : '$1'.
Expr -> Let         : '$1'.
Expr -> Vecs        : '$1'.
Expr -> stdlib Vecs : make_stdlib('$1', '$2').

Dyadic  -> Args Fns Args : make_dyadic('$2', '$1', '$3').
Monadic ->      Fns Args : make_monadic('$1', '$2').

Args -> Vecs : '$1'.
Args -> Var  : '$1'.

Fns -> Fn        : '$1'.
Fns -> Fns Fn    : maybe_merge('$1', '$2').

Fn -> hybrid     : make_fn_ast('$1').
Fn -> monadic    : make_fn_ast('$1').
Fn -> dyadic     : make_fn_ast('$1').
Fn -> ambivalent : make_fn_ast('$1').
Fn -> Rank       : log('$1', "$$$$$ranked is ").

Rank -> monadic_ranked                        : add_rank('$1', default_rank('$1')).
Rank -> monadic_ranked open_sq Int   close_sq : add_rank('$1', '$3').
Rank -> monadic_ranked open_sq float close_sq : add_rank('$1', '$3').

Let -> Var let_op Vecs : make_let('$1', '$3').
Let -> Var let_op Expr : make_let('$1', '$3').

Vecs -> Vector      : '$1'.
Vecs -> Vecs Vector : append('$1', '$2').

Scalar -> open_bracket Vector close_bracket : maybe_enclose_vector('$1', '$2').
Scalar -> unary_negate Value                : handle_value(negative, '$2').
Scalar -> Value                             : handle_value(positive, '$1').
Scalar -> unary_negate int                  : handle_value(negative, make_scalar('$2', number)).
Scalar -> int                               : handle_value(positive, make_scalar('$1', number)).
Scalar -> Var                               : '$1'.

% a vector of ints might be a rank or it might be a vector of ints
Vector -> Scalar                         : '$1'.
Vector -> Vector Scalar                  : append('$1', '$2').
Vector -> Vector Int                     : append('$1', '$2').

Value -> float                : make_scalar('$1', number).
Value -> complex_number       : make_scalar('$1', complex).
Value -> maybe_complex_number : make_scalar('$1', complex).

Int -> unary_negate int : handle_value(negative, make_scalar('$2', number)).
Int -> int              : handle_value(positive, make_scalar('$1', number)).
Int -> Int int          : append('$1', make_scalar('$2', number)).

Var -> var : make_var('$1').

Erlang code.

-include("parser_include.hrl").
