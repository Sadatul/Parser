%option noyywrap

%x CONST_CHAR
%x CONST_STRING
%x SINGLE_LINE_COMMENT
%x MULTI_LINE_COMMENT
%x INDENT

%{
#include<stdio.h>
#include<stdlib.h>
#include<ctype.h>
#include<string.h>
#include "2005077_SymbolTable.h"
#include<iostream>
#include "parser.hpp"

extern int line_count;
extern int error_count;
extern int warning_count;

extern FILE *logout;
// FILE *tokenout;

std::string lexeme;
std::string characterToken;

int scopeCounter = 0;
int spaceCounter = 0;
bool gotSpace = false;

std::string stringToken;
bool multiLineString = false;
int startLine;

// SymbolTable symbolTable(10);

char *toUpper(char *s){
    int n = strlen(s);
    char *newChar = new char[n+1];
    int i = 0;
    while(*s){
        newChar[i] = toupper(*s);
        s++;
        i++;
    }
    newChar[i] = '\0';
    return newChar;
}

void endFile(){
    fprintf(logout, "Total number of errors: %d\n", error_count);
    fprintf(logout, "Total number of lines: %d\n", line_count);
}

%}
WHITESPACE [ \t\r\v\f]+
DIGIT [0-9]
KEYWORDS if|else|for|while|do|break|int|char|float|double|void|return|switch|case|default|continue
NEWLINE \n
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
CONST_INT {DIGIT}+
CONST_FLOAT (({DIGIT}+(\.{DIGIT}+)?)|\.{DIGIT}+)([Ee][+-]?{DIGIT}+)?
MULTI_DOT {DIGIT}*(\.{DIGIT}*)(\.{DIGIT}*)+([Ee][+-]?{DIGIT}+)?
ILL_FORMED (({DIGIT}+(\.{DIGIT}+)?)|\.{DIGIT}+)([Ee][+-]?{DIGIT}*(\.{DIGIT}*)*)+
NUMERIC {CONST_INT}|{CONST_FLOAT}
SUFFIX_PREFIX {NUMERIC}[a-zA-Z_][a-zA-Z0-9_]*

%%
{WHITESPACE} {}
int {
    SymbolInfo *tmp = new SymbolInfo(yytext, "INT");
    tmp->leftPart = "INT";
    tmp->rightPart = "int";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    fprintf(logout, "Line# %d: Token <INT> Lexeme int found\n", line_count);
    return INT;
}
float {
    SymbolInfo *tmp = new SymbolInfo(yytext, "FLOAT");
    tmp->leftPart = "FLOAT";
    tmp->rightPart = "float";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    fprintf(logout, "Line# %d: Token <FLOAT> Lexeme float found\n", line_count);
    return FLOAT;
}
void {
    SymbolInfo *tmp = new SymbolInfo(yytext, "VOID");
    tmp->leftPart = "VOID";
    tmp->rightPart = "void";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    fprintf(logout, "Line# %d: Token <VOID> Lexeme void found\n", line_count);
    return VOID;
}

return {
    SymbolInfo *tmp = new SymbolInfo(yytext, "RETURN");
    tmp->leftPart = "RETURN";
    tmp->rightPart = "return";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;

    fprintf(logout, "Line# %d: Token <RETURN> Lexeme return found\n", line_count);
    return RETURN;

}

for {
    SymbolInfo *tmp = new SymbolInfo(yytext, "FOR");
    tmp->leftPart = "FOR";
    tmp->rightPart = "for";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;

    fprintf(logout, "Line# %d: Token <FOR> Lexeme for found\n", line_count);
    return FOR;

}

if {
    SymbolInfo *tmp = new SymbolInfo(yytext, "IF");
    tmp->leftPart = "IF";
    tmp->rightPart = "if";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;

    fprintf(logout, "Line# %d: Token <IF> Lexeme if found\n", line_count);
    return IF;

}

else {
    SymbolInfo *tmp = new SymbolInfo(yytext, "ELSE");
    tmp->leftPart = "ELSE";
    tmp->rightPart = "else";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;

    fprintf(logout, "Line# %d: Token <ELSE> Lexeme else found\n", line_count);
    return ELSE;

}

while {
    SymbolInfo *tmp = new SymbolInfo(yytext, "WHILE");
    tmp->leftPart = "WHILE";
    tmp->rightPart = "while";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;

    fprintf(logout, "Line# %d: Token <WHILE> Lexeme while found\n", line_count);
    return WHILE;
}

println {
    SymbolInfo *tmp = new SymbolInfo(yytext, "PRINTLN");
    tmp->leftPart = "PRINTLN";
    tmp->rightPart = "println";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;

    fprintf(logout, "Line# %d: Token <PRINTLN> Lexeme println found\n", line_count);
    return PRINTLN;
}
{CONST_INT} {
    // fprintf(tokenout,"<CONST_INT, %s>\n", yytext);
    SymbolInfo *tmp = new SymbolInfo(yytext, "CONST_INT");
    tmp->leftPart = "CONST_INT";
    tmp->rightPart = yytext;
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    fprintf(logout, "Line# %d: Token <CONST_INT> Lexeme %s found\n", line_count, yytext);
    return CONST_INT;    
}
{CONST_FLOAT} {
    SymbolInfo *tmp = new SymbolInfo(yytext, "CONST_FLOAT");
    tmp->leftPart = "CONST_FLOAT";
    tmp->rightPart = yytext;
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<CONST_FLOAT, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <CONST_FLOAT> Lexeme %s found\n", line_count, yytext);
    return CONST_FLOAT;
}
{MULTI_DOT} {
    fprintf(logout,"Error at line# %d: TOO_MANY_DECIMAL_POINTS %s\n",line_count, yytext);
    error_count++;
}
{ILL_FORMED} {
    fprintf(logout,"Error at line# %d: ILLFORMED_NUMBER %s\n",line_count, yytext);
    error_count++;
}
{SUFFIX_PREFIX} {
    fprintf(logout,"Error at line# %d: INVALID_ID_SUFFIX_NUM_PREFIX %s\n",line_count, yytext);
    error_count++;
}



' {
    characterToken = "";
    lexeme = "";
    BEGIN(CONST_CHAR);
}

<CONST_CHAR>' {
    if(characterToken.length() == 0){
        fprintf(logout, "Error at line# %d: EMPTY_CONST_CHAR \'\'\n", line_count);
        error_count++;
    }
    else if(characterToken.length() == 2 && characterToken[0] == '\\'){
        fprintf(logout, "Error at line# %d: UNRECOGNIZED_CHAR \'%s\'\n", line_count, lexeme.c_str());
        error_count++;
    }
    else if(characterToken.length() > 1){
        fprintf(logout, "Error at line# %d: MULTICHAR_CONST_CHAR \'%s\'\n", line_count, lexeme.c_str());
        error_count++;
    }else{
        // fprintf(tokenout,"<CONST_CHAR, %s>\n", characterToken.c_str());
        fprintf(logout, "Line# %d: Token <CONST_CHAR> Lexeme %s found\n", line_count, characterToken.c_str());
    }
    BEGIN(INITIAL);
}

<CONST_CHAR>\\[nt\'afrbv0\"\\] {
    char c;
    switch(yytext[1]){
        case 'n': c = '\n'; break;
        case 't': c = '\t'; break;
        case '\'': c = '\''; break;
        case 'a': c = '\a'; break;
        case 'f': c = '\f'; break;
        case 'r': c = '\r'; break;
        case 'b': c = '\b'; break;
        case 'v': c = '\v'; break;
        case '0': c = '\0'; break;
        case '\"': c = '\"'; break;
        case '\\': c = '\\'; break;
    }
    characterToken += c;
    lexeme += yytext;
}

<CONST_CHAR>\n {
    fprintf(logout, "Error at line# %d: UNFINISHED_CONST_CHAR \'%s\n", line_count, lexeme.c_str());
    error_count++;
    // line_count++;
    BEGIN(INITIAL);
    unput(yytext[0]);
}

<CONST_CHAR><<EOF>> {
    fprintf(logout, "Error at line# %d: UNFINISHED_CONST_CHAR \'%s\n", line_count, lexeme.c_str());
    error_count++;
    BEGIN(INITIAL);
    // endFile();
}

<CONST_CHAR>. {
    characterToken += yytext;
    lexeme += yytext;
}

"+"|"-" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "ADDOP");
    tmp->leftPart = "ADDOP";
    tmp->rightPart = yytext;
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<ADDOP, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <ADDOP> Lexeme %s found\n", line_count, yytext);
    return ADDOP;
}

"*"|"/"|"%" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "MULOP");
    tmp->leftPart = "MULOP";
    tmp->rightPart = yytext;
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<MULOP, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <MULOP> Lexeme %s found\n", line_count, yytext);
    return MULOP;
}

"++" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "INCOP");
    tmp->leftPart = "INCOP";
    tmp->rightPart = yytext;
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<INCOP, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <INCOP> Lexeme %s found\n", line_count, yytext);
    return INCOP;
}

"--" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "DECOP");
    tmp->leftPart = "DECOP";
    tmp->rightPart = yytext;
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<DECOP, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <DECOP> Lexeme %s found\n", line_count, yytext);
    return DECOP;

}
"<"|">"|"<="|">="|"=="|"!=" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "RELOP");
    tmp->leftPart = "RELOP";
    tmp->rightPart = yytext;
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<RELOP, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <RELOP> Lexeme %s found\n", line_count, yytext);
    return RELOP;
}

"=" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "ASSIGNOP");
    tmp->leftPart = "ASSIGNOP";
    tmp->rightPart = "=";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<ASSIGNOP, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <ASSIGNOP> Lexeme %s found\n", line_count, yytext);
    return ASSIGNOP;
}

"&&"|"||" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "LOGICOP");
    tmp->leftPart = "LOGICOP";
    tmp->rightPart = yytext;
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<LOGICOP, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <LOGICOP> Lexeme %s found\n", line_count, yytext);
    return LOGICOP;
}

"!" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "NOT");
    tmp->leftPart = "NOT";
    tmp->rightPart = yytext;
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<NOT, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <NOT> Lexeme %s found\n", line_count, yytext);
    return NOT;
}

"&"|"|"|"^"|"<<"|">>" {
    // fprintf(tokenout,"<BITOP, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <BITOP> Lexeme %s found\n", line_count, yytext);
}

"(" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "LPAREN");
    tmp->leftPart = "LPAREN";
    tmp->rightPart = "(";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<LPAREN, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <LPAREN> Lexeme %s found\n", line_count, yytext);
    return LPAREN;
}

")" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "RPAREN");
    tmp->leftPart = "RPAREN";
    tmp->rightPart = ")";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<RPAREN, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <RPAREN> Lexeme %s found\n", line_count, yytext);
    return RPAREN;
}

"{" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "LCURL");
    tmp->leftPart = "LCURL";
    tmp->rightPart = "{";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<LCURL, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <LCURL> Lexeme %s found\n", line_count, yytext);
    // symbolTable.enterScope();
    scopeCounter++;
    return LCURL;
}

"}" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "RCURL");
    tmp->leftPart = "RCURL";
    tmp->rightPart = "}";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<RCURL, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <RCURL> Lexeme %s found\n", line_count, yytext);
    // symbolTable.exitScope();
    scopeCounter--;
    return RCURL;
    // symbolTable.printAllScopeTableInFile(logout);
}

"[" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "LSQUARE");
    tmp->leftPart = "LSQUARE";
    tmp->rightPart = "[";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<LSQUARE, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <LSQUARE> Lexeme %s found\n", line_count, yytext);
    return LSQUARE;

}

"]" {
    SymbolInfo *tmp = new SymbolInfo(yytext, "RSQUARE");
    tmp->leftPart = "RSQUARE";
    tmp->rightPart = "]";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    // fprintf(tokenout,"<RSQUARE, %s>\n", yytext);
    fprintf(logout, "Line# %d: Token <RSQUARE> Lexeme %s found\n", line_count, yytext);
    return RSQUARE;
}

"," {
    // fprintf(tokenout,"<COMMA, %s>\n", yytext);
    SymbolInfo *tmp = new SymbolInfo(yytext, "COMMA");
    tmp->leftPart = "COMMA";
    tmp->rightPart = ",";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    fprintf(logout, "Line# %d: Token <COMMA> Lexeme %s found\n", line_count, yytext);
    return COMMA;
}

";" {
    // fprintf(tokenout,"<SEMICOLON, %s>\n", yytext);
    SymbolInfo *tmp = new SymbolInfo(yytext, "SEMICOLON");
    tmp->leftPart = "SEMICOLON";
    tmp->rightPart = ";";
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    fprintf(logout, "Line# %d: Token <SEMICOLON> Lexeme %s found\n", line_count, yytext);
    return SEMICOLON;
}

{IDENTIFIER} {
    // bool tmp = symbolTable.insert(yytext, "ID");
    // fprintf(tokenout,"<ID, %s>\n", yytext);
    SymbolInfo *tmp = new SymbolInfo(yytext, "ID");
    tmp->leftPart = "ID";
    tmp->rightPart = yytext;
    tmp->isLeaf = true;
    tmp->startLine = line_count;
    tmp->endLine = line_count;
    yylval.symbol = tmp;
    fprintf(logout, "Line# %d: Token <ID> Lexeme %s found\n", line_count, yytext);
    // if(!tmp){
    //     fprintf(logout, "\t%s already exists in the current ScopeTable\n", yytext);
    // } else {
    //     symbolTable.printAllScopeTableInFile(logout);
    // }
    return ID;
}


\" {
    BEGIN(CONST_STRING);
    stringToken = "";
    multiLineString = false;
    lexeme = "";
    startLine = line_count;
}

<CONST_STRING>\" {
    std::string tmp = "SINGLE LINE STRING";
    if(multiLineString){
        tmp = "MULTI LINE STRING";
    }
    // fprintf(tokenout,"<%s, %s>\n", tmp.c_str(), stringToken.c_str());
    fprintf(logout, "Line# %d: Token <%s> Lexeme \"%s\" found\n", startLine, tmp.c_str(), lexeme.c_str());
    BEGIN(INITIAL);
}

<CONST_STRING>\\\n {
    multiLineString = true;
    line_count++;
    lexeme += yytext;
}

<CONST_STRING>\\[nt\'afrbv0\"\\] {
    char c;
    switch(yytext[1]){
        case 'n': c = '\n'; break;
        case 't': c = '\t'; break;
        case '\'': c = '\''; break;
        case 'a': c = '\a'; break;
        case 'f': c = '\f'; break;
        case 'r': c = '\r'; break;
        case 'b': c = '\b'; break;
        case 'v': c = '\v'; break;
        case '0': c = '\0'; break;
        case '\"': c = '\"'; break;
        case '\\': c = '\\'; break;
    }

    stringToken += c;
    lexeme += yytext;
}
<CONST_STRING>\n {
    fprintf(logout, "Error at line# %d: UNFINISHED_STRING \"%s\n", line_count, lexeme.c_str());
    error_count++;
    // line_count++;
    BEGIN(INITIAL);
    unput(yytext[0]);
}

<CONST_STRING><<EOF>> {
    fprintf(logout, "Error at line# %d: UNFINISHED_STRING \"%s\n", line_count, lexeme.c_str());
    error_count++;
    BEGIN(INITIAL);
    // endFile();
}

<CONST_STRING>. {
    lexeme += yytext;
    stringToken += yytext;
}

"//" {
    BEGIN(SINGLE_LINE_COMMENT);
    startLine = line_count;
    lexeme = "//";
}

<SINGLE_LINE_COMMENT>\\\n {
    line_count++;
    lexeme += yytext;
}

<SINGLE_LINE_COMMENT>\n {
    fprintf(logout, "Line# %d: Token <SINGLE LINE COMMENT> Lexeme %s found\n", startLine, lexeme.c_str());
    // line_count++;
    BEGIN(INITIAL);
    unput(yytext[0]);
}
<SINGLE_LINE_COMMENT>. {
    lexeme += yytext;
}

<SINGLE_LINE_COMMENT><<EOF>> {
    fprintf(logout, "Line# %d: Token <SINGLE LINE COMMENT> Lexeme %s found\n", startLine, lexeme.c_str());
    BEGIN(INITIAL);
    // endFile();
}


"/*" {
    BEGIN(MULTI_LINE_COMMENT);
    startLine = line_count;
    lexeme = "/*";
}

<MULTI_LINE_COMMENT>\n {
    line_count++;
    lexeme += yytext;
}

<MULTI_LINE_COMMENT>. {
    lexeme += yytext;
}
<MULTI_LINE_COMMENT><<EOF>> {
    fprintf(logout, "Error at line# %d: UNFINISHED_COMMENT %s\n", line_count, lexeme.c_str());
    error_count++;
    BEGIN(INITIAL);
    // endFile();
}

<MULTI_LINE_COMMENT>"*/" {
    fprintf(logout, "Line# %d: Token <MULTI LINE COMMENT> Lexeme %s*/ found\n", startLine, lexeme.c_str());
    BEGIN(INITIAL);
}

{NEWLINE} {
    line_count++;
    spaceCounter = 0;
    BEGIN(INDENT);
    gotSpace = false;
}

<INDENT>" " {
    spaceCounter++;
    gotSpace = true;
}
<INDENT>"\t" {
    spaceCounter += 4;
}
<INDENT>"\n" {
    line_count++;
    spaceCounter = 0;
    gotSpace = false;
}
<INDENT>. {
    if(yytext[0] == '}'){
        scopeCounter--;
    }
    
    // If you want space for indention

    // if(spaceCounter != scopeCounter*4){
    //     if(spaceCounter % 4 == 0){
    //         fprintf(logout, "Line# %d: warning, %d of tabs needed but got %d tabs.\n", line_count, scopeCounter, spaceCounter/4);
    //         warning_count++;
    //     } else {
    //         fprintf(logout, "Line# %d: Warning, tab requrired but got space.\n", line_count);
    //         warning_count++;
    //     }
    // }

    // Only tab for indentation
    if(gotSpace){
        fprintf(logout, "Line# %d: Warning, tab requrired but got space.\n", line_count);
        warning_count++;
    } else if(spaceCounter != scopeCounter*4){
        fprintf(logout, "Line# %d: warning, %d of tabs needed but got %d tabs.\n", line_count, scopeCounter, spaceCounter/4);
        warning_count++;
    }

    if(yytext[0] == '}'){
        scopeCounter++;
    }
    unput(yytext[0]);
    BEGIN(INITIAL);
}

. {
    fprintf(logout, "Error at line# %d: UNRECOGNIZED_CHAR %s\n", line_count, yytext);
    error_count++;
}
%%

void changeState(){
    BEGIN(INDENT);
}

/* int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("2005077_log.txt","w");
	tokenout= fopen("2005077_token.txt","w");

    BEGIN(INDENT);

	yyin= fin;
	yylex();

    symbolTable.printAllScopeTableInFile(logout);
    /* Total lines: 16
Total errors: 14
Total warnings: 0 
    fprintf(logout, "Total lines: %d\n", line_count);
    fprintf(logout, "Total errors: %d\n", error_count);
    fprintf(logout, "Total warnings: %d\n", warning_count);
	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
} */