%{
#include <stdio.h>
#include <stdlib.h>
#include "2005077_SymbolTable.h"

void yyerror(char *s){
	
}

void changeState();
int yylex(void);


int error_count = 0;
int warning_count = 0;

// Files
FILE* logout;
FILE* parseTree;
FILE* errorout;
extern FILE* yyin;

// For keeping track of all the variables
SymbolTable *symbolTable;
LinkedList vars;

void printParseTree(SymbolInfo *root, int level){
	if(root == NULL){
		return;
	}
	for(int i = 0; i < level; i++){
		fprintf(parseTree, "  ");
	}
	fprintf(parseTree, "%s : %s", root->leftPart.c_str(), root->rightPart.c_str());
	if(root->isLeaf){
		fprintf(parseTree, "\t<Line: %d>\n", root->startLine);
	}
	else{
		fprintf(parseTree, "\t<Line: %d-%d>\n", root->startLine, root->endLine);
	}
	SymbolInfo *tmp = root->children;
	while(tmp != NULL){
		printParseTree(tmp, level + 1);
		tmp = tmp->next;
	}
}

%}

%union {
    SymbolInfo *symbol;
}

%token <symbol> INT, FLOAT, VOID, SEMICOLON, COMMA, ID, LSQUARE, CONST_INT, RSQUARE
%type <symbol> start program unit var_declaration type_specifier declaration_list
%%
start : program
	  {
		SymbolInfo *tmp = new SymbolInfo("start", "start");
		tmp->leftPart = "start";
		tmp->rightPart = "program";
		tmp->startLine = $1->startLine;
		tmp->endLine = $1->endLine;
		tmp->children = $1;
		$$ = tmp;
		fprintf(logout, "start : program\n");
		printParseTree($$, 0);
	  }
      ;
program : program unit 
		{
			SymbolInfo *tmp = new SymbolInfo("program", "program");
			tmp->leftPart = "program";
			tmp->rightPart = "program unit";
			tmp->startLine = $1->startLine;
			tmp->endLine = $2->endLine;
			$$ = tmp;

			$1->next = $2;
			$2->next = NULL;
			$$->children = $1;
			fprintf(logout, "program : program unit\n");
		}
		|
		unit
		{
			SymbolInfo *tmp = new SymbolInfo("program", "program");
			tmp->leftPart = "program";
			tmp->rightPart = "unit";
			tmp->startLine = $1->startLine;
			tmp->endLine = $1->endLine;
			tmp->children = $1;
			$$ = tmp;
			fprintf(logout, "program : unit\n");
		}
        ;
unit : var_declaration
			 {
				SymbolInfo *tmp = new SymbolInfo("unit", "unit");
				tmp->leftPart = "unit";
				tmp->rightPart = "var_declaration";
				tmp->startLine = $1->startLine;
				tmp->endLine = $1->endLine;
				tmp->children = $1;
				$$ = tmp;
				fprintf(logout, "unit : var_declaration\n");
			 }
        	 ;
var_declaration : type_specifier declaration_list SEMICOLON
				{
					SymbolInfo *tmp = new SymbolInfo("var_declaration", "var_declaration");
					tmp->leftPart = "var_declaration";
					tmp->rightPart = "type_specifier declaration_list SEMICOLON";
					tmp->startLine = $1->startLine;
					tmp->endLine = $3->endLine;
					$$ = tmp;

					$1->next = $2;
					$2->next = $3;
					$3->next = NULL;
					$$->children = $1;

					fprintf(logout, "var_declaration : type_specifier declaration_list SEMICOLON\n");

					if($1->getName() == "VOID"){
						error_count++;
						string tempName = vars.head->getName();
						fprintf(errorout, "Line %d: Variable or field \'%s\' declared void \n", $1->startLine, tempName.c_str());
					} else {
						SymbolInfo *cur = vars.head;
						while(cur != NULL){
							if(cur->getFlag() == 0){
								bool inserted = symbolTable->insert(cur->getName(), $1->getName(), 0);
								if(!inserted){
									error_count++;
									SymbolInfo *tmp1 = symbolTable->lookUp(cur->getName());
									if(tmp1->getType() != $1->getName()){
										fprintf(errorout, "Line# %d: Conflicting types for \'%s\'\n", $1->startLine, cur->getName().c_str());
									}
									else{
										fprintf(errorout, "Line# %d: Multiple declaration of %s\n", $1->startLine, cur->getName().c_str());
									}
								}
							}
							else if(cur->getFlag() == 1){
								bool inserted = symbolTable->insert(cur->getName(), $1->getName(), 1, cur);
								if(!inserted){
									error_count++;
									SymbolInfo *tmp1 = symbolTable->lookUp(cur->getName());
									if(tmp1->getType() != $1->getName()){
										fprintf(errorout, "Line# %d: Conflicting types for \'%s\'\n", $1->startLine, cur->getName().c_str());
									}
									else{
										fprintf(errorout, "Line# %d: Multiple declaration of %s\n", $1->startLine, cur->getName().c_str());
									}
								}
							}
							cur = cur->next;
						}
					}
					vars.clear();
					symbolTable->printAllScopeTableInFile(logout);
				}
        		;
type_specifier : INT
				{
					SymbolInfo *tmp = new SymbolInfo("INT", "type_specifier");
    				tmp->leftPart = "type_specifier";
					tmp->rightPart = "INT";
					tmp->startLine = yylval.symbol->startLine;
					tmp->endLine = yylval.symbol->endLine;
					tmp->children = yylval.symbol;
					$$ = tmp;
					fprintf(logout, "type_specifier: INT\n");
				}
                | FLOAT
				{
					SymbolInfo *tmp = new SymbolInfo("FLOAT", "type_specifier");
    				tmp->leftPart = "type_specifier";
					tmp->rightPart = "FLOAT";
					tmp->startLine = yylval.symbol->startLine;
					tmp->endLine = yylval.symbol->endLine;
					tmp->children = yylval.symbol;
					$$ = tmp;
					fprintf(logout, "type_specifier: FLOAT\n");
				}
                | VOID
				{
					SymbolInfo *tmp = new SymbolInfo("VOID", "type_specifier");
    				tmp->leftPart = "type_specifier";
					tmp->rightPart = "VOID";
					tmp->startLine = yylval.symbol->startLine;
					tmp->endLine = yylval.symbol->endLine;
					tmp->children = yylval.symbol;
					$$ = tmp;
					fprintf(logout, "type_specifier: VOID\n");
				}
                ;
declaration_list : declaration_list COMMA ID
				 {
					SymbolInfo *tmp = new SymbolInfo("ID", "declaration_list");
    				tmp->leftPart = "declaration_list";
					tmp->rightPart = "declaration_list COMMA ID";
					tmp->startLine = $1->startLine;
					tmp->endLine = $3->endLine;
					$$ = tmp;

					$1->next = $2;
					$2->next = $3;
					$3->next = NULL;
					$$->children = $1;

					vars.insert(SymbolInfo::getVariableSymbol($3->getName(), $3->getType()));
					fprintf(logout, "declaration_list : declaration_list COMMA ID\n");
				 }
                 | declaration_list COMMA ID LSQUARE CONST_INT RSQUARE
				 {
					SymbolInfo *tmp = new SymbolInfo("declaration_list", "declaration_list");
    				tmp->leftPart = "declaration_list";
					tmp->rightPart = "declaration_list COMMA ID LSQUARE CONST_INT RSQUARE";
					tmp->startLine = $1->startLine;
					tmp->endLine = $6->endLine;
					$$ = tmp;

					$1->next = $2;
					$2->next = $3;
					$3->next = $4;
					$4->next = $5;
					$5->next = $6;
					$6->next = NULL;
					$$->children = $1;

					vars.insert(SymbolInfo::getArrayTypeSymbol($3->getName(), $3->getType(), stoi($5->getName())));
					fprintf(logout, "declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE\n");
				 }
                 | ID
				 {
					SymbolInfo *tmp = new SymbolInfo("ID", "declaration_list");
					tmp->children = $1;
    				tmp->leftPart = "declaration_list";
					tmp->rightPart = "ID";
					tmp->startLine = $1->startLine;
					tmp->endLine = $1->endLine;
					$$ = tmp;
					vars.insert(SymbolInfo::getVariableSymbol($1->getName(), $1->getType()));
					fprintf(logout, "declaration_list : ID\n");
				 }
                 | ID LSQUARE CONST_INT RSQUARE
				 {
					SymbolInfo *tmp = new SymbolInfo("declaration_list", "declaration_list");
    				tmp->leftPart = "declaration_list";
					tmp->rightPart = "ID LSQUARE CONST_INT RSQUARE";
					tmp->startLine = $1->startLine;
					tmp->endLine = $4->endLine;
					$$ = tmp;
					$1->next = $2;
					$2->next = $3;
					$3->next = $4;
					$4->next = NULL;
					$$->children = $1;
					vars.insert(SymbolInfo::getArrayTypeSymbol($1->getName(), $1->getType(), stoi($3->getName())));
					fprintf(logout, "declaration_list : ID LSQUARE CONST_INT RSQUARE\n");
				 }
                 ;
%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("./output/2005077_log.txt","w");
	parseTree= fopen("./output/2005077_parseTree.txt","w");
	errorout= fopen("./output/2005077_error.txt","w");
	symbolTable = new SymbolTable(11);
	/* tokenout= fopen("2005077_token.txt","w"); */

    /* BEGIN(INDENT); */
	changeState();

	yyin= fin;
	yyparse();
	/* yylex(); */

    /* symbolTable.printAllScopeTableInFile(logout); */
    /* Total lines: 16
Total errors: 14
Total warnings: 0 */
    /* fprintf(logout, "Total lines: %d\n", line_count); */
    /* fprintf(logout, "Total errors: %d\n", error_count); */
    /* fprintf(logout, "Total warnings: %d\n", warning_count); */
	fclose(yyin);
	fclose(logout);
	fclose(parseTree);
	delete symbolTable;
	return 0;
}
