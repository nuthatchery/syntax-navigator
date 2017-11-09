module Grammars
import List;
import Productions;
import ParseTree;
import String;
import Grammar;
import util::Reflective;
import lang::rascal::grammar::definition::Modules;
import lang::rascal::\syntax::Rascal;
import IO;
import Triples;

alias SymTable = map[Symbol,Id];

public Graph metaGraph = newGraph("metaGraph");
public Id STRUCTURAL = newId(metaGraph, "structural");

public Graph metaGrammar = newGraph("metaGrammar");
	
public Id SORT = newId(metaGrammar, "sort");
public Id START = newId(metaGrammar, "start");
public Id CF_SORT = newId(metaGrammar, "cfSort");
public Id LEX_SORT = newId(metaGrammar, "lexSort");
public Id LAYOUT_SORT = newId(metaGrammar, "layoutSort");
public Id KW_SORT = newId(metaGrammar, "kwSort");
public Id SYMBOL = newId(metaGrammar, "symbol");
public Id PRODUCTION = newId(metaGrammar, "production");
public Id CF_SYM = newId(metaGrammar, "contextFree");
public Id LEX_SYM = newId(metaGrammar, "lexical");
public Id LAYOUT_SYM = newId(metaGrammar, "layout");
public Id KW_SYM = newId(metaGrammar, "keyword");
public Id LIT_SYM = newId(metaGrammar, "literal");
public Id CILIT_SYM = ident(newId(metaGrammar, "literal"), "insensitive");
public Id CC_SYM = newId(metaGrammar, "charClass");
public Id EMPTY_SYM = newId(metaGrammar, "empty");
public Id OPT_SYM = newId(metaGrammar, "optional");
public Id ITER_STAR_SYM = newId(metaGrammar, "iterStar");
public Id ITER_STAR_SEPS_SYM = newId(metaGrammar, "iterStarSeps");
public Id ITER_PLUS_SEPS_SYM = newId(metaGrammar, "iterPlusSeps");
public Id ITER_PLUS_SYM = newId(metaGrammar, "iterPlus");
public Id ALT_SYM = newId(metaGrammar, "alternatives");
public Id SEQ_SYM = newId(metaGrammar, "sequence");
public Id SOURCE = newId(metaGrammar, "source");
public Id STRING_VALUE = newId(metaGrammar, "stringValue");
public Id ELEMENT = newId(metaGrammar, "element");


Id nextId(this(), int childNum) = ident(".<childNum>");
Id nextId(ident(parent, old), int childNum) = ident(parent, "<old>.<childNum>");
Id nextId(ident(old), int childNum) = ident("<old>.<childNum>");
Id nextId(ident(parent, old), int childNum) = ident(parent, "<old>.<childNum>");

public tuple[Graph,map[Production,loc]] loadGrammar(loc grammarModule) {
	Module m = parseModule(grammarModule);
	<n,_,_> = getModuleMetaInf(m);
	set[SyntaxDefinition] syntaxDefs = getModuleSyntaxDefinitions(m);
	Grammar gr = Productions::syntax2grammar(syntaxDefs);
	g = grammarToGraph(gr, n);
	return <g, findGrammarLocs(gr)>;
}


public Graph grammarToGraph(Grammar gr, str name) {
	Graph g = newGraph(name);
	g += <SORT,IS,STRUCTURAL>;
	g += <ELEMENT,IS,STRUCTURAL>;
	
	
	SymTable symTable = ();
	id = this();
	int i = 0;	
	for(s <- gr.starts) {
		childId = nextId(id, i);
		<childId, symTable> = symToId(s, childId, symTable);
		g += <this(), START, childId>;
	}

	i = 0;	
	for(s <- gr.rules) {
		childId = nextId(id, i);
		<childId, symTable> = symToId(s, childId, symTable);
		g += <this(), SORT, childId>;

//		println("<s>: <gr.rules[s]>");
		<g,symTable> = prodToGraph(gr.rules[s], childId, g, symTable);
		i += 1;
	}
	return g;
}
public tuple[Graph,SymTable] prodToGraph(P:choice(_,alts), Id id, Graph g, SymTable symTable) {
	g += <id, CONFORMS_TO, PRODUCTION>;
	int i = 0;
	for(p <- alts) {
		childId = nextId(id, i);
		g += <id, ELEMENT, childId>;
		<g, symTable> = prodToGraph(p, childId, g, symTable);
		i += 1;
	}
	return <g, symTable>;
}
public tuple[Graph,SymTable] prodToGraph(P:prod(s,syms,_), Id id, Graph g, SymTable symTable) {
	//<id, symTable> = symToId(s, id, symTable);
	g += <id, CONFORMS_TO, PRODUCTION>;
//	g += <id, STRING_VALUE, string(prodToStr(P))>;
	if(P@\loc?) {
		g += <id, SOURCE, uri(P@\loc)>;
	}
	return symToGraph(seq(syms), id, g, symTable);
}

public tuple[Graph,SymTable] symToGraph(S:alt(alts), Id id, Graph g, SymTable symTable) {
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, IS, ALT_SYM>;
	int i = 0;
	for(p <- alts) {
		childId = nextId(id, i);
		<childId, symTable> = symToId(p, childId, symTable);
		g += <id, ELEMENT, childId>;
		<g, symTable> = symToGraph(p, childId, g, symTable);
		i += 1;
	}
	return <g, symTable>;
}

public tuple[Graph,SymTable] symToGraph(S:seq(syms), Id id, Graph g, SymTable symTable) {
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, IS, SEQ_SYM>;
	g += <id, IS, STRUCTURAL>;
	int i = 0;
	for(p <- syms) {
		childId = nextId(id, i);
		<childId, symTable> = symToId(p, childId, symTable);
		g += <id, ordinal("element", i), childId>;
		<g, symTable> = symToGraph(p, childId, g, symTable);
		i += 1;
	}
	return <g, symTable>;
}

public tuple[Graph,SymTable] symToGraph(S:iter(Symbol s), Id id, Graph g, SymTable symTable) {
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, IS, ITER_PLUS_SYM>;
	childId = nextId(id, 0);
	<childId, symTable> = symToId(s, childId, symTable);
	g += <id, ELEMENT, childId>;
	<g, symTable> = symToGraph(s, childId, g, symTable);
	return <g, symTable>;
}

public tuple[Graph,SymTable] symToGraph(S:\char-class(rng), Id id, Graph g, SymTable symTable) {
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, IS, CC_SYM>;
	//g += <id, STRING_VALUE, string(printSymbol(S,true))>;
	for(range(f,t) <- rng) {
		if(f == t) {
			g += <id, ELEMENT, uri(|values://characters/<"<f>">|)>;
		}
		else {
			g += <id, ELEMENT, uri(|values://characters/<"<f>">/to/<"<t>">|)>;
		}
	}
	return <g, symTable>;
}

public tuple[Graph,SymTable] symToGraph(S:\iter-star(s), Id id, Graph g, SymTable symTable) {
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, IS, ITER_STAR_SYM>;
	childId = nextId(id, 0);
	<childId, symTable> = symToId(s, childId, symTable);
	g += <id, ELEMENT, childId>;
	<g, symTable> = symToGraph(s, childId, g, symTable);
	return <g, symTable>;
}

public tuple[Graph,SymTable] symToGraph(S:\lex(s), Id id, Graph g, SymTable symTable)
	= basicSymToGraph(S, s, LEX_SYM, id, g, symTable);
public tuple[Graph,SymTable] symToGraph(S:\sort(s), Id id, Graph g, SymTable symTable)
	= basicSymToGraph(S, s, CF_SYM, id, g, symTable);
public tuple[Graph,SymTable] symToGraph(S:\lit(s), Id id, Graph g, SymTable symTable)
	= basicSymToGraph(S, s, LIT_SYM, id, g, symTable);
public tuple[Graph,SymTable] symToGraph(S:\cilit(s), Id id, Graph g, SymTable symTable)
	= basicSymToGraph(S, s, CILIT_SYM, id, g, symTable);
public tuple[Graph,SymTable] symToGraph(S:\keywords(s), Id id, Graph g, SymTable symTable)
	= basicSymToGraph(S, s, KW_SYM, id, g, symTable);
public tuple[Graph,SymTable] symToGraph(S:\layouts(s), Id id, Graph g, SymTable symTable)
	= basicSymToGraph(S, s, LAYOUT_SYM, id, g, symTable);
	
public tuple[Graph,SymTable] basicSymToGraph(Symbol S, str s, Id kind, Id id, Graph g, SymTable symTable) {
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, IS, kind>;
	if(kind in [LIT_SYM,CILIT_SYM])
		g += <id, STRING_VALUE, string(s)>;
	g += <id, NAME, string(sym2name(S) ? "<S>")>;
	//g += <id, IS, NT_SYM>;
	return <g, symTable>;
}

public default tuple[Graph,SymTable] symToGraph(Symbol s, Id id, Graph g, SymTable symTable) {
	g += <id, CONFORMS_TO, SYMBOL>;
	g += <id, NAME, string(sym2name(s) ? "<s>")>;
	//g += <id, IS, NT_SYM>;
	return <g, symTable>;
}

public tuple[Id,SymTable] symToId(Symbol s, Id id, SymTable symTable) {
	if(s in symTable) {
		return <symTable[s], symTable>;
	}
	else if(sym2name(s)?) {
		id = ident(sym2name(s));
	}
	
	symTable[s] = id;
	return <id, symTable>;
}

public map[Production, loc] findGrammarLocs(Grammar g) {
	map[Production, loc] result = ();
	top-down visit(g) {
		case p:prod(def, syms, attrs): {
			if(p@\loc?)
				result[p] = p@\loc;
		}	
	}
	return result;
}

str sym2name(Symbol sym) {
        switch (sym) {
        case \label(_, s): return sym2name(s);
        case \sort(str s): return "cf-<s>";
        case \lex(str s): return "lex-<s>";
        case \layouts(str s): return "layout-<s>";
        case \keywords(str s): return "kw-<s>";
        case \empty(): return "empty";
        case \opt(s): return "optional-<sym2name(s)>";
        case \iter(s): return "one-or-more-<sym2name(s)>";
        case \iter-star(s): return "zero-or-more-<sym2name(s)>";
        case \iter-seps(s, [by]): return "one-or-more-<sym2name(s)>-sep-by-<sym2name(by)>";
        case \iter-star-seps(s, [by]): return "zero-or-more-<sym2name(s)>-sep-by-<sym2name(by)>";
//        case \parameterized-sort(str s, [sort(str z)]): return "<s><z>";
//        case \iter(\parameterized-sort(str s, [sort(str z)])): return "<s><z>List";
//        case \iter-star(\parameterized-sort(str s, [sort(str z)])): return "<s><z>List";
//        case \iter-seps(\parameterized-sort(str s, [sort(str z)]), _): return "<s><z>List";
//        case \iter-star-seps(\parameterized-sort(str s, [sort(str z)]), _): return "<s><z>List";
   }
   throw "Unexpected symbol <sym>";
}

public str prodToStr(prod(s,as,_)) = "<printSymbol(s, true)> = <intercalate(", ", [printSymbol(a, true) | a <- as])>;";
public str prodToStr(regular(s)) = "<printSymbol(s, true)>";
