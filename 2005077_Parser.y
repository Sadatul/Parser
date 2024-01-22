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
LinkedList args;
string funcReturnType = ""; // This is used to keep track of the return type of the function during definition.
					// We match this in the return statement to check if the return type is correct or not.
					// Remember after end of definition we need to reset this to empty string.

// Our log file shows that functions added after definition is complete.
// But the way we coded before....addded the function to the symbolTable right after
// the declaration part before..compound statements have been checked.
// So, now to match the logfile, we keep a flag callAddfunction and based on this flag
// add the function to the symbolTable after the compound statement is checked.
string funcName = "";
bool callAddFunction = false;

bool paramErrorFlag = false; // If error occurs in a param declaration...this prevents us 
							// from adding anymore symbols to the symbol table.

void yyerror(char *s){
	error_count++;
	fprintf(logout, "Error at line no %d : %s\n", line_count, s);
	// fprintf(errorout, "Error at line no %d : %s\n", line_count, s);	
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
		fprintf(parseTree, " ");
	}
	fprintf(parseTree, "%s : %s", root->leftPart.c_str(), root->rightPart.c_str());
	if(root->isLeaf){
		fprintf(parseTree, "\t<Line: %d>\n", root->startLine);
	}
	else{
		fprintf(parseTree, " \t<Line: %d-%d>\n", root->startLine, root->endLine);
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

%token <symbol> INT FLOAT VOID SEMICOLON COMMA ID LSQUARE CONST_INT CONST_FLOAT RSQUARE LPAREN RPAREN LCURL RCURL ASSIGNOP RELOP LOGICOP ADDOP MULOP NOT INCOP DECOP RETURN FOR IF ELSE WHILE PRINTLN
%type <symbol> start program unit var_declaration type_specifier declaration_list func_declaration func_definition parameter_list compound_statement statements statement factor variable unary_expression term simple_expression rel_expression logic_expression expression expression_statement arguments argument_list

%{
	// LOWER_THAN_ELSE , a pseudo token, is used to resolve the dangling else problem.
	// LOWER_THAN_ELSE has lower precedence than ELSE as it is defined earlier.
	// %nonassoc means non associative but we are using this only to define
	// precedence...associativity is not important here.	
%}

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

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
		fprintf(logout, "start : program \n");
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
			fprintf(logout, "program : program unit \n");
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
			fprintf(logout, "program : unit \n");
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
		fprintf(logout, "unit : var_declaration  \n");
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
		fprintf(logout, "unit : func_declaration \n");
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
		fprintf(logout, "unit : func_definition  \n");
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

					if($4->error){
						fprintf(errorout, "Line# %d: Syntax error at parameter list of function declaration\n", $1->startLine);
					}

					$1->next = $2;
					$2->next = $3;
					$3->next = $4;
					$4->next = $5;
					$5->next = $6;
					$6->next = NULL;
					$$->children = $1;
					fprintf(logout, "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON \n");

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
					else if(!$4->error){
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
					// symbolTable->printAllScopeTableInFile(logout);
					paramErrorFlag = false;
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
					fprintf(logout, "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON \n");

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
					// symbolTable->printAllScopeTableInFile(logout);
				 }
				 ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN 
				{
					string name = $2->getName();
					string type = $1->getName();

					// funcReturnType is global variable used to keep
					// track of return type and match it when we 
					// encounter return statement.
					funcReturnType = type;
					funcName = name;

					// Recovering from parameter_list error
					if($4->error){
						fprintf(errorout, "Line# %d: Syntax error at parameter list of function definition\n", $1->startLine);
					}
					
					SymbolInfo *func = symbolTable->lookUp(name);
					if(func == NULL){
						// addFunction(name, type, true);
						callAddFunction = true;
					}
					else if(func->getFlag() == 2){
						callAddFunction = false;
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
										fprintf(errorout, "Line# %d: Conflicting types for \'%s\'\n", $1->startLine, name.c_str());
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
									fprintf(errorout, "Line# %d: Conflicting types for \'%s\'\n", $1->startLine, name.c_str());
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
					// Call addFunction only if there is no error in parameter_list
					if(callAddFunction && (!$4->error))
					{
						addFunction(funcName, funcReturnType, true);
					}
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
					fprintf(logout, "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement \n");

					// After finishing the definiation we reset th
					// funcReturnType to empty string.
					funcReturnType = "";

					// Need to reset our flags and params.
					callAddFunction = false;
					funcName = "";
					params.clear();
					paramErrorFlag = false;
				}
				|
				type_specifier ID LPAREN RPAREN
				{
					string name = $2->getName();
					string type = $1->getName();
					
					funcReturnType = type;
					funcName = name;

					SymbolInfo *func = symbolTable->lookUp(name);
					if(func == NULL){
						// addFunction(name, type, true);
						callAddFunction = true;
					}
					else if(func->getFlag() == 2){
						callAddFunction = false;
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
								fprintf(errorout, "Line# %d: Conflicting types for '%s\'\n", $1->startLine, name.c_str());
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
					if(callAddFunction)
					{
						addFunction(funcName, funcReturnType, true);
					}
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

					funcReturnType = "";
					callAddFunction = false;
					funcName = "";
					params.clear();
					paramErrorFlag = false;
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
						fprintf(errorout, "Line# %d: Redefinition of parameter \'%s\'\n", $4->startLine, $4->getName().c_str());
						paramErrorFlag = true;
					} else if(!paramErrorFlag){
						// We only insert a param if we are confimed no erro has occured
						// in the previous param declaration.
						params.insert(SymbolInfo::getVariableSymbol($4->getName(), $3->getName()));
					}
					fprintf(logout, "parameter_list  : parameter_list COMMA type_specifier ID\n");
				
					if($1->error){
						$$->error = true;
						$$->children = NULL;
						$$->leftPart = "parameter_list";
						$$->rightPart = "error";
						$$->isLeaf = true;

						delete $1;
						delete $2;
						delete $3;
						delete $4;
					}
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
					fprintf(logout, "parameter_list  : parameter_list COMMA type_specifier\n");
				
					if($1->error){
						$$->error = true;
						$$->children = NULL;
						$$->leftPart = "parameter_list";
						$$->rightPart = "error";
						$$->isLeaf = true;

						delete $1;
						delete $2;
						delete $3;
					}
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
					fprintf(logout, "parameter_list  : type_specifier ID\n");
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
					fprintf(logout, "parameter_list  : type_specifier \n");
				}
				|
				error
				{
					// fprintf(logout, "Line# %d: parameter_list: Syntax error1\n", line_count);
					yyclearin ;
					// fprintf(logout, "Line# %d: parameter_list: Syntax error2\n", line_count);
					SymbolInfo *tmp = new SymbolInfo("parameter_list", "parameter_list");
					tmp->leftPart = "parameter_list";
					tmp->rightPart = "error";
					tmp->startLine = line_count;
					tmp->endLine = line_count;
					tmp->isLeaf = true;
					tmp->children = NULL;

					tmp->error = true;
					
					$$ = tmp;
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
						fprintf(logout, "compound_statement : LCURL statements RCURL  \n");

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
						fprintf(logout, "compound_statement : LCURL RCURL  \n");

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
				// params.clear();
				// printf("Cleared Params\n");
			}

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

					fprintf(logout, "var_declaration : type_specifier declaration_list SEMICOLON  \n");

					if($2->error){
						fprintf(errorout, "Line# %d: Syntax error at declaration list of variable declaration\n", $1->startLine);
					}

					if($1->getName() == "VOID"){
						error_count++;
						string tempName = vars.head->getName();
						fprintf(errorout, "Line# %d: Variable or field \'%s\' declared void\n", $1->startLine, tempName.c_str());
					} else if(!$2->error){
						SymbolInfo *cur = vars.head;
						while(cur != NULL){
							if(cur->getFlag() == 0){
								bool inserted = symbolTable->insert(cur->getName(), $1->getName(), 0);
								if(!inserted){
									error_count++;
									SymbolInfo *tmp1 = symbolTable->lookUp(cur->getName());
									if(tmp1->getType() != $1->getName()){
										fprintf(errorout, "Line# %d: Conflicting types for\'%s\'\n", $1->startLine, cur->getName().c_str());
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
										fprintf(errorout, "Line# %d: Conflicting types for\'%s\'\n", $1->startLine, cur->getName().c_str());
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
					// symbolTable->printAllScopeTableInFile(logout);
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
					fprintf(logout, "type_specifier\t: INT \n");
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
					fprintf(logout, "type_specifier\t: FLOAT \n");
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
					fprintf(logout, "type_specifier\t: VOID\n");
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
					fprintf(logout, "declaration_list : declaration_list COMMA ID  \n");
				 
				 	if($1->error){
						$$->error = true;
						$$->isLeaf = true;
						$$->children = NULL;
						$$->leftPart = "declaration_list";
						$$->rightPart = "error";

						delete $1;
						delete $2;
						delete $3;
					}
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
					fprintf(logout, "declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE \n");
				 
				 	if($1->error){
						$$->error = true;
						$$->isLeaf = true;
						$$->children = NULL;
						$$->leftPart = "declaration_list";
						$$->rightPart = "error";

						delete $1;
						delete $2;
						delete $3;
						delete $4;
						delete $5;
						delete $6;
					}
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
					fprintf(logout, "declaration_list : ID \n");
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
					fprintf(logout, "declaration_list : ID LSQUARE CONST_INT RSQUARE \n");
				 }
				 |
				 error {
					SymbolInfo *tmp = new SymbolInfo("dedeclaration_list", "declaration_list");
					tmp->leftPart = "declaration_list";
					tmp->rightPart = "error";
					tmp->startLine = line_count;
					tmp->endLine = line_count;
					tmp->isLeaf = true;
					tmp->children = NULL;
					$$ = tmp;

					tmp->error = true;

					// fprintf(logout, "Line# %d: declaration_list: Syntax error\n", line_count);
					yyclearin;
				}
                 ;

statements : statement
		   {
				SymbolInfo *tmp = new SymbolInfo("statements", "statements");
				tmp->leftPart = "statements";
				tmp->rightPart = "statement";
				tmp->startLine = $1->startLine;
				tmp->endLine = $1->endLine;
				tmp->children = $1;
				$$ = tmp;
				fprintf(logout, "statements : statement  \n");
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

				fprintf(logout, "statements : statements statement  \n");
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
			fprintf(logout, "statement : var_declaration \n");

		  }
		  | expression_statement
		  {
			SymbolInfo *tmp = new SymbolInfo("statement", "statement");
			tmp->leftPart = "statement";
			tmp->rightPart = "expression_statement";
			tmp->startLine = $1->startLine;
			tmp->endLine = $1->endLine;
			tmp->children = $1;
			$$ = tmp;
			fprintf(logout, "statement : expression_statement  \n");
		  }
		  | compound_statement
		  {
			SymbolInfo *tmp = new SymbolInfo("statement", "statement");
			tmp->leftPart = "statement";
			tmp->rightPart = "compound_statement";
			tmp->startLine = $1->startLine;
			tmp->endLine = $1->endLine;
			tmp->children = $1;
			$$ = tmp;
			fprintf(logout, "statement : compound_statement \n");
		  }
		  |
		  FOR LPAREN expression_statement expression_statement expression RPAREN statement
		  {
			SymbolInfo *tmp = new SymbolInfo("statement", "statement");
			tmp->leftPart = "statement";
			tmp->rightPart = "FOR LPAREN expression_statement expression_statement expression RPAREN statement";
			tmp->startLine = $1->startLine;
			tmp->endLine = $7->endLine;

			$1->next = $2;
			$2->next = $3;
			$3->next = $4;
			$4->next = $5;
			$5->next = $6;
			$6->next = $7;
			$7->next = NULL;
			tmp->children = $1;

			$$ = tmp;
			fprintf(logout, "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement \n");
		  }
		  |
		  IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
		  {
			// %prec tells that this production has equal precedence to LOWER_THAN_ELSE
			// which is lower than ELSE, which allows us to give precedence
			// to shift operation rather than reduce.
			SymbolInfo *tmp = new SymbolInfo("statement", "statement");
			tmp->leftPart = "statement";
			tmp->rightPart = "IF LPAREN expression RPAREN statement";
			tmp->startLine = $1->startLine;
			tmp->endLine = $5->endLine;

			$1->next = $2;
			$2->next = $3;
			$3->next = $4;
			$4->next = $5;
			$5->next = NULL;

			tmp->children = $1;
			$$ = tmp;
			fprintf(logout, "statement : IF LPAREN expression RPAREN statement \n");
		  }
		  |
		  IF LPAREN expression RPAREN statement ELSE statement
		  {
			SymbolInfo *tmp = new SymbolInfo("statement", "statement");
			tmp->leftPart = "statement";
			tmp->rightPart = "IF LPAREN expression RPAREN statement ELSE statement";
			tmp->startLine = $1->startLine;
			tmp->endLine = $7->endLine;

			$1->next = $2;
			$2->next = $3;
			$3->next = $4;
			$4->next = $5;
			$5->next = $6;
			$6->next = $7;
			$7->next = NULL;

			tmp->children = $1;
			$$ = tmp;
			fprintf(logout, "statement : IF LPAREN expression RPAREN statement ELSE statement \n");
		  }
		  |
		  WHILE LPAREN expression RPAREN statement
		  {
			SymbolInfo *tmp = new SymbolInfo("statement", "statement");
			tmp->leftPart = "statement";
			tmp->rightPart = "WHILE LPAREN expression RPAREN statement";
			tmp->startLine = $1->startLine;
			tmp->endLine = $5->endLine;

			$1->next = $2;
			$2->next = $3;
			$3->next = $4;
			$4->next = $5;
			$5->next = NULL;

			tmp->children = $1;
			$$ = tmp;
			fprintf(logout, "statement : WHILE LPAREN expression RPAREN statement \n");
		  }
		  |
		  PRINTLN LPAREN ID RPAREN SEMICOLON
		  {
			SymbolInfo *tmp = new SymbolInfo("statement", "statement");
			tmp->leftPart = "statement";
			tmp->rightPart = "PRINTLN LPAREN ID RPAREN SEMICOLON";
			tmp->startLine = $1->startLine;
			tmp->endLine = $5->endLine;

			$1->next = $2;
			$2->next = $3;
			$3->next = $4;
			$4->next = $5;
			$5->next = NULL;

			tmp->children = $1;
			$$ = tmp;
			fprintf(logout, "statement : PRINTLN LPAREN ID RPAREN SEMICOLON \n");

		  	SymbolInfo *check = symbolTable->lookUp($3->getName());
			if(check == NULL){
				error_count++;
				fprintf(errorout, "Line# %d: Undeclared variable \'%s\'\n", $3->startLine, $3->getName().c_str());
			} else if(check->getFlag() == 2){
				error_count++;
				fprintf(errorout, "Line# %d: \'%s\' is a function.\n", $3->startLine, $3->getName().c_str());
			}
		  }
		  |
		  RETURN expression SEMICOLON
		  {
			SymbolInfo *tmp = new SymbolInfo("statement", "statement");
			tmp->leftPart = "statement";
			tmp->rightPart = "RETURN expression SEMICOLON";
			tmp->startLine = $1->startLine;
			tmp->endLine = $3->endLine;

			$1->next = $2;
			$2->next = $3;
			$3->next = NULL;
			tmp->children = $1;

			$$ = tmp;
			fprintf(logout, "statement : RETURN expression SEMICOLON\n");
		  
		  	// Need to do error checking here.
			// if(funcReturnType == "" || funcReturnType == "VOID"){
			// 	error_count++;
			//  	fprintf(errorout, "Line# %d: RETURN not allowed here.\n", $1->startLine);
			// }
			// else {
			//  	if(funcReturnType != $2->dType){
			//  		error_count++;
			//  		fprintf(errorout, "Line# %d: Conflicting return type for function.\n", $1->startLine);
			//  	}
			// }

		  }
		  ;

expression_statement : SEMICOLON
					 {
						SymbolInfo *tmp = new SymbolInfo("expression_statement", "expression_statement");
						tmp->leftPart = "expression_statement";
						tmp->rightPart = "SEMICOLON";
						tmp->startLine = $1->startLine;
						tmp->endLine = $1->endLine;
						tmp->children = $1;
						
						$$ = tmp;
						fprintf(logout, "expression_statement : SEMICOLON \n");
					 }
					 |
					 expression SEMICOLON
					 {
						SymbolInfo *tmp = new SymbolInfo("expression_statement", "expression_statement");
						tmp->leftPart = "expression_statement";
						tmp->rightPart = "expression SEMICOLON";
						tmp->startLine = $1->startLine;
						tmp->endLine = $2->endLine;

						$1->next = $2;
						$2->next = NULL;
						tmp->children = $1;

						$$ = tmp;
						fprintf(logout, "expression_statement : expression SEMICOLON \t\t \n");
					 	if($1->error){
							fprintf(errorout, "Line# %d: Syntax error at expression of expression statement\n", $1->startLine);
						}
					 }

variable : ID
		 {
			// variable can have 3 different dTypes -> UNDEFINED, INT, FLOAT, VOID
			// flags can be 0 -> variable, 1 -> array

			// We have created the tmp but didn't assign it to $ $ because
			// we want to make sure it exists before doing that.
			// flag and dType also need to be set before the assignment 
			SymbolInfo *tmp = new SymbolInfo($1->getName(), "variable");
			tmp->leftPart = "variable";
			tmp->rightPart = "ID";
			tmp->startLine = $1->startLine;
			tmp->endLine = $1->endLine;
			tmp->children = $1;

			tmp->isZero = false;

			fprintf(logout, "variable : ID \t \n");

			SymbolInfo *check = symbolTable->lookUp($1->getName());
			if(check == NULL){
				error_count++;
				fprintf(errorout, "Line# %d: Undeclared variable \'%s\'\n", $1->startLine, $1->getName().c_str());
				tmp->dType = "UNDEFINED";
				tmp->setFlag(0);
			}
			else {
				// Functions can't be considered variables so we are thrwoing an error.
				// When we find a function we are showing the error and then as an 
				// recovery we are actually considering it as a variable with type
				// same as the returnType of the function.
				if(check->getFlag() == 2){
					error_count++;
					fprintf(errorout, "Line# %d: \'%s\' is a function.\n", $1->startLine, $1->getName().c_str());
					tmp->dType = "UNDEFINED";
					tmp->setFlag(0);
				}
				else{
					tmp->dType = check->getType();
					tmp->setFlag(check->getFlag());
				}
			}
			$$ = tmp;

		 }
		 |
		 ID LSQUARE expression RSQUARE
		 {
			SymbolInfo *tmp = new SymbolInfo($1->getName(), "variable");
			tmp->leftPart = "variable";
			tmp->rightPart = "ID LSQUARE expression RSQUARE";
			tmp->startLine = $1->startLine;
			tmp->endLine = $4->endLine;

			$1->next = $2;
			$2->next = $3;
			$3->next = $4;
			$4->next = NULL;
			tmp->children = $1;
			
			fprintf(logout, "variable : ID LSQUARE expression RSQUARE  \t \n");

			tmp->isZero = false;

			SymbolInfo *check = symbolTable->lookUp($1->getName());
			if(check == NULL){
				error_count++;
				fprintf(errorout, "Line# %d: Undeclared variable \'%s\'\n", $1->startLine, $1->getName().c_str());
				tmp->dType = "UNDEFINED";
				tmp->setFlag(0);
			}
			else {
				tmp->dType = check->getType();
				tmp->setFlag(0); // We a[12] can be treated like an integer variable rather than an array.
				if(check->getFlag() == 1){
					if($3->dType != "INT"){
						error_count++;
						fprintf(errorout, "Line# %d: Array subscript is not an integer\n", $1->startLine);
					}
				}
				else {
					error_count++;
					fprintf(errorout, "Line# %d: \'%s\' is not an array\n", $1->startLine, $1->getName().c_str());

				}	
			}
			$$ = tmp;
		 }
		 ;

expression : logic_expression
		   {
				SymbolInfo *tmp = new SymbolInfo($1->getName(), "expression");
				
				tmp->dType = $1->dType;
				tmp->setFlag($1->getFlag());
				tmp->isZero = $1->isZero;
				
				tmp->leftPart = "expression";
				tmp->rightPart = "logic_expression";
				tmp->startLine = $1->startLine;
				tmp->endLine = $1->endLine;
				tmp->children = $1;
				$$ = tmp;
				fprintf(logout, "expression \t: logic_expression\t \n");
		   }
		   |
		   variable ASSIGNOP logic_expression
		   {
				SymbolInfo *tmp = new SymbolInfo($1->getName(), "expression");
				
				tmp->setFlag(0);
				tmp->isZero = false;
				
				tmp->leftPart = "expression";
				tmp->rightPart = "variable ASSIGNOP logic_expression";
				tmp->startLine = $1->startLine;
				tmp->endLine = $3->endLine;

				$1->next = $2;
				$2->next = $3;
				$3->next = NULL;
				tmp->children = $1;

				$$ = tmp;
				fprintf(logout, "expression \t: variable ASSIGNOP logic_expression \t\t \n");

				if($1->dType == "VOID" || $3->dType == "VOID"){
					error_count++;
					fprintf(errorout, "Line# %d: Void cannot be used in expression \n", $1->startLine);
					tmp->dType = "UNDEFINED";
				}
				else if($1->dType == "UNDEFINED" || $3->dType == "UNDEFINED"){
					tmp->dType = "UNDEFINED";
				}
				else{
					tmp->dType = $1->dType;
					if($1->dType == "INT" && $3->dType == "FLOAT")
					{
						error_count++;
						fprintf(errorout, "Line# %d: Warning: possible loss of data in assignment of FLOAT to INT\n", $1->startLine);
						
					}
				}
		   }
		   |
			error {
				yyclearin;
				SymbolInfo *tmp = new SymbolInfo("expression", "expression");
				tmp->leftPart = "expression";
				tmp->rightPart = "error";
				tmp->startLine = line_count;
				tmp->endLine = line_count;
				tmp->isLeaf = true;
				tmp->children = NULL;
				$$ = tmp;
				
				tmp->error = true;
				// fprintf(errorout, "Line# %d: Syntax error at expression of expression statement\n", line_count);
			}
		   ;

logic_expression : rel_expression
				 {
					SymbolInfo *tmp = new SymbolInfo($1->getName(), "logic_expression");
					
					tmp->dType = $1->dType;
					tmp->setFlag($1->getFlag());
					tmp->isZero = $1->isZero;

					tmp->leftPart = "logic_expression";
					tmp->rightPart = "rel_expression";
					tmp->startLine = $1->startLine;
					tmp->endLine = $1->endLine;
					tmp->children = $1;
					$$ = tmp;
					fprintf(logout, "logic_expression : rel_expression \t \n");
				 }
				 |
				 rel_expression LOGICOP rel_expression
				 {
					SymbolInfo *tmp = new SymbolInfo($1->getName(), "logic_expression");
					
					tmp->dType = "INT";
					tmp->setFlag(0);
					tmp->isZero = false;
					
					tmp->leftPart = "logic_expression";
					tmp->rightPart = "rel_expression LOGICOP rel_expression";
					tmp->startLine = $1->startLine;
					tmp->endLine = $3->endLine;

					$1->next = $2;
					$2->next = $3;
					$3->next = NULL;
					tmp->children = $1;

					$$ = tmp;
					fprintf(logout, "logic_expression : rel_expression LOGICOP rel_expression \t \t \n");

					if($1->dType == "VOID" || $3->dType == "VOID"){
						error_count++;
						fprintf(errorout, "Line# %d: Void cannot be used in expression \n", $1->startLine);
					}
					if($1->dType != "INT" || $3->dType != "INT"){
						error_count++;
						fprintf(errorout, "Line# %d: Both operands should be int\n", $1->startLine);
					}
				 }
				 ;

rel_expression : simple_expression
			   {
					SymbolInfo *tmp = new SymbolInfo($1->getName(), "rel_expression");
					
					tmp->dType = $1->dType;
					tmp->setFlag($1->getFlag());
					tmp->isZero = $1->isZero;

					tmp->leftPart = "rel_expression";
					tmp->rightPart = "simple_expression";
					tmp->startLine = $1->startLine;
					tmp->endLine = $1->endLine;
					tmp->children = $1;
					$$ = tmp;
					fprintf(logout, "rel_expression\t: simple_expression \n");
			   }
			   |
			   simple_expression RELOP simple_expression
			   {
					SymbolInfo *tmp = new SymbolInfo($1->getName(), "rel_expression");
					
					tmp->dType = "INT";
					tmp->setFlag(0);
					tmp->isZero = false;

					tmp->leftPart = "rel_expression";
					tmp->rightPart = "simple_expression RELOP simple_expression";
					tmp->startLine = $1->startLine;
					tmp->endLine = $3->endLine;

					$1->next = $2;
					$2->next = $3;
					$3->next = NULL;
					tmp->children = $1;

					$$ = tmp;
					fprintf(logout, "rel_expression\t: simple_expression RELOP simple_expression\t  \n");
			   		
					if($1->dType == "VOID" || $3->dType == "VOID"){
						error_count++;
						fprintf(errorout, "Line# %d: Void cannot be used in expression \n", $1->startLine);
					}
			   }
			   ;

simple_expression : term
				  {
						SymbolInfo *tmp = new SymbolInfo($1->getName(), "simple_expression");
						
						tmp->dType = $1->dType;
						tmp->setFlag($1->getFlag());
						tmp->isZero = $1->isZero;
						
						tmp->leftPart = "simple_expression";
						tmp->rightPart = "term";
						tmp->startLine = $1->startLine;
						tmp->endLine = $1->endLine;
						tmp->children = $1;
						$$ = tmp;
						fprintf(logout, "simple_expression : term \n");
				  }
				  |
				  simple_expression ADDOP term
				  {
						SymbolInfo *tmp = new SymbolInfo($1->getName(), "simple_expression");

						tmp->isZero = false;
						
						tmp->leftPart = "simple_expression";
						tmp->rightPart = "simple_expression ADDOP term";
						tmp->startLine = $1->startLine;
						tmp->endLine = $3->endLine;

						$1->next = $2;
						$2->next = $3;
						$3->next = NULL;
						tmp->children = $1;
						
						$$ = tmp;
						fprintf(logout, "simple_expression : simple_expression ADDOP term  \n");

						tmp->setFlag(0);
						if($1->dType == "UNDEFINED" || $3->dType == "UNDEFINED"){
							tmp->dType = "UNDEFINED";
						}
						else if($1->dType == "VOID" || $3->dType == "VOID"){
							error_count++;
							fprintf(errorout, "Line# %d: Void cannot be used in expression \n", $1->startLine);
							tmp->dType = "UNDEFINED";
						}
						else{
							if($1->dType == "INT" && $3->dType == "INT"){
								tmp->dType = "INT";
							}
							else {
								tmp->dType = "FLOAT";
							}
						}
				  }
				  ;

term : unary_expression
	 {
		SymbolInfo *tmp = new SymbolInfo($1->getName(), "term");
		
		tmp->dType = $1->dType;
		tmp->setFlag($1->getFlag());
		tmp->isZero = $1->isZero; // unary_expression can be zero...
		
		tmp->leftPart = "term";
		tmp->rightPart = "unary_expression";
		tmp->startLine = $1->startLine;
		tmp->endLine = $1->endLine;
		tmp->children = $1;
		$$ = tmp;
		fprintf(logout, "term :\tunary_expression \n");
	 }
	 |
	 term MULOP unary_expression
	 {
		// unary_expression can have 4 different dTypes -> UNDEFINED, INT, FLOAT, VOID
		// flags can be 0 -> variable, 1 -> array
		// functions are considered as variables with dType as the returnType of the function.
		// An error has already been shown for functions.

		SymbolInfo *tmp = new SymbolInfo($1->getName(), "term");
		
		tmp->isZero = false;

		tmp->leftPart = "term";
		tmp->rightPart = "term MULOP unary_expression";
		tmp->startLine = $1->startLine;
		tmp->endLine = $3->endLine;

		$1->next = $2;
		$2->next = $3;
		$3->next = NULL;
		tmp->children = $1;

		$$ = tmp;
		fprintf(logout, "term :\tterm MULOP unary_expression \n");

		tmp->setFlag(0);
		// dType and flag needs to be saved....
		bool flag = true; // if this is true farther checking is needed. When we get a certain error...
						  // we no longer look for error
		// Sets teh type of the term
		if($1->dType == "UNDEFINED" || $3->dType == "UNDEFINED"){
			tmp->dType = "UNDEFINED";
			flag = false;
		}
		else if($1->dType == "VOID" || $3->dType == "VOID"){
			error_count++;
			fprintf(errorout, "Line# %d: Void cannot be used in expression \n", $1->startLine);
			tmp->dType = "UNDEFINED";
			flag = false;
		}
		else{
			flag = true;
			if($1->dType == "INT" && $3->dType == "INT"){
				tmp->dType = "INT";
			}
			else {
				tmp->dType = "FLOAT";
			}
		}
		
		// Checks for some errors.
		if(flag){
			if($2->getName() == "%"){
				if($1->dType == "FLOAT" || $3->dType == "FLOAT"){
					error_count++;
					fprintf(errorout, "Line# %d: Operands of modulus must be integers \n", $1->startLine);
					tmp->dType = "UNDEFINED";
				}
				else if($3->isZero){
					error_count++;
					fprintf(errorout, "Line# %d: Warning: division by zero i=0f=1Const=0\n", $1->startLine);
					tmp->dType = "UNDEFINED";
				}
			}
			else if($2->getName() == "/"){
				if($3->isZero){
					error_count++;
					fprintf(errorout, "Line# %d: Warning: division by zero i=0f=1Const=0\n", $1->startLine);
					tmp->dType = "UNDEFINED";
				}
			}
		}
	 }
	 ;

unary_expression : ADDOP unary_expression
				 {
					SymbolInfo *tmp = new SymbolInfo($2->getName(), "unary_expression");
					
					tmp->dType = $2->dType;
					tmp->setFlag($2->getFlag());
					tmp->isZero = false;
					
					tmp->leftPart = "unary_expression";
					tmp->rightPart = "ADDOP unary_expression";
					tmp->startLine = $1->startLine;
					tmp->endLine = $2->endLine;
					
					$1->next = $2;
					$2->next = NULL;
					tmp->children = $1;
					$$ = tmp;

					fprintf(logout, "unary_expression : ADDOP unary_expression \n");
				 }
				 |
				 NOT unary_expression
				 {
					SymbolInfo *tmp = new SymbolInfo($2->getName(), "unary_expression");
					
					tmp->dType = $2->dType;
					tmp->setFlag($2->getFlag());
					tmp->isZero = false;
					
					tmp->leftPart = "unary_expression";
					tmp->rightPart = "NOT unary_expression";
					tmp->startLine = $1->startLine;
					tmp->endLine = $2->endLine;

					$1->next = $2;
					$2->next = NULL;
					tmp->children = $1;
					$$ = tmp;

					fprintf(logout, "unary_expression : NOT unary_expression \n");
				 }
				 |
				 factor
				 {
					// unary_expression can have 3 different dTypes -> UNDEFINED, INT, FLOAT, VOID
					// flags can be 0 -> variable, 1 -> array, 2 
					// functions are considered as variables with dType as the returnType of the function.
					// An error has already been shown for functions.
					SymbolInfo *tmp = new SymbolInfo($1->getName(), "unary_expression");
					
					tmp->dType = $1->dType;
					tmp->setFlag($1->getFlag());
					tmp->isZero = $1->isZero; // factor can be zero...
					
					tmp->leftPart = "unary_expression";
					tmp->rightPart = "factor";
					tmp->startLine = $1->startLine;
					tmp->endLine = $1->endLine;
					tmp->children = $1;
					$$ = tmp;

					fprintf(logout, "unary_expression : factor \n");	
				 }
				 ;
factor : variable
	   {
			// factor can have 3 different dTypes -> UNDEFINED, INT, FLOAT, VOID
			// flags can be 0 -> variable, 1 -> array, 2
			// functions are considered as variables with dType as the returnType of the function.
			// An error has already been shown for functions
			SymbolInfo *tmp = new SymbolInfo($1->getName(), "factor");
			tmp->dType = $1->dType;
			tmp->isZero = $1->isZero; // will be always false
			// Passing the type of ID(array or variable) to the factor.
			tmp->setFlag($1->getFlag());
			tmp->leftPart = "factor";
			tmp->rightPart = "variable";
			tmp->startLine = $1->startLine;
			tmp->endLine = $1->endLine;
			tmp->children = $1;
			$$ = tmp;
			fprintf(logout, "factor\t: variable \n");
	   }
	   |
	   ID LPAREN argument_list RPAREN
	   {
			SymbolInfo *tmp = new SymbolInfo($1->getName(), "factor");
			// Data type should be the return type of the function. As all our return types 
			// are variables .....so we setting the flag 0 -> variable
			// tmp->dType = $1->getType();
			tmp->setFlag(0);
			tmp->isZero = false;
			tmp->leftPart = "factor";
			tmp->rightPart = "ID LPAREN argument_list RPAREN";
			tmp->startLine = $1->startLine;
			tmp->endLine = $4->endLine;

			$1->next = $2;
			$2->next = $3;
			$3->next = $4;
			$4->next = NULL;
			tmp->children = $1;

			$$ = tmp;
			fprintf(logout, "factor\t: ID LPAREN argument_list RPAREN  \n");

			SymbolInfo *check = symbolTable->lookUp($1->getName());

			// bool flag = true;
			if(check == NULL){
				// flag = false;
				error_count++;
				fprintf(errorout, "Line# %d: Undeclared function \'%s\'\n", $1->startLine, $1->getName().c_str());
			}
			else if(check->getFlag() != 2){
				error_count++;
				fprintf(errorout, "Line# %d: \'%s\' is not a function\n", $1->startLine, $1->getName().c_str());
			}
			else if(!check->isDefined){
				error_count++;
				fprintf(errorout, "Line# %d: Inconsistent function call.\n", $1->startLine);
			}
			else{
				// As per specs void functions can't be called.
				// if(check->getType() == "VOID"){
				// 	error_count++;
				// 	fprintf(errorout, "Line# %d: Void functions can't be called.\n", $1->startLine);
				// }

				if(check->params->getLength() > args.getLength()){
					error_count++;
					fprintf(errorout, "Line# %d: Too few arguments to function \'%s\'\n", $1->startLine, $1->getName().c_str());
				}
				else if(check->params->getLength() < args.getLength()){
					error_count++;
					fprintf(errorout, "Line# %d: Too many arguments to function \'%s\'\n", $1->startLine, $1->getName().c_str());
				}
				else{
					SymbolInfo *funcCur = check->params->head;
					SymbolInfo *paramCur = args.head;
					int i = 1;
					while(funcCur != NULL){
						if(funcCur->getType() != paramCur->dType){
							error_count++;
							fprintf(errorout, "Line# %d: Type mismatch for argument %d of \'%s\'\n", $1->startLine, i, $1->getName().c_str());
						}
						funcCur = funcCur->next;
						paramCur = paramCur->next;
						i++;
					}
				}
			}
			
			if(check != NULL){
				tmp->dType = check->getType();
			}
			else{
				tmp->dType = "UNDEFINED";
			}
			args.clear();
	   }
	   |
	   LPAREN expression RPAREN
	   {
			SymbolInfo *tmp = new SymbolInfo($2->getName(), "factor");

			// The dType of factor should the dType of the expression.
			// The flag should be the flag of the expression.
			
			tmp->dType = $2->dType;
			tmp->setFlag($2->getFlag());
			tmp->isZero = $2->isZero; // expression can be zero... 

			tmp->leftPart = "factor";
			tmp->rightPart = "LPAREN expression RPAREN";
			tmp->startLine = $1->startLine;
			tmp->endLine = $3->endLine;

			$1->next = $2;
			$2->next = $3;
			$3->next = NULL;
			tmp->children = $1;

			$$ = tmp;
			fprintf(logout, "factor\t: LPAREN expression RPAREN   \n");
	   }
	   |
	   CONST_INT
	   {
			SymbolInfo *tmp = new SymbolInfo($1->getName(), "factor");
			
			tmp->dType = "INT";
			tmp->setFlag(0);
			if($1->getName() == "0"){
				tmp->isZero = true;
			}
			else{
				tmp->isZero = false;
			}
			
			tmp->leftPart = "factor";
			tmp->rightPart = "CONST_INT";
			tmp->startLine = $1->startLine;
			tmp->endLine = $1->endLine;
			tmp->children = $1;
			$$ = tmp;
			fprintf(logout, "factor\t: CONST_INT   \n");
	   }
	   |
	   CONST_FLOAT
	   {
			SymbolInfo *tmp = new SymbolInfo($1->getName(), "factor");
			
			tmp->dType = "FLOAT";
			tmp->setFlag(0);
			tmp->isZero = false;
			
			tmp->leftPart = "factor";
			tmp->rightPart = "CONST_FLOAT";
			tmp->startLine = $1->startLine;
			tmp->endLine = $1->endLine;
			tmp->children = $1;
			$$ = tmp;
			fprintf(logout, "factor\t: CONST_FLOAT   \n");
	   }
	   |
	   variable INCOP
	   {
			// Remeber we are considereing we will not find a function in the flag...
			// So we are not checking for that.
			// But might be necessary....in the future.

			SymbolInfo *tmp = new SymbolInfo($1->getName() + "++", "factor");
			
			tmp->dType = $1->dType;
			tmp->setFlag($1->getFlag());
			tmp->isZero = false;

			tmp->leftPart = "factor";
			tmp->rightPart = "variable INCOP";
			tmp->startLine = $1->startLine;
			tmp->endLine = $2->endLine;
			
			$1->next = $2;
			$2->next = NULL;
			tmp->children = $1;
			$$ = tmp;
			
			fprintf(logout, "factor\t: variable INCOP \n");
	   }
	   |
	   variable DECOP
	   {
			SymbolInfo *tmp = new SymbolInfo($1->getName() + "--", "factor");
			
			tmp->dType = $1->dType;
			tmp->setFlag($1->getFlag());
			tmp->isZero = false; // We can't tell until we evaluate the expression.
			
			tmp->leftPart = "factor";
			tmp->rightPart = "variable DECOP";
			tmp->startLine = $1->startLine;
			tmp->endLine = $2->endLine;

			$1->next = $2;
			$2->next = NULL;
			tmp->children = $1;
			$$ = tmp;

			fprintf(logout, "factor\t: variable DECOP \n");
	   }
	   ;

argument_list : arguments
			  {
				SymbolInfo *tmp = new SymbolInfo("argument_list", "argument_list");
				tmp->leftPart = "argument_list";
				tmp->rightPart = "arguments";
				tmp->startLine = $1->startLine;
				tmp->endLine = $1->endLine;
				tmp->children = $1;
				$$ = tmp;
				fprintf(logout, "argument_list : arguments  \n");
			  }
			  |
			  {
				SymbolInfo *tmp = new SymbolInfo("argument_list", "argument_list");
				tmp->leftPart = "argument_list";
				tmp->rightPart = "";
				tmp->startLine = line_count;
				tmp->endLine = line_count;
				tmp->children = NULL;
				$$ = tmp;
				fprintf(logout, "argument_list : \n");
			  }
			  ;

arguments : arguments COMMA logic_expression
	 	  {
			SymbolInfo *tmp = new SymbolInfo($1->getName(), "arguments");

			SymbolInfo *arg = new SymbolInfo(to_string(args.getLength()), "argument");
			arg->dType = $3->dType;
			arg->setFlag($3->getFlag());

			tmp->leftPart = "arguments";
			tmp->rightPart = "arguments COMMA logic_expression";
			tmp->startLine = $1->startLine;
			tmp->endLine = $3->endLine;
			
			$1->next = $2;
			$2->next = $3;
			$3->next = NULL;
			tmp->children = $1;
			
			$$ = tmp;
			args.insert(arg);
			fprintf(logout, "arguments : arguments COMMA logic_expression \n");
		  }
		  |
		  logic_expression
		  {
			SymbolInfo *tmp = new SymbolInfo($1->getName(), "arguments");
			
			SymbolInfo *arg = new SymbolInfo(to_string(args.getLength()), "argument");
			arg->dType = $1->dType;
			arg->setFlag($1->getFlag());

			tmp->leftPart = "arguments";
			tmp->rightPart = "logic_expression";
			tmp->startLine = $1->startLine;
			tmp->endLine = $1->endLine;
			tmp->children = $1;
			$$ = tmp;

			args.insert(arg);
			fprintf(logout, "arguments : logic_expression\n");
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
	/* symbolTable->printAllScopeTableInFile(logout); */
  	fprintf(logout, "Total Lines: %d\n", line_count); 
    fprintf(logout, "Total Errors: %d\n", error_count); 
    /* fprintf(logout, "Total warnings: %d\n", warning_count);  */
	fclose(yyin);
	fclose(logout);
	fclose(parseTree);
	delete symbolTable;
	return 0;
}
