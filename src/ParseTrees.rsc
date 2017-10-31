module ParseTrees
import List;
import ParseTree;
import String;
import Grammar;
import util::Reflective;
import lang::rascal::grammar::definition::Modules;
import lang::rascal::\syntax::Rascal;
import Productions;
import IO;

syntax Expr 
	= "(" Expr ")"
	| Expr a "+" Expr b
//	| left (Expr "*" Expr | Expr "/" Expr)
	| left (Expr a ":")* 
	| Var
	| Num
	;

lexical Var = [a-zA-Z]+;

lexical Num = [0-9]+;

layout LAYOUT = [\ \n\r\f\t]*;

anno loc Expr@\loc;
anno loc Production@\loc;

public set[SyntaxDefinition] syntaxDefs = getModuleSyntaxDefinitions(parseModule(|project://syntax-navigator/src/ParseTrees.rsc|));
public Grammar g = Productions::syntax2grammar(syntaxDefs);
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
public map[Production, loc] grammarLocs = findGrammarLocs(g);
alias NodeId = str;

NodeId nextId(NodeId old, int childNum) = "<old><childNum>/";

NodeId childEdgeId(int childNum) = "CHILD_<childNum>";


alias DB = rel[NodeId,NodeId,NodeId];

public DB ptToGraph(tree:appl(prod, args), NodeId id, DB g) {
	g += <id, "CONFORMS_TO", "APPL">;
	g += <id, "PRODUCTION", prodToStr(prod)>;
	
	prodNoLayouts = innermost visit(prod) { case [*as,\layouts(_),*bs] => [*as,*bs] };
	
	if(prodNoLayouts in grammarLocs) {
		g += <id, "PRODUCTION_LOC", "location::<grammarLocs[prodNoLayouts]>">;
	}
	else {
		println("no location found for <prodToStr(prodNoLayouts)>: <prodNoLayouts>");
	}
	if(tree@\loc?) {
		g += <id, "SOURCE", "location::<tree@\loc>">;
	}
	
	if(prod(lit(_),_,_) := prod 
	   || prod(lex(_),_,_) := prod) {
		g += <id, "STRING_VALUE", "String::<unparse(tree)>">;
 	}
	int layoutCount = 0;
	for(i <- index(args)) {
		child = nextId(id, i);
		subTree = args[i];
		g += <id, childEdgeId(i), child>;
		if(appl(prod(layouts(_),_,_),_) := subTree) {
			g += <id, "LAYOUT_<childEdgeId(i-layoutCount)>", child>;
			layoutCount = layoutCount + 1;
		}
		else {
			g += <id, "SYM_<childEdgeId(layoutCount)>", child>;
		}
		g = ptToGraph(subTree, child, g);
	}

	return g;
}

public DB ptToGraph(amb(prod, args), NodeId id, DB g) {
	g += <id, "CONFORMS_TO", "AMB">;

	int i = 0;
	for(a <- args) {
		child = nextId(id, i);
		g += <id, "ALTERNATIVE", child>;
		g = ptToGraph(a, child, g);
		i = i + 1;
	}
	
	return g;
}

public DB ptToGraph(char(c), NodeId id, DB g) {
	g += <id, "CONFORMS_TO", "CHAR">;
	g += <id, "CHAR_CODE", "Integer::<c>">;
	g += <id, "CHAR_SYMBOL", "String::<stringChar(c)>">;

	return g;
}

public default DB ptToGraph(Tree tree, NodeId id, DB g) {
	throw "ptToGraph: don\'t know what to do with <tree>";
}

public str prodToStr(prod(s,as,_)) = "<printSymbol(s, true)> = <intercalate(", ", [printSymbol(a, true) | a <- as])>;";
public str prodToStr(regular(s)) = "<printSymbol(s, true)>";
 