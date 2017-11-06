module ParseTrees
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

syntax Expr 
	= "(" Expr ")"
	| Expr a "+" Expr b
//	| left (Expr "*" Expr | Expr "/" Expr)
	| left (Expr a ":")* 
	| Var
	| Num
	;

lexical Var = [a-zA-Z\u51f0]+;

lexical Num = [0-9]+;

layout LAYOUT = [\ \n\r\f\t]*;

anno loc Expr@\loc;


Id nextId(ident(old), int childNum) = ident("<old>.<childNum>");
Id nextId(ident(parent, old), int childNum) = ident(parent, "<old>.<childNum>");

public Graph metaParseTree = newGraph("metaParseTree");
public Id PRODUCTION_STRING = newId(metaParseTree, "productionString");
public Id PRODUCTION_LOC = newId(metaParseTree, "productionLoc");
public Id APPL = newId(metaParseTree, "appl");
public Id SOURCE = newId(metaParseTree, "source");
public Id STRING_VALUE = newId(metaParseTree, "stringValue");
public Id AMB = newId(metaParseTree, "amb");
public Id ALTERNATIVE = newId(metaParseTree, "alternative");
public Id CHAR = newId(metaParseTree, "char");
public Id CHAR_CODE = newId(metaParseTree, "charCode");
public Id CHAR_SYMBOL = newId(metaParseTree, "charSymbol");
public Id ROOT = newId(metaParseTree, "root");

public Graph ptToGraph(Tree t, str name) {
	Graph g = newGraph(name);
	g += <this(), ROOT, ident("0")>;
	return ptToGraph(t, ident("0"), g);
}
public Graph ptToGraph(tree:appl(p, args), Id id, Graph g) {
	g += <id, CONFORMS_TO, APPL>;
	g += <id, PRODUCTION_STRING, string(prodToStr(p))>;

	prodNoLayouts = innermost visit(p) { case [*Symbol as1,\layouts(_),*Symbol as2] => [*as1,*as2] };
	
	if(prodNoLayouts in grammarLocs) {
		g += <id, PRODUCTION_LOC,  uri(grammarLocs[prodNoLayouts])>;
	}
	else {
		println("no location found for <prodToStr(prodNoLayouts)>: <prodNoLayouts>");
	}
	if(tree@\loc?) {
		g += <id, SOURCE, uri(tree@\loc)>;
	}
	
	if(prod(lit(_),_,_) := p 
	   || prod(lex(_),_,_) := p) {
		g += <id, STRING_VALUE, string(unparse(tree))>;
 	}
	int layoutCount = 0;
	for(i <- index(args)) {
		child = nextId(id, i);
		subTree = args[i];
		g += <id, ordinal("child", i), child>;
		if(appl(prod(layouts(_),_,_),_) := subTree) {
			g += <id, ordinal("layout", layoutCount), child>;
			layoutCount = layoutCount + 1;
		}
		else {
			g += <id, ordinal("subtree", i-layoutCount), child>;
		}
		g = ptToGraph(subTree, child, g);
	}

	return g;
}

public Graph ptToGraph(amb(args), Id id, Graph g) {
	g += <id, CONFORMS_TO, AMB>;

	int i = 0;
	for(a <- args) {
		child = nextId(id, i);
		g += <id, ALTERNATIVE, child>;
		g = ptToGraph(a, child, g);
		i = i + 1;
	}
	
	return g;
}

public Graph ptToGraph(char(c), Id id, Graph g) {
	g += <id, CONFORMS_TO, CHAR>;
	g += <id, CHAR_CODE, character(c)>;
	g += <id, STRING_VALUE, string(stringChar(c))>;

	return g;
}

public default Graph ptToGraph(Tree tree, Id id, Graph g) {
	throw "ptToGraph: don\'t know what to do with <tree>";
}

public str prodToStr(prod(s,as,_)) = "<printSymbol(s, true)> = <intercalate(", ", [printSymbol(a, true) | a <- as])>;";
public str prodToStr(regular(s)) = "<printSymbol(s, true)>";
 