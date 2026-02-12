digit [0-9]
letter [a-zA-Z]

%{

#include <stdio.h>
#include "y.tab.h"
int line_number = 1;

%}

%%

{letter}({letter}|{digit})* {yylval.str = strdup(yytext); return VARIABLE;}
\= return EQUALSIGN;
{digit}+ {yylval.number=atoi(yytext); return NUMBER;}
(\+|\-|\*|\/|\^) {yylval.str = strdup(yytext); return OPERATOR;}
\; return SEMICOLON;
\{ return CURVYOPEN;
\} return CURVYCLOSE;
\, {yylval.str = strdup(yytext); return COMMA;}
\n {line_number++;}
[ \t]+

%%