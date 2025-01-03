%option noyywrap
%option yylineno

%{
#include "label_parser.h"
int yylex();
%}

%%
"IFEND "                    {yylval.num = yylineno; return END;}
"IFELSE "                   {yylval.num = yylineno; return ELSE;}
"IFEND"                     {yylval.num = yylineno; return START;}
"WHILEEND "                 {yylval.num = yylineno; return WHILE_END;}
"WHILEEND"                  {yylval.num = yylineno; return WHILE_START;}
"WHILESTART "               {yylval.num = yylineno; return WHILE_BEGIN;}
"WHILESTART"                {yylval.num = yylineno; return WHILE_RETURN;}
"UNTILSTART "               {yylval.num = yylineno; return UNTIL_START;}
"UNTILSTART"                {yylval.num = yylineno; return UNTIL_END;}
"FOREND "                   {yylval.num = yylineno; return FOR_END;}
"FOREND"                    {yylval.num = yylineno; return FOR_START;}
"FORSTART "                 {yylval.num = yylineno; return FOR_BEGIN;}
"FORSTART"                  {yylval.num = yylineno; return FOR_RETURN;}
"MAIN "                     {yylval.num = yylineno; return MAIN;}
"RETURN"                    {yylval.num = yylineno; return RETURN;}
"RTRN ".*                   {yylval.str = yytext; return RTRN;}
"FN$_".*"_$FN [ ".*" ] "    {yylval.str = yytext; return ARGUMENT_LIST;}
"STORE FN$_".*"_$FN"        {yylval.fun_data.pos = yylineno; yylval.fun_data.id = yytext; return FUN_ARG;}
"FUN$_".*"_$FUN "           {yylval.fun_data.pos = yylineno; yylval.fun_data.id = yytext; return FUN_START;}
"FUN$_".*"_$FUN"            {yylval.fun_data.pos = yylineno; yylval.fun_data.id = yytext; return FUN_CALL;}
"$+"[0-9]*                  {yylval.fun_data.pos = yylineno; yylval.fun_data.id = yytext; return MAX_VALUE;}
"HALT "[0-9]*               {yylval.str = yytext; return HALT;}
.|\n                        {yylval.str = yytext; return CHR;}
%%