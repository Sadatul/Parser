%{
#include <stdio.h>
#include <stdlib.h>
#include "2005077_SymbolTable.h"


void changeState();
int yylex(void);

int line_count=1;
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
LinkedList params;

void yyerror(char *s){
	error_count++;
	fprintf(errorout, "Line# %d: %s\n", line_count, s);	
}

void addFunction(string name, string type, bool isDefined){
	SymbolInfo *tmp2 = new SymbolInfo(name, type, 2);
	tmp2->isDefined = isDefined;
	SymbolInfo *cur = params.head;
	while(cur != NULL){
		tmp2->params->insert(SymbolInfo::getVariableSymbol(cur->getName(), cur->getType()));
		cur = cur->next;
	}
	symbolTable->insert(tmp2);
}

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

void freeParseTree(SymbolInfo *root){
	if(root == NULL){
		return;
	}
	SymbolInfo *tmp = root->children;
	while(tmp != NULL){
		freeParseTree(tmp);
		tmp = tmp->next;
	}
	delete root;
}

%}

%union {
    SymbolInfo *symbol;
}

%token <symbol> INT, FLOAT, VOID, SEMICOLON, COMMA, ID, LSQUARE, CONST_INT, RSQUARE, LPAREN, RPAREN, LCURL, RCURL
%type <symbol> start program unit var_declaration type_specifier declaration_list func_declaration func_definition parameter_list compound_statement statements statement

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
		freeParseTree($$);
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
	 |
	 func_declaration
	 {
		SymbolInfo *tmp = new SymbolInfo("unit", "unit");
		tmp->leftPart = "unit";
		tmp->rightPart = "func_declaration";
		tmp->startLine = $1->startLine;
		tmp->endLine = $1->endLine;
		tmp->children = $1;
		$$ = tmp;
		fprintf(logout, "unit : func_declaration\n");
	 }
	 |
	 func_definition
	 {
		SymbolInfo *tmp = new SymbolInfo("unit", "unit");
		tmp->leftPart = "unit";
		tmp->rightPart = "func_definition";
		tmp->startLine = $1->startLine;
		tmp->endLine = $1->endLine;
		tmp->children = $1;
		$$ = tmp;
		fprintf(logout, "unit : func_definition\n");
	 }
	 ;

func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
				 {
					SymbolInfo *tmp = new SymbolInfo("func_declaration", "func_declaration");
					tmp->leftPart = "func_declaration";
					tmp->rightPart = "type_specifier ID LPAREN parameter_list RPAREN SEMICOLON";
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
					fprintf(logout, "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n");

					SymbolInfo *tmp1 = symbolTable->lookUp($2->getName());
					if(tmp1 != NULL){
						if(tmp1->getFlag() != 2){
							error_count++;
							fprintf(errorout, "Line# %d: Redeclared as different kind of symbol %s\n", $1->startLine, $2->getName().c_str());
						}
						else{
							error_count++;
							fprintf(errorout, "Line# %d: Multiple Declaration of function \'%s\'\n", $1->startLine, $2->getName().c_str());
						}
					}
					else {
						SymbolInfo *tmp2 = new SymbolInfo($2->getName(), $1->getName(), 2);
						tmp2->isDefined = false;
						SymbolInfo *cur = params.head;
						while(cur != NULL){
							tmp2->params->insert(SymbolInfo::getVariableSymbol(cur->getName(), cur->getType()));
							cur = cur->next;
						}
						symbolTable->insert(tmp2);
					}
					params.clear();
					symbolTable->printAllScopeTableInFile(logout);
				 }
				 |
				 type_specifier ID LPAREN RPAREN SEMICOLON
				 {
					SymbolInfo *tmp = new SymbolInfo("func_declaration", "func_declaration");
					tmp->leftPart = "func_declaration";
					tmp->rightPart = "type_specifier ID LPAREN RPAREN SEMICOLON";
					tmp->startLine = $1->startLine;
					tmp->endLine = $5->endLine;
					$$ = tmp;

					$1->next = $2;
					$2->next = $3;
					$3->next = $4;
					$4->next = $5;
					$5->next = NULL;
					$$->children = $1;
					fprintf(logout, "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n");

					SymbolInfo *tmp1 = symbolTable->lookUp($2->getName());
					if(tmp1 != NULL){
						if(tmp1->getFlag() != 2){
							error_count++;
							fprintf(errorout, "Line# %d: Redeclared as different kind of symbol %s\n", $1->startLine, $2->getName().c_str());
						}
						else{
							error_count++;
							fprintf(errorout, "Line# %d: Multiple Declaration of function \'%s\'\n", $1->startLine, $2->getName().c_str());
						}
					}
					else {
						SymbolInfo *tmp2 = new SymbolInfo($2->getName(), $1->getName(), 2);
						tmp2->isDefined = false;
						symbolTable->insert(tmp2);
					}
					symbolTable->printAllScopeTableInFile(logout);
				 }
				 ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN 
				{
					string name = $2->getName();
					string type = $1->getName();
					
					SymbolInfo *func = symbolTable->lookUp(name);
					if(func == NULL){
						addFunction(name, type, true);
					}
					else if(func->getFlag() == 2){
						if(func->isDefined){
							error_count++;
							fprintf(errorout, "Line# %d: Redifination of function \'%s\'\n", $1->startLine, name.c_str());
						}
						else {
							// so function is declared but not defined
							// Now we will check all the if the return type and parameters are the same.
							if(func->getType() == type){
								if(func->params->getLength() == params.getLength())
								{
									// Paramcount matched
									bool errorFlag = false;

									SymbolInfo *funcCur = func->params->head;
									SymbolInfo *paramCur = params.head;
									while(funcCur != NULL){
										if(funcCur->getType() != paramCur->getType()){
											errorFlag = true;
											break;
										}
										funcCur = funcCur->next;
										paramCur = paramCur->next;
									}
									
									if(errorFlag){
										error_count++;
										fprintf(errorout, "Line# %d: Conflicting(ParamType) types for \'%s\'\n", $1->startLine, name.c_str());
									}
									else {
										func->isDefined = true;
										// Changed the function parameters names.
										SymbolInfo *funcCur = func->params->head;
										SymbolInfo *paramCur = params.head;
										while(funcCur != NULL){
											funcCur->setName(paramCur->getName());
											funcCur = funcCur->next;
											paramCur = paramCur->next;
										}
										
									}
								}
								else {
									error_count++;
									fprintf(errorout, "Line# %d: Conflicting(ParamCount) types for \'%s\'\n", $1->startLine, name.c_str());
								}
							}
							else {
								error_count++;
								// Return value doesn't match with already declared function.
								fprintf(errorout, "Line# %d: Conflicting types for \'%s\'\n", $1->startLine, name.c_str());
							}
						}
					}
					else {
						error_count++;
						fprintf(errorout, "Line# %d: \'%s\' redeclared as different kind of symbol\n", $1->startLine, name.c_str());
					}
				}
				compound_statement
				{
					SymbolInfo *tmp = new SymbolInfo("func_definition", "func_definition");
					tmp->leftPart = "func_definition";
					tmp->rightPart = "type_specifier ID LPAREN parameter_list RPAREN compound_statement";
					tmp->startLine = $1->startLine;
					tmp->endLine = $7->endLine;
					$$ = tmp;

					$1->next = $2;
					$2->next = $3;
					$3->next = $4;
					$4->next = $5;
					$5->next = $7;
					$7->next = NULL;
					$$->children = $1;
					fprintf(logout, "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n");
				}
				|
				type_specifier ID LPAREN RPAREN
				{
					string name = $2->getName();
					string type = $1->getName();
					
					SymbolInfo *func = symbolTable->lookUp(name);
					if(func == NULL){
						addFunction(name, type, true);
					}
					else if(func->getFlag() == 2){
						if(func->isDefined){
							error_count++;
							fprintf(errorout, "Line# %d: Redifination of function \'%s\'\n", $1->startLine, name.c_str());
						}
						else {
							// so function is declared but not defined
							// Now we will check all the if the return type and parameters are the same.
							if(func->getType() != type){
								error_count++;
								// Return value doesn't match with already declared function.
								fprintf(errorout, "Line# %d: Conflicting types for \'%s\'\n", $1->startLine, name.c_str());
							}
							else if(func->params->getLength() != params.getLength() && params.getLength() == 0)
							{	
								error_count++;
								fprintf(errorout, "Line# %d: Conflicting(ParamCount) types for \'%s\'\n", $1->startLine, name.c_str());
							}
							else {
								func->isDefined = true;
							}
						}
					}
					else {
						error_count++;
						fprintf(errorout, "Line# %d: \'%s\' redeclared as different kind of symbol\n", $1->startLine, name.c_str());
					}
				}
				compound_statement
				{
					SymbolInfo *tmp = new SymbolInfo("func_definition", "func_definition");
					tmp->leftPart = "func_definition";
					tmp->rightPart = "type_specifier ID LPAREN RPAREN compound_statement";
					tmp->startLine = $1->startLine;
					tmp->endLine = $6->endLine;
					$$ = tmp;

					$1->next = $2;
					$2->next = $3;
					$3->next = $4;
					$4->next = $6;
					$6->next = NULL;
					$$->children = $1;
					fprintf(logout, "func_definition : type_specifier ID LPAREN RPAREN compound_statement\n");
				}
				;
parameter_list : parameter_list COMMA type_specifier ID
				{
					SymbolInfo *tmp = new SymbolInfo("parameter_list", "parameter_list");
    				tmp->leftPart = "parameter_list";
					tmp->rightPart = "parameter_list COMMA type_specifier ID";
					tmp->startLine = $1->startLine;
					tmp->endLine = $4->endLine;
					$$ = tmp;

					$1->next = $2;
					$2->next = $3;
					$3->next = $4;
					$4->next = NULL;
					$$->children = $1;

					SymbolInfo *cur = params.head;
					bool errorFlag = false;
					while(cur != NULL){
						if(cur->getName() == $4->getName()){
							errorFlag = true;
							break;
						}
						cur = cur->next;
					}
					if(errorFlag){
						error_count++;
						fprintf(errorout, "Line# %d: Multiple declaration of %s\n", $4->startLine, $4->getName().c_str());
						
					} else {
						params.insert(SymbolInfo::getVariableSymbol($4->getName(), $3->getName()));
					}
					fprintf(logout, "parameter_list : parameter_list COMMA type_specifier ID\n");
				}
				|
				parameter_list COMMA type_specifier
				{
					SymbolInfo *tmp = new SymbolInfo("parameter_list", "parameter_list");
    				tmp->leftPart = "parameter_list";
					tmp->rightPart = "parameter_list COMMA type_specifier";
					tmp->startLine = $1->startLine;
					tmp->endLine = $3->endLine;
					$$ = tmp;

					$1->next = $2;
					$2->next = $3;
					$3->next = NULL;
					$$->children = $1;

					params.insert(SymbolInfo::getVariableSymbol("", $3->getName()));
					fprintf(logout, "parameter_list : parameter_list COMMA type_specifier\n");
				}
				|
				type_specifier ID
				{
					SymbolInfo *tmp = new SymbolInfo("parameter_list", "parameter_list");
    				tmp->leftPart = "parameter_list";
					tmp->rightPart = "type_specifier ID";
					tmp->startLine = $1->startLine;
					tmp->endLine = $2->endLine;
					$$ = tmp;

					$1->next = $2;
					$2->next = NULL;
					$$->children = $1;

					params.insert(SymbolInfo::getVariableSymbol($2->getName(), $1->getName()));
					fprintf(logout, "parameter_list : type_specifier ID\n");
				}
				|
				type_specifier
				{
					SymbolInfo *tmp = new SymbolInfo("parameter_list", "parameter_list");
    				tmp->leftPart = "parameter_list";
					tmp->rightPart = "type_specifier";
					tmp->startLine = $1->startLine;
					tmp->endLine = $1->endLine;
					$$ = tmp;

					$1->next = NULL;
					$$->children = $1;

					params.insert(SymbolInfo::getVariableSymbol("", $1->getName()));
					fprintf(logout, "parameter_list : type_specifier\n");
				}
				;
compound_statement : LCURL ENTER_SCOPE statements RCURL
				   {
						SymbolInfo *tmp = new SymbolInfo("compound_statement", "compound_statement");
						tmp->leftPart = "compound_statement";
						tmp->rightPart = "LCURL statements RCURL";
						tmp->startLine = $1->startLine;
						tmp->endLine = $4->endLine;
						$$ = tmp;

						$1->next = $3;
						$3->next = $4;
						$4->next = NULL;
						$$->children = $1;
						fprintf(logout, "compound_statement : LCURL statements RCURL\n");

						symbolTable->printAllScopeTableInFile(logout);
						symbolTable->exitScope();
				   }
				   |
				   LCURL ENTER_SCOPE RCURL
				   {
						SymbolInfo *tmp = new SymbolInfo("compound_statement", "compound_statement");
						tmp->leftPart = "compound_statement";
						tmp->rightPart = "LCURL RCURL";
						tmp->startLine = $1->startLine;
						tmp->endLine = $3->endLine;
						$$ = tmp;

						$1->next = $3;
						$3->next = NULL;
						$$->children = $1;
						fprintf(logout, "compound_statement : LCURL RCURL\n");

						symbolTable->printAllScopeTableInFile(logout);
						symbolTable->exitScope();
				   }
				   ;

ENTER_SCOPE :
			{
				symbolTable->enterScope();
				SymbolInfo *tmp = params.head;
				while(tmp != NULL){
					symbolTable->insert(tmp->getName(), tmp->getType(), 0);
					tmp = tmp->next;
				}
				params.clear();
				// printf("Cleared Params\n");
			}

statements : statement
		   {
				SymbolInfo *tmp = new SymbolInfo("statements", "statements");
				tmp->leftPart = "statements";
				tmp->rightPart = "statement";
				tmp->startLine = $1->startLine;
				tmp->endLine = $1->endLine;
				tmp->children = $1;
				$$ = tmp;
				fprintf(logout, "statements : statement\n");
		   }
		   |
		   statements statement
		   {
				SymbolInfo *tmp = new SymbolInfo("statements", "statements");
				tmp->leftPart = "statements";
				tmp->rightPart = "statements statement";
				tmp->startLine = $1->startLine;
				tmp->endLine = $2->endLine;
				$$ = tmp;

				$1->next = $2;
				$2->next = NULL;
				$$->children = $1;

				fprintf(logout, "statements statement\n");
		   }
		   ;

statement : var_declaration
		  {
			SymbolInfo *tmp = new SymbolInfo("statement", "statement");
			tmp->leftPart = "statement";
			tmp->rightPart = "var_declaration";
			tmp->startLine = $1->startLine;
			tmp->endLine = $1->endLine;
			tmp->children = $1;
			$$ = tmp;
			fprintf(logout, "statement : var_declaration\n");

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
