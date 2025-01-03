%option noyywrap
%option yylineno

%{
#include "parser.h"
int yylex();
%}

%%
"PROCEDURE"     { return PROCEDURE; }
"PROGRAM"       { return PROGRAM; }
"BEGIN"         { return BEGIN_T; }
"IS"            { return IS; }
"END"           { return END; }
"WRITE"         { return WRITE; }
"READ"          { return READ; }
"IF"            { return IF; }
"THEN"          { return THEN; }
"ELSE"          { return ELSE; }
"ENDIF"         { return ENDIF; }
"WHILE"         { return WHILE; }
"ENDWHILE"      { return ENDWHILE; }
"REPEAT"        { return REPEAT; }
"UNTIL"         { return UNTIL; }
"FOR"           { return FOR; }
"FROM"          { return FROM; }
"TO"            { return TO; }
"DOWNTO"        { return DOWNTO; }
"DO"            { return DO; }
"ENDFOR"        { return ENDFOR; }
":="            { return ASSIGN; }
"!="            { return N_EQUAL; }
"<="            { return L_EQUAL; }
">="            { return G_EQUAL; }
"="             { return '='; }
"<"             { return '<'; }
">"             { return '>'; }
"["             { return '['; }
"]"             { return ']'; }
":"             { return ':'; }
"("             { return '('; }
")"             { return ')'; }
"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"/"             { return '/'; }
"%"             { return '%'; }
","             { return ','; }
";"             { return ';'; }
"T"             { return 'T'; }
([0-9])* 	    { yylval.num = atoi(yytext); return number; }
[_a-z]+         { yylval.str = strdup(yytext); return pidentifier; }
"#".*   ;
.|\n    ;
%%
