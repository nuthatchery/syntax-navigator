/**
 * 
 */

function graphStyle() {
	var _obj = this;
	this.layoutEdges = [];
	this.edgeFilter = function(edge) {
		return _obj.layoutEdges.indexOf(edge.data('label')) >= 0;
	};
	this.constraintEdges = [];
	this.constraintEdgeFilter = function(edge) {
		return _obj.constraintEdges.indexOf(edge.data('label')) >= 0;
	};
	this.style = [];

}

var graphStyles = {
	'/metaGrammar/grammar' : new graphStyle(),
	'/metaParseTree/parseTree' : new graphStyle(),
	'default' : new graphStyle(),
};

graphStyles['/metaGrammar/grammar'].layoutEdges = [ '/metaGrammar/bindsTo',
		'/metaGrammar/element', '/metaGrammar/separateBy'];//, '/metaGrammar/next' ];
graphStyles['/metaGrammar/grammar'].constraintEdges = [ '/metaGrammar/bindsTo',
		'/metaGrammar/element' ];
graphStyles['/metaGrammar/grammar'].moreConstraints = function() {
	return makeTreeConstraints(cy.collection(), cy.nodes(
			'.\\/metaGrammar\\/production').toArray(), function(edge) {
		return edge.data('label') == '/metaGrammar/next';
	}, 'y', 20);
}
graphStyles['/metaGrammar/grammar'].style = [ {
	selector : '[label="/metaGrammar/next"]',
	style : {
		'line-color' : '#88d',
		'target-arrow-color' : '#88d',
		'mid-target-arrow-color' : '#88d',
		'text-outline-color' : '#ccf',
		'width' : 3.5,
		'opacity' : 0.7,
		'z-index' : 150,
	}
}, {
	selector : '[label="/metaGrammar/refersTo"]',
	style : {
		'line-color' : '#7a7',
		'target-arrow-color' : '#7a7',
		'mid-target-arrow-color' : '#7a7',
		'text-outline-color' : '#aca',
		'opacity' : 0.7,
		'width' : 3.5,
		'z-index' : 110,
		'line-style' : 'dashed'
	}
}, {
	selector : '[label="/metaGrammar/element"],[label="/metaGrammar/bindsTo"]',
	style : {
		'line-color' : '#3a3',
		'target-arrow-color' : '#3a3',
		'mid-target-arrow-color' : '#3a3',
		'text-outline-color' : '#aca',
		'width' : 7,
		'z-index' : 150,
	}
}, {
	selector : '.\\/metaGrammar\\/symbol',
	style : {
		'shape' : 'triangle'
	}
}, {
	selector : '.\\/metaGrammar\\/production',
	style : {
		'shape' : 'rhomboid'
	}
},
{
	selector : '.\\/metaGrammar\\/stop',
	style : {
		'shape' : 'octagon',
		'label' : '',
		'border-width' : 3.0,
		'background-color' : '#fff',
		'border-color' : '#f00',
		'width' : 15.0,
		'height' : 15.0,
		'opacity' : 0.3,
		'display': 'none',
	}
}, 
];

graphStyles['/metaParseTree/parseTree'].layoutEdges = [
		'/metaParseTree/subTree', '/metaParseTree/root' ];
graphStyles['/metaParseTree/parseTree'].constraintEdges = [
		'/metaParseTree/subTree', '/metaParseTree/root' ];
graphStyles['/metaParseTree/parseTree'].style = [
		{
			selector : '[label="/metaParseTree/subTree"],[label="/metaParseTree/root"]',
			style : {
				'line-color' : '#88d',
				'target-arrow-color' : '#88d',
				'mid-target-arrow-color' : '#88d',
				'text-outline-color' : '#ccf',
				'width' : 3.5,
				'opacity' : 0.7,
				'z-index' : 150,
			}
		},
		{
			selector : '[label="/metaParseTree/layout"],[label="/metaParseTree/child"]',
			style : {
				'line-color' : '#7a7',
				'target-arrow-color' : '#7a7',
				'mid-target-arrow-color' : '#7a7',
				'text-outline-color' : '#aca',
				'opacity' : 0.7,
				'width' : 3.5,
				'z-index' : 110,
				'line-style' : 'dashed',
				'display' : 'none',
			}
		}, {
			selector : '[label="/metaParseTree/subTree"]',
			style : {
				'line-color' : '#3a3',
				'target-arrow-color' : '#3a3',
				'mid-target-arrow-color' : '#3a3',
				'text-outline-color' : '#aca',
				'width' : 7,
				'z-index' : 150,
			}
		}, {
			selector : '.\\/metaParseTree\\/appl',
			style : {
				'shape' : 'triangle'
			}
		}, {
			selector : '.\\/metaParseTree\\/char',
			style : {
				'shape' : 'square'
			}
		}, {
			selector : '.nodeType_\\/metaParseTree\\/layout',
			style : {
				'display' : 'none'
			}
		}, {
			selector : '.nodeType_\\/metaParseTree\\/lex',
			style : {
				'font-family' : 'monospace'
			}
		}, {
			selector : '.nodeType_\\/metaParseTree\\/keyword',
			style : {
				'font-family' : 'monospace',
				'font-weight' : 'bold'
			}
		}, ];
