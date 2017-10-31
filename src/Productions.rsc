@license{
  Copyright (c) 2009-2015 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Jurgen J. Vinju - Jurgen.Vinju@cwi.nl - CWI}
@contributor{Arnold Lankamp - Arnold.Lankamp@cwi.nl}
module Productions

     
import lang::rascal::\syntax::Rascal;
import lang::rascal::grammar::definition::Characters;
import lang::rascal::grammar::definition::Symbols;
import lang::rascal::grammar::definition::Attributes;
import lang::rascal::grammar::definition::Names;

import Grammar;
import List; 
import String;    
import ParseTree;
import IO;  
import util::Math;
import util::Maybe;

anno loc SyntaxDefinition@\loc;
anno loc Production@\loc;
//anno loc Production@location;
anno loc Symbol@\loc;
anno loc node@\loc;

// conversion functions

public Grammar syntax2grammar(set[SyntaxDefinition] defs) {
  set[Production] prods = {prod(Symbol::empty(),[],{}), prod(layouts("$default$"),[],{})};
  set[Symbol] starts = {};
  
  for (sd <- defs) {
    <ps,st> = rule2prod(sd);
    prods += ps;
    if (st is just)
      starts += st.val;
  }
  
  return grammar(starts, prods);
}

public tuple[set[Production] prods, Maybe[Symbol] \start] rule2prod(SyntaxDefinition sd) {  
    switch (sd) {
      case x:\layout(_, nonterminal(Nonterminal n), Prod p) : 
        return <{prod2prod(\layouts("<n>"), p)[@\loc=x@\loc]},nothing()>;
      case x:\language(present() /*start*/, nonterminal(Nonterminal n), Prod p) : 
        return < {prod(\start(sort("<n>")),[label("top", sort("<n>"))],{})[@\loc=x@\loc]
                ,prod2prod(sort("<n>"), p)[@\loc=x@\loc]}
               ,just(\start(sort("<n>")))>;
      case x:\language(absent(), parametrized(Nonterminal l, {Sym ","}+ syms), Prod p) : 
        return <{prod2prod(\parameterized-sort("<l>",separgs2symbols(syms)), p)[@\loc=x@\loc]}, nothing()>;
      case x:\language(absent(), nonterminal(Nonterminal n), Prod p) : 
        return <{prod2prod(\sort("<n>"), p)[@\loc=x@\loc]},nothing()>;
      case x:\lexical(parametrized(Nonterminal l, {Sym ","}+ syms), Prod p) : 
        return <{prod2prod(\parameterized-lex("<l>",separgs2symbols(syms)), p)[@\loc=x@\loc]}, nothing()>;
      case x:\lexical(nonterminal(Nonterminal n), Prod p) : 
        return <{prod2prod(\lex("<n>"), p)[@\loc=x@\loc]}, nothing()>;
      case x:\keyword(nonterminal(Nonterminal n), Prod p) : 
        return <{prod2prod(keywords("<n>"), p)[@\loc=x@\loc]}, nothing()>;
      default: { iprintln(sd); throw "unsupported kind of syntax definition? <sd> at <sd@\loc>"; }
    }
} 


private Production prod2prod(Symbol nt, Prod p) {
  switch(p) {
    case z:labeled(ProdModifier* ms, Name n, Sym* args) : 
      if ([Sym x] := args.args, x is empty) {
        return prod(label("<n>",nt), [], mods2attrs(ms))[@\loc=z@\loc];
      }
      else {
        return prod(label(unescape("<n>"),nt),args2symbols(args),mods2attrs(ms))[@\loc=z@\loc];
      }
    case z:unlabeled(ProdModifier* ms, Sym* args) :
      if ([Sym x] := args.args, x is empty) {
        return prod(nt, [], mods2attrs(ms))[@\loc=z@\loc];
      }
      else {
        return prod(nt,args2symbols(args),mods2attrs(ms))[@\loc=z@\loc];
      }     
    case x:\all(Prod l, Prod r) :
      return choice(nt,{prod2prod(nt, l), prod2prod(nt, r)})[@\loc=x@\loc];
    case x:\first(Prod l, Prod r) : 
      return priority(nt,[prod2prod(nt, l), prod2prod(nt, r)])[@\loc=x@\loc];
    case x:associativityGroup(\left(), Prod q) :
      return associativity(nt, Associativity::\left(), {prod2prod(nt, q)})[@\loc=x@\loc];
    case x:associativityGroup(\right(), Prod q) :
      return associativity(nt, Associativity::\right(), {prod2prod(nt, q)})[@\loc=x@\loc];
    case x:associativityGroup(\nonAssociative(), Prod q) :      
      return associativity(nt, \non-assoc(), {prod2prod(nt, q)})[@\loc=x@\loc];
    case x:associativityGroup(\associative(), Prod q) :      
      return associativity(nt, Associativity::\left(), {prod2prod(nt, q)})[@\loc=x@\loc];
    case x:others(): return \others(nt)[@\loc=x@\loc];
    case x:reference(Name n): return \reference(nt, "<n>")[@\loc=x@\loc];
    default: throw "prod2prod, missed a case <p>";
  } 
}

@doc{"..." in a choice is a no-op}   
public Production choice(Symbol s, {*Production a, others(Symbol t)}) {
  if (a == {})
    return others(t);
  else
    return choice(s, a);
}

@doc{This implements the semantics of "..." under a priority group}
public Production choice(Symbol s, {*Production a, priority(Symbol t, [*Production b, others(Symbol u), *Production c])}) 
  = priority(s, b + [choice(s, a)] + c);

  