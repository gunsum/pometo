-include_lib("eunit/include/eunit.hrl").
-include("parser_records.hrl").

append(#liffey{op = #'¯¯⍴¯¯'{dimensions = [D1]} = R1, args = Args1},
       #liffey{op = #'¯¯⍴¯¯'{dimensions = [D2]},      args = Args2}) ->
  #liffey{op = R1#'¯¯⍴¯¯'{dimensions = [D1 + D2]},
          args = Args1 ++ Args2}.

handle_value(Sign, {_, _, _, _, Val}) ->
  Rho = #'¯¯⍴¯¯'{style      = eager,
                 indexed    = false,
                 dimensions = [1]},
  SignedVal = case Sign of
    positive ->  Val;
    negative -> -Val
  end,
  #liffey{op = Rho, args = [SignedVal]}.

extract(monadic, {scalar_fn, _, _, _, Fnname}, Args) ->
  {#liffey{op = {monadic, Fnname}, args = Args}, #{}};
extract(dyadic, {scalar_fn, _, _, _, Fnname}, Args) ->
  {#liffey{op = {dyadic, Fnname}, args = Args}, #{}}.

make_let({var, _, _, _, Var}, #liffey{} = Expr, Bindings) ->
  {#liffey{op = 'let', args = [list_to_atom(Var), Expr]}, bind(Var, Expr, Bindings)}.

bind(Var, Expr, Bindings) ->
  case maps:is_key(Var, Bindings) of
    true  -> throw("binding should be immutable");
    false -> maps:put(Var, Expr, Bindings)
  end.