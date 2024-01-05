%{
#include <stdio.h>
#include <stdlib.h>
#include "2005077_SymbolTable.h"

void yyerror(char *s){
	
}

void changeState();
int yylex(void);

FILE* logout;
extern FILE* yyin;

%}

%union {
    SymbolInfo *symbol;
}

%token <symbol> INT, FLOAT, VOID, SEMICOLON, COMMA, ID, LTHIRD, CONST_INT, RTHIRD
%%
start : program
	  {
		fprintf(logout, "start : program\n");
	  }
      ;
program : program_unit
		{
			fprintf(logout, "program : program_unit\n");
		}
        ;
program_unit : var_declaration
			 {
				fprintf(logout, "program_unit : var_declaration\n");
			 }
        	 ;
var_declaration : type_specifier declaration_list SEMICOLON
				{
					fprintf(logout, "var_declaration : type_specifier declaration_list SEMICOLON\n");
				}
        		;
type_specifier : INT
				{
					fprintf(logout, "type_specifier: INT\n");
				}
                | FLOAT
				{
					fprintf(logout, "type_specifier: FLOAT\n");
				}
                | VOID
				{
					fprintf(logout, "type_specifier: VOID\n");
				}
                ;
declaration_list : declaration_list COMMA ID
				 {
					fprintf(logout, "declaration_list : declaration_list COMMA ID\n");
				 }
                 | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
				 {
					fprintf(logout, "declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n");
				 }
                 | ID
				 {
					fprintf(logout, "declaration_list : ID\n");
				 }
                 | ID LTHIRD CONST_INT RTHIRD
				 {
					fprintf(logout, "declaration_list : ID LTHIRD CONST_INT RTHIRD\n");
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
	/* fclose(tokenout); */
	fclose(logout);
	return 0;
}
