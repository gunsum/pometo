-module(scope_dictionary).

-export([
			puts/1,
			are_current_bindings_valid/0,
			can_bindings_be_consolidated/0,
			consolidate_bindings/0,
			get_bindings/0,
			get_current_bindings/0,
			%gets/1,
			%get_keys/1,
			clear/1,
			clear_all/0,
			put_line_no/1,
			get_line_no/0,
			get_errors/0,
			append_error/1
		]).

%% debugging export
-export([
		  'print_DEBUG'/1
		]).

-include_lib("eunit/include/eunit.hrl").
-include("parser_records.hrl").
-include("errors.hrl").

-define(EMPTYDUPS, []).

%%
%% This module uses the process dictionary for scope
%%

-record(storage, {
				  current         = [],
				  current_line_no = none,
				  bindings        = #{},
				  errors          = []
			     }).

%% this function appends the term to the PD as a list under a key called `'$POMETO_DATA'`
puts(Term) ->
	case get('$POMETO_DATA') of
		#storage{current = C} = S ->
			put('$POMETO_DATA', S#storage{current = [Term | C]});
	    undefined ->
			put('$POMETO_DATA',  #storage{current = [Term]})
		end,
	ok.

are_current_bindings_valid() ->
	case get('$POMETO_DATA') of
		#storage{current = C} ->
			case get_duplicates(C) of
                []   -> true;
                Dups -> {false, Dups}
			end;
	    undefined ->
            true
		end.

consolidate_bindings() ->
	case get('$POMETO_DATA') of
		[] ->
			true;
		#storage{current  = C,
				 bindings = Bindings} = S ->
			ConsolidateFn = fun({K, V}, Bs) ->
				maps:put(K, V, Bs)
			end,
			NewBs =  lists:foldl(ConsolidateFn, Bindings, C),
			put('$POMETO_DATA', S#storage{current  = [],
				                  		  bindings = NewBs})
	end,
	ok.

can_bindings_be_consolidated() ->
	case get('$POMETO_DATA') of
		[] ->
			true;
		#storage{current  = C,
				 bindings = Bindings} ->
			TestKeysFn = fun({K, CurrentBinding}, Acc) ->
				case maps:is_key(K, Bindings) of
					false -> Acc;
					true  -> [{K, {maps:get(K, Bindings), CurrentBinding}} | Acc]
				end
			end,
			Test = lists:foldl(TestKeysFn, ?EMPTYDUPS, C),
			case Test of
				[] -> true;
				_  -> {false, Test}
			end
	end.

apply_bindings(#liffey{} = L) ->
	L;
apply_bindings(X) ->
	X.

get_bindings() ->
	case get('$POMETO_DATA') of
		#storage{bindings = Bindings} -> Bindings;
	    undefined           -> #{}
	end.

get_current_bindings() ->
	case get('$POMETO_DATA') of
		#storage{current = C} -> maps:from_list(C);
	    undefined             -> #{}
	end.


%get_keys() ->
%	case get('$POMETO_DATA') of
%		#storage{bindings = Bindings} = S -> maps:keys(Bindings);
%	    undefined               -> []
%	end.

%gets(Scope) ->
%	#storage{bindings = Bindings} = get('$POMETO_DATA'),
%	case maps:is_key(Scope, Bindings) of
%		true  -> {ok,    maps:get(Scope, Bindings)};
%		false -> {error, io_lib:format("no key called ~p", [Scope])}
%	end.

clear_all() ->
	erase(),
	ok.

clear(Scope) ->
	#storage{bindings = Bindings} = S = get('$POMETO_DATA'),
	NewBindings = map:remove(Scope, Bindings),
	put('$POMETO_DATA', S#storage{bindings = NewBindings}),
	ok.

put_line_no(N) ->
	case get('$POMETO_DATA') of
		#storage{} = S ->
			put('$POMETO_DATA', S#storage{current_line_no = N});
	    undefined ->
			put('$POMETO_DATA', #storage{current_line_no = N})
	end,
	ok.

get_line_no() ->
	#storage{current_line_no = N} = get('$POMETO_DATA'),
	N.

get_duplicates(Bindings) -> get_dups(lists:sort(Bindings), ?EMPTYDUPS).

get_dups([],                      Dups) -> Dups;
get_dups([_H               | []], Dups) -> Dups;
% three in a row is two errors
get_dups([{K, V1}, {K, V2} | T],  Dups) -> get_dups([{K, V2} | T], [{K, {V1, V2}} | Dups]);
get_dups([_H               | T],  Dups) -> get_dups(T, Dups).

print_DEBUG(Label) ->
	?debugFmt("~n*************************************************~n~n", []),
	?debugFmt(Label ++ "~n", []),
	S = get('$POMETO_DATA'),
	case S of
		undefined ->
		?debugFmt("there is nothing in the scope dictionary~n", []);
	#storage{current         = C,
			 current_line_no = N,
			 bindings        = Bindings} ->
		?debugFmt("The current accumulator is ~p~n", [C]),
		?debugFmt("The current line no is ~p~n", [N]),
		?debugFmt("The Bindings are ~p~n", [Bindings])
	end,
	?debugFmt("~n*************************************************~n", []).

append_error(Err) ->
	?debugFmt("in append err for ~p~n", [Err]),
	case get('$POMETO_DATA') of
		#storage{errors = Errs} = S ->
		?debugFmt("in append err with errs of ~p~n", [Errs]),
			put('$POMETO_DATA', S#storage{errors = [Err | Errs]});
	    undefined ->
			put('$POMETO_DATA',  #storage{errors = [Err]})
	end,
	ok.

get_errors() ->
	case get('$POMETO_DATA') of
		#storage{errors = Errs} -> lists:reverse(Errs);
	    undefined               -> []
	end.
