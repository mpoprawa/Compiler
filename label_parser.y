%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
int yylex();
int yyerror(char*);
extern FILE *yyin;
extern FILE *yyout;
FILE *labels;

struct function
{
    int pos;
    char *id;
    struct function *next;
};
typedef struct function function;
function *fun_table = NULL;
function *fun_calls = NULL;
function *return_table = NULL;

void insert_function(int,char*,int);
void insert_return(char*);
void function_calls();
%}

%union {
        char* str;
        int num;
        struct
        {
            int pos;
            char *id;
        } fun_data;
    }
%token <str> CHR RTRN HALT ARGUMENT_LIST
%token <num> START ELSE END MAIN
%token <num> WHILE_START WHILE_END WHILE_BEGIN WHILE_RETURN
%token <num> UNTIL_START UNTIL_END 
%token <num> FOR_START FOR_END FOR_BEGIN FOR_RETURN RETURN
%token <fun_data> FUN_START FUN_CALL MAX_VALUE FUN_ARG

%%
all     : jump program                                                              {function_calls(); printf("done\n");}

jump    :                                                                           {fprintf(yyout,"JUMP \n");}

program : program block
        | program CHR                                                               {fprintf(yyout,"%s",$2);}
        |

block   : MAIN                                                                      {fprintf(labels,"0 %d\n",$1);}
        | START program ELSE                                                        {fprintf(labels,"%d %d\n",$1,$3-$1+1);}
        | START program END                                                         {fprintf(labels,"%d %d\n",$1,$3-$1);}
        | WHILE_BEGIN program WHILE_START program WHILE_END program WHILE_RETURN    {fprintf(yyout,"%d",$1-$7); fprintf(labels,"%d %d\n",$3,$5-$3+1);}
        | FOR_BEGIN program FOR_START program FOR_END program FOR_RETURN            {fprintf(yyout,"%d",$1-$7); fprintf(labels,"%d %d\n",$3,$5-$3+1);}
        | UNTIL_START program UNTIL_END                                             {fprintf(yyout,"%d",$1-$3);}
        | FUN_START                                                                 {insert_function($1.pos,$1.id,0);}
        | FUN_CALL                                                                  {insert_function($1.pos,$1.id,1);}
        | RETURN                                                                    {fprintf(yyout,"%d",$1+3);}
        | RTRN                                                                      {fprintf(yyout,"%s",$1); insert_return($1);}
        | MAX_VALUE                                                                 {fprintf(labels,"%d %s\n",$1.pos,$1.id);}
        | ARGUMENT_LIST                                                             {fprintf(labels,"%s\n",$1);}
        | FUN_ARG                                                                   {fprintf(yyout,"STORE "); fprintf(labels,"%d %s\n",$1.pos,$1.id);}
        | HALT                                                                      {fprintf(yyout,"HALT"); fprintf(labels,"%s\n",$1);}
%%

void insert_function(int pos, char *id, int option){
    function *ptr;
    int len = strlen(id+1);
    ptr = (function *) malloc (sizeof(function));
    ptr->pos = pos;
    ptr->id = (char *) malloc (len);
    if (option == 0){
        id[len] = '\0';
        strcpy(ptr->id,id);
        ptr->next = (struct function *)fun_table;
        fun_table = ptr;
    }
    else{
        strcpy (ptr->id,id);
        ptr->next = (struct function *)fun_calls;
        fun_calls = ptr;
    }
}

void insert_return(char *name){
    function *ptr;
    ptr = (function *) malloc (sizeof(function));
    ptr->pos = 0;
    ptr->id = (char *) malloc (strlen(name+1));
    strcpy(ptr->id,name);
    ptr->next = (struct function *)return_table;
    return_table = ptr;
}

void function_calls(){
    function *call;
    function *fn;
    function *rtrn;
    call = fun_calls;
    while (call != NULL){
        rtrn = return_table;
        for (fn = fun_table; strcmp(fn->id,call->id) != 0; fn = (function *)fn->next){
            if (fn->next == NULL){
                printf("calling undeclared function\n");
                return;
            }
            rtrn = rtrn->next;
        }
        fprintf(labels,"%d %s\n",call->pos-1,rtrn->id);
        fprintf(labels,"%d %d\n",call->pos,fn->pos-call->pos);
        call = call->next;
    }
}

int yyerror(char *s)
{
    return 0;
}

int main(int argc, char *argv[])
{
    yyout = fopen("temp2.mr","w");
    labels = fopen("labels.txt", "w");
    yyin = fopen("temp1.mr", "r");
    yyparse();
    fclose(yyin);
	fclose(yyout);
    fclose(labels);
    return 0;
}