%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<limits.h>
int yylex();
int yyerror(char*);
extern int linenum;
extern FILE *yyin;
extern FILE *yyout;

long long error_type = 0;
long long variable_count = 1;
long long max_count = 1;
long long loop_type; /*0-IF 1-WHILE 2-UNTIL 3=FOR*/
char* current_scope = "main";
char* current_function = "main";
long long fun_loc = 0;
long long arg_count = 0;
struct symbol
{
    long long num;
    long long start;
    long long end;
    long long type;
    long long initialised;
    long long iterator;
    char *name;
    char *scope;
    struct symbol *next;
};
typedef struct symbol symbol;
symbol *sym_table = NULL;

void  insert_sym(char *sym_name, long long type, long long start, long long end){
    long long len = end-start;
    symbol *ptr;
    ptr = (symbol *) malloc (sizeof(symbol));
    ptr->num = variable_count;
    if (len>0){
        variable_count += 2 + len;
    }
    else{
        variable_count += 1;
    }
    if (variable_count>max_count){
        max_count = variable_count;
    }
    ptr->start = start;
    ptr->end = variable_count-1;
    if (type == 3){
        ptr->type = 0;
        ptr->initialised = 1;
        ptr->iterator = 1;
    }
    else{
        ptr->type = type;
        ptr->initialised = 0;
        ptr->iterator = 0;
    }
    ptr->name = (char *) malloc (strlen(sym_name)+1);
    strcpy (ptr->name,sym_name);
    ptr->scope = (char *) malloc (strlen(current_scope)+1);
    strcpy (ptr->scope,current_scope);
    ptr->next = (struct symbol *)sym_table;
    sym_table = ptr;
}
symbol*  get_sym(char *sym_name){
    symbol *ptr;
    for (ptr = sym_table; ptr != NULL; ptr = (symbol *)ptr->next){
        if (strcmp(ptr->name,sym_name) == 0 && strcmp(ptr->scope,current_scope) == 0){
            return ptr;
        }
    }
    return NULL;
}
void declare(char *sym_name, long long type){ /*0-zmienna 1-argument*/
    symbol *s;
    s =  get_sym(sym_name);
    if (s == NULL || sym_name == "for_limit" || sym_name == "array_adr")
        insert_sym(sym_name, type, 0, 0);
    else {
        error_type = 3;
        yyerror(sym_name);
    }
}
void declare_array(char *sym_name, long long type, long long start, long long end){
    if (start>end){
        error_type = 4;
        yyerror(sym_name);
    }

    symbol *s;
    s =  get_sym(sym_name);
    if (s == NULL || sym_name == "for_limit" || sym_name == "array_adr")
        insert_sym(sym_name, type, start, end);
    else {
        error_type = 3;
        yyerror(sym_name);
    }
}
long long sym_check(char *sym_name){
    symbol *sym =  get_sym(sym_name);
    if (sym == NULL){
        error_type = 2;
        yyerror(sym_name);
    }
    else{
        return sym->num;
    }
}
long long num_check(long long i){
    symbol *ptr;
    for (ptr = sym_table; ptr != NULL; ptr = (symbol *)ptr->next){
        if (ptr->num == i){
            return ptr->type;
        }
    }
}
long long find_in_scope(char *sym_name){
    char *temp_scope = current_scope;
    current_scope = current_function;
    symbol *sym =  get_sym(sym_name);
    if (sym == NULL){
        error_type = 8;
        yyerror(current_function);
    }
    else{
        current_scope = temp_scope;
        return sym->num;
    }   
}
void type_check(char *sym_name, long long type){/*0-long long 1-tablica*/
    symbol *sym =  get_sym(sym_name);
    if (sym == NULL){
        error_type = 2;
        yyerror(sym_name);
    }
    if (type == 0 && (sym->num != sym->end || sym->type == 2)){
        if (arg_count == 0){
            error_type = 5;
            yyerror(sym_name);
        }
        else{
            error_type = 12;
            yyerror(current_function);
        }
    }
    if (type == 1 && (sym->num == sym->end && sym->type != 2)){
        if (arg_count == 0){
            error_type = 6;
            yyerror(sym_name);
        }
        else{
            error_type = 12;
            yyerror(current_function);
        }
    }
}
void bound_check(char *sym_name, long long n){
    symbol *sym =  get_sym(sym_name);
    if (sym == NULL){
        error_type = 2;
        yyerror(sym_name);
    }
    long long end = sym->end - sym->num + sym->start -1;
    //printf("%lld %lld %lld\n",sym->start,end,n);
    if (sym->type == 0 && (n<sym->start || n>end)){
        error_type = 14;
        yyerror(sym_name);
    }
}
void init(long long i){
    symbol *ptr;
    for (ptr = sym_table; ptr != NULL; ptr = (symbol *)ptr->next){
        if (ptr->num == i){
            break;
        }
    }
    if (ptr->iterator == 1){
        error_type = 16;
        yyerror(ptr->name);
    }
    ptr->initialised = 1;
}
void init_check(char *sym_name){
    symbol *ptr;
    ptr = get_sym(sym_name);
    if (ptr->initialised == 0 && ptr->type == 0){
        error_type = 15;
        yyerror(ptr->name);
    }
}
void print_sym_table(){
    symbol *ptr;
    for (ptr = sym_table; ptr != NULL; ptr = (symbol *)ptr->next){
        printf("%s %lld type %lld starts at %lld ends at %lld in %s init is %lld\n",ptr->name,ptr->num,ptr->type,ptr->num,ptr->end,ptr->scope,ptr->initialised);
    }
}

void load_var(long long);
void store_var(long long);
void add_var(long long);
void sub_var(long long);
void write_var(long long*);
void handle_addition(long long*,long long*);
void handle_subtraction(long long*,long long*);
void handle_multiplication(long long*,long long*);
void handle_division(long long*,long long*);
void handle_modulo(long long*,long long*);
void handle_compare(long long*,long long*,long long);
void start_for(long long*,long long*,long long,long long);
void end_for(long long*);
void add_argument(char*);
%}

%union {
        long long pair[2];
        long long num;
        char* str;
    }
%token PROCEDURE PROGRAM IS BEGIN_T END
%token WRITE READ IF THEN ELSE ENDIF WHILE ENDWHILE REPEAT UNTIL FOR FROM TO DOWNTO DO ENDFOR
%token ASSIGN N_EQUAL L_EQUAL G_EQUAL
%token <num> number
%token <str> pidentifier

%left '+' '-'
%left '*' '/' '%'

%type <num> identifier aidentifier val
%type <str> prefunc
%type <pair> value for 

%%
program_all : procedures main {fprintf(yyout,"HALT %lld",max_count); printf("done\n");}

procedures  : procedures PROCEDURE proc_head IS declarations BEGIN_T commands END   {fprintf(yyout,"RTRN %lld\n",sym_check("return")); variable_count = max_count;}
            | procedures PROCEDURE proc_head IS BEGIN_T commands END                {fprintf(yyout,"RTRN %lld\n",sym_check("return")); variable_count = max_count;}
            |

proc_head   : fidentifier '(' args_decl ')'

fidentifier : pidentifier                                                           {fprintf(yyout,"FUN$_%s_$FUN ",$1); current_scope = $1; declare("return",0);}                                         

args_decl   : args_decl ',' pidentifier                                             {declare($3,1);}
            | pidentifier                                                           {declare($1,1);}
            | args_decl ',' 'T' pidentifier                                         {declare($4,2);}
            | 'T' pidentifier                                                       {declare($2,2);}
            |

main        : premain PROGRAM IS declarations temp BEGIN_T commands END temp
            | premain PROGRAM IS BEGIN_T commands END

temp        :

declarations: declarations ',' pidentifier                              {declare($3,0);}
            | pidentifier                                               {declare($1,0);}
            | declarations ',' pidentifier '[' val ':' val ']'          {declare_array($3,0,$5,$7); long long pos = sym_check($3);
                                                                        fprintf(yyout,"SET %lld\n",pos-$5+1); fprintf(yyout,"STORE %lld\n",pos);}
            | pidentifier '[' val ':' val ']'                           {declare_array($1,0,$3,$5); long long pos = sym_check($1);
                                                                        fprintf(yyout,"SET %lld\n",pos-$3+1); fprintf(yyout,"STORE %lld\n",pos);}

commands    : commands command
            | command

command     : aidentifier assign expression lineend                     {store_var($1); init($1);}
            | if IF condition THEN commands ENDIF                       {fprintf(yyout,"IFEND ");}
            | if IF condition THEN commands else ELSE commands ENDIF    {fprintf(yyout,"IFEND ");}
            | while WHILE condition DO commands ENDWHILE                {fprintf(yyout,"WHILEEND JUMP WHILESTART\n");}
            | repeat1 REPEAT commands repeat2 UNTIL condition lineend
            | FOR for commands ENDFOR                                   {end_for($2);}
            | proc_call lineend
            | WRITE value lineend                                       {write_var($2);}
            | READ aidentifier lineend                                  {fprintf(yyout,"GET %lld\n",$2); init($2);}

premain     :                                                           {fprintf(yyout,"MAIN "); current_scope = "main";}
if          :                                                           {loop_type = 0;}
else        :                                                           {fprintf(yyout,"IFELSE "); fprintf(yyout,"JUMP IFEND\n");}
while       :                                                           {loop_type = 1;}
repeat1     :                                                           {fprintf(yyout,"UNTILSTART ");}
repeat2     :                                                           {loop_type = 2;}

for         : pidentifier FROM value TO value DO        {loop_type=3; declare($1,3); declare("for_limit",0); $$[0]=0; $$[1]=sym_check($1);
                                                        start_for($3,$5,$$[1],$$[0]);}
            | pidentifier FROM value DOWNTO value DO    {loop_type=3; declare($1,3); declare("for_limit",0); $$[0]=1; $$[1]=sym_check($1);
                                                        start_for($3,$5,$$[1],$$[0]);}

expression  : value                 {if ($1[0]==0){
                                        fprintf(yyout,"SET %lld\n",$1[1]);}
                                    else{
                                        load_var($1[1]);};}
            | value '+' value       {handle_addition($1,$3);}
            | value '-' value       {handle_subtraction($1,$3);}
            | value '*' value       {handle_multiplication($1,$3);}
            | value '/' value       {handle_division($1,$3);}
            | value '%' value       {handle_modulo($1,$3);}

condition   : value '=' value       {handle_compare($1,$3,0);}
            | value '<' value       {handle_compare($1,$3,1);}
            | value '>' value       {handle_compare($1,$3,2);}
            | value N_EQUAL value   {handle_compare($1,$3,3);}
            | value L_EQUAL value   {handle_compare($1,$3,4);}
            | value G_EQUAL value   {handle_compare($1,$3,5);}

value       : val                   {$$[0] = 0;
                                     $$[1] = $1;}
            | identifier            {$$[0] = 1;
                                     $$[1] = $1;}

val         : number                   {$$ = $1;}
            | '-' number               {$$ = -$2;}

aidentifier  : pidentifier                      {type_check($1,0); $$ = sym_check($1);}
            | pidentifier '[' val ']'           {type_check($1,1); bound_check($1,$3); long long pos = sym_check($1); fprintf(yyout,"SET %lld\n",$3); add_var(pos);
                                                 declare("array_adr",1  ); $$ = sym_check("array_adr"); fprintf(yyout,"STORE %lld\n",$$);}
            | pidentifier '[' pidentifier ']'   {type_check($1,1); type_check($3,0); init_check($3); long long pos = sym_check($1); load_var(sym_check($3)); add_var(pos);
                                                 declare("array_adr",1  ); $$ = sym_check("array_adr"); fprintf(yyout,"STORE %lld\n",$$);}

identifier  : pidentifier                       {type_check($1,0); $$ = sym_check($1); init_check($1);}
            | pidentifier '[' val ']'           {type_check($1,1); bound_check($1,$3); long long pos = sym_check($1); fprintf(yyout,"SET %lld\n",$3); add_var(pos);
                                                 declare("array_adr",1  ); $$ = sym_check("array_adr"); fprintf(yyout,"STORE %lld\n",$$);}
            | pidentifier '[' pidentifier ']'   {type_check($1,1); type_check($3,0); init_check($3); long long pos = sym_check($1); load_var(sym_check($3)); add_var(pos);
                                                 declare("array_adr",1  ); $$ = sym_check("array_adr"); fprintf(yyout,"STORE %lld\n",$$);}

proc_call   : prefunc '(' args ')'      {long long type = num_check(fun_loc+arg_count);
                                         if (type == 1 || type == 2){
                                            error_type = 11;
                                            yyerror(current_function);}
                                         arg_count = 0;
                                         fprintf(yyout,"SET RETURN\n");
                                         fprintf(yyout,"STORE %lld\n",fun_loc);
                                         fprintf(yyout,"JUMP FUN$_%s_$FUN\n",$1);}

args        : args ',' pidentifier      {add_argument($3); init(sym_check($3));}
            | pidentifier               {add_argument($1); init(sym_check($1));}

prefunc     : pidentifier               {if (strcmp($1,current_scope) == 0){error_type = 9; yyerror($1);}
                                         current_function = $1; fun_loc = find_in_scope("return"); arg_count = 1;}

lineend     : ';'
            |                           {error_type = 1; yyerror("");}

assign      : ASSIGN
            | '='                       {error_type = 7; yyerror("");}

%%

void load_var(long long n){
    long long type = num_check(n);
    if (type == 0){
        fprintf(yyout,"LOAD %lld\n",n);
    }
    else{
        fprintf(yyout,"LOADI %lld\n",n);
    }
}

void store_var(long long n){
    long long type = num_check(n);
    if (type == 0){
        fprintf(yyout,"STORE %lld\n",n);
    }
    else{
        fprintf(yyout,"STOREI %lld\n",n);
    }
}

void add_var(long long n){
    long long type = num_check(n);
    if (type == 0){
        fprintf(yyout,"ADD %lld\n",n);
    }
    else{
        fprintf(yyout,"ADDI %lld\n",n);
    }
}

void sub_var(long long n){
    long long type = num_check(n);
    if (type == 0){
        fprintf(yyout,"SUB %lld\n",n);
    }
    else{
        fprintf(yyout,"SUBI %lld\n",n);
    }
}

void write_var(long long *x){
    if (x[0]==0){
        fprintf(yyout,"SET %lld\n",x[1]);
        fprintf(yyout,"PUT 0\n");
    }
    else{
        long long type = num_check(x[1]);
        if (type == 0){
            fprintf(yyout,"PUT %lld\n",x[1]);
        }
        else{
            fprintf(yyout,"LOADI %lld\n",x[1]);
            fprintf(yyout,"PUT 0\n");
        }
    }
}

void handle_addition(long long *x, long long *y){
    if (x[0]==1 && y[0] == 1){
        load_var(x[1]);
        add_var(y[1]);
    }
    else if (x[0]==0 && y[0] == 0){
        if ((x[1] > 0 && y[1] > LLONG_MAX - x[1]) || (x[1] < 0 && y[1] < LLONG_MIN - x[1])){
            fprintf(yyout,"SET %lld\n",x[1]);
            fprintf(yyout,"STORE $+1\n");
            fprintf(yyout,"SET %lld\n",y[1]);
            fprintf(yyout,"ADD $+1\n");
        }
        else{
            fprintf(yyout,"SET %lld\n",x[1]+y[1]);
        }
    }
    else if (x[0] == 0){
        fprintf(yyout,"SET %lld\n",x[1]);
        add_var(y[1]);
    }
    else{
        fprintf(yyout,"SET %lld\n",y[1]);
        add_var(x[1]);
    }
}

void handle_subtraction(long long *x, long long *y){
    if (x[0]==1 && y[0] == 1){
        load_var(x[1]);
        sub_var(y[1]);
    }
    else if (x[0]==0 && y[0] == 0){
        if ((x[1] < 0 && y[1] > LLONG_MAX + x[1]) || (x[1] > 0 && y[1] < LLONG_MIN + x[1])){
            fprintf(yyout,"SET %lld\n",y[1]);
            fprintf(yyout,"STORE $+1\n");
            fprintf(yyout,"SET %lld\n",x[1]);
            fprintf(yyout,"SUB $+1\n");
        }
        else{
            fprintf(yyout,"SET %lld\n",x[1]-y[1]);
        }
    }
    else if (x[0] == 0){
        fprintf(yyout,"SET %lld\n",x[1]);
        sub_var(y[1]);
    }
    else{
        fprintf(yyout,"SET %lld\n",-y[1]);
        add_var(x[1]);
    }
}

void handle_multiplication(long long *x, long long *y){
    if ((x[0]==0 && y[0] == 0) && !((x[1] > 0 && (y[1] > LLONG_MAX / x[1] || y[1] < LLONG_MIN / x[1])) || (x[1] < 0 && (y[1] < LLONG_MAX / x[1] || y[1] > LLONG_MIN / x[1])))){
        fprintf(yyout,"SET %lld\n",x[1]*y[1]);
        return;
    }

    if (x[0] == 0){
        fprintf(yyout,"SET %lld\n",x[1]);}
    else {
        load_var(x[1]);}
    fprintf(yyout,"STORE $+1\n");
    x[1] = variable_count+1;
    fprintf(yyout,"STORE $+4\n");
    fprintf(yyout,"JPOS 7\n");
    fprintf(yyout,"SUB $+1\n");
    fprintf(yyout,"SUB $+1\n");
    fprintf(yyout,"STORE $+1\n");
    fprintf(yyout,"STORE $+4\n");
    fprintf(yyout,"SET 1\n");
    fprintf(yyout,"JUMP 2\n");
    fprintf(yyout,"SET 0\n");
    fprintf(yyout,"STORE $+5\n");

    if (y[0] == 0){
        fprintf(yyout,"SET %lld\n",y[1]);}
    else {
        load_var(y[1]);}
    fprintf(yyout,"STORE $+2\n");
    y[1] = variable_count+2;
    fprintf(yyout,"JPOS 7\n");
    fprintf(yyout,"SUB $+2\n");
    fprintf(yyout,"SUB $+2\n");
    fprintf(yyout,"STORE $+2\n");
    fprintf(yyout,"SET -1\n");
    fprintf(yyout,"ADD $+5\n");
    fprintf(yyout,"STORE $+5\n");

    fprintf(yyout,"SET 0\n");
    fprintf(yyout,"STORE $+3\n");

    fprintf(yyout,"LOAD %lld\n",y[1]);
    fprintf(yyout,"LOAD $+2\n");
    fprintf(yyout,"JZERO 20\n");

    fprintf(yyout,"LOAD $+2\n");
    fprintf(yyout,"HALF\n");
    fprintf(yyout,"ADD 0\n");
    fprintf(yyout,"SUB $+2\n");
    fprintf(yyout,"JZERO 8\n");
    fprintf(yyout,"LOAD $+3\n");
    fprintf(yyout,"ADD $+4\n");
    fprintf(yyout,"STORE $+3\n");
    fprintf(yyout,"SET -1\n");
    fprintf(yyout,"ADD $+2\n");
    fprintf(yyout,"STORE $+2\n");
    fprintf(yyout,"JUMP 7\n");
    fprintf(yyout,"LOAD $+4\n");
    fprintf(yyout,"ADD $+4\n");
    fprintf(yyout,"STORE $+4\n");
    fprintf(yyout,"LOAD $+2\n");
    fprintf(yyout,"HALF\n");
    fprintf(yyout,"STORE $+2\n");

    fprintf(yyout,"JUMP -20\n");

    fprintf(yyout,"LOAD $+5\n");
    fprintf(yyout,"JZERO 4\n");
    fprintf(yyout,"SET 0\n");
    fprintf(yyout,"SUB $+3\n");
    fprintf(yyout,"JUMP 2\n");
    fprintf(yyout,"LOAD $+3\n");
}

void handle_division(long long *x, long long *y){
    if(y[1] == 0){
        fprintf(yyout,"SET 0\n");
        return;
    }
    if (x[0]==0 && y[0] == 0){
        fprintf(yyout,"SET %lld\n",x[1]/y[1]);
        return;
    } 

    if (x[0] == 0){
        fprintf(yyout,"SET %lld\n",x[1]);}
    else {
        load_var(x[1]);}
    x[1] = variable_count+1;
    fprintf(yyout,"STORE $+1\n");
    fprintf(yyout,"JPOS 6\n");
    fprintf(yyout,"SUB $+1\n");
    fprintf(yyout,"SUB $+1\n");
    fprintf(yyout,"STORE $+1\n");
    fprintf(yyout,"SET 1\n");
    fprintf(yyout,"JUMP 2\n");
    fprintf(yyout,"SET 0\n");
    fprintf(yyout,"STORE $+6\n");

    if (y[0] == 0){
        fprintf(yyout,"SET %lld\n",y[1]);}
    else {
        load_var(y[1]);}
    y[1] = variable_count+2;
    fprintf(yyout,"JZERO 49\n");
    fprintf(yyout,"STORE $+2\n");
    fprintf(yyout,"JPOS 7\n");
    fprintf(yyout,"SUB $+2\n");
    fprintf(yyout,"SUB $+2\n");
    fprintf(yyout,"STORE $+2\n");
    fprintf(yyout,"SET -1\n");
    fprintf(yyout,"ADD $+6\n");
    fprintf(yyout,"STORE $+6\n");

    fprintf(yyout,"SET 0\n");
    fprintf(yyout,"STORE $+3\n");
    fprintf(yyout,"SET 1\n");
    fprintf(yyout,"STORE $+4\n");
    fprintf(yyout,"LOAD $+2\n");
    fprintf(yyout,"STORE $+5\n");
    
    fprintf(yyout,"LOAD $+1\n");
    fprintf(yyout,"SUB $+2\n");
    fprintf(yyout,"JNEG 22\n");

    fprintf(yyout,"LOAD $+5\n");
    fprintf(yyout,"ADD $+5\n");
    fprintf(yyout,"SUB $+1\n");
    fprintf(yyout,"JPOS 7\n");

    fprintf(yyout,"ADD $+1\n");
    fprintf(yyout,"STORE $+5\n");
    fprintf(yyout,"LOAD $+4\n");
    fprintf(yyout,"ADD $+4\n");
    fprintf(yyout,"STORE $+4\n");
    fprintf(yyout,"JUMP 11\n");

    fprintf(yyout,"LOAD $+1\n");
    fprintf(yyout,"SUB $+5\n");
    fprintf(yyout,"STORE $+1\n");
    fprintf(yyout,"LOAD $+2\n");
    fprintf(yyout,"STORE $+5\n");
    fprintf(yyout,"LOAD $+4\n");
    fprintf(yyout,"ADD $+3\n");
    fprintf(yyout,"STORE $+3\n");
    fprintf(yyout,"SET 1\n");
    fprintf(yyout,"STORE $+4\n");

    fprintf(yyout,"JUMP -23\n");

    fprintf(yyout,"LOAD $+6\n");
    fprintf(yyout,"JZERO 8\n");
    fprintf(yyout,"LOAD $+1\n");
    fprintf(yyout,"JZERO 3\n");
    fprintf(yyout,"SET -1\n");
    fprintf(yyout,"JUMP 2\n");
    fprintf(yyout,"SET 0\n");
    fprintf(yyout,"SUB $+3\n");
    fprintf(yyout,"JUMP 2\n");
    fprintf(yyout,"LOAD $+3\n");
}

void handle_modulo(long long *x, long long *y){
    if(y[1] == 0){
        fprintf(yyout,"SET 0\n");
        return;
    }
    if (x[0]==0 && y[0] == 0){
        long long res = x[1]%y[1];
        if (x[1]*y[1]<0){
            res += y[1];
        }
        fprintf(yyout,"SET %lld\n",res);
        return;
    } 

    long long a = variable_count+3;
    long long flag = variable_count+4;
    long long flag2 = variable_count+5;
    if (x[0] == 0){
        fprintf(yyout,"SET %lld\n",x[1]);}
    else {
        load_var(x[1]);}
    x[1] = variable_count+1;
    fprintf(yyout,"STORE $+1\n");
    fprintf(yyout,"JPOS 6\n");
    fprintf(yyout,"SUB $+1\n");
    fprintf(yyout,"SUB $+1\n");
    fprintf(yyout,"STORE $+1\n");
    fprintf(yyout,"SET -1\n");
    fprintf(yyout,"JUMP 2\n");
    fprintf(yyout,"SET 0\n");
    fprintf(yyout,"STORE $+4\n");
    fprintf(yyout,"STORE $+5\n");

    if (y[0] == 0){
        fprintf(yyout,"SET %lld\n",y[1]);}
    else {
        load_var(y[1]);}
    y[1] = variable_count+2;
    fprintf(yyout,"JZERO 41\n");
    fprintf(yyout,"STORE $+2\n");
    fprintf(yyout,"JPOS 8\n");
    fprintf(yyout,"SUB $+2\n");
    fprintf(yyout,"SUB $+2\n");
    fprintf(yyout,"STORE $+2\n");
    fprintf(yyout,"SET 1\n");
    fprintf(yyout,"STORE $+5\n");
    fprintf(yyout,"ADD $+4\n");
    fprintf(yyout,"STORE $+4\n");

    fprintf(yyout,"LOAD $+2\n");
    fprintf(yyout,"STORE $+3\n");
    
    fprintf(yyout,"LOAD $+1\n");
    fprintf(yyout,"SUB $+2\n");
    fprintf(yyout,"JNEG 14\n");

    fprintf(yyout,"LOAD $+3\n");
    fprintf(yyout,"ADD $+3\n");
    fprintf(yyout,"SUB $+1\n");
    fprintf(yyout,"JPOS 4\n");

    fprintf(yyout,"ADD $+1\n");
    fprintf(yyout,"STORE $+3\n");
    fprintf(yyout,"JUMP 6\n");

    fprintf(yyout,"LOAD $+1\n");
    fprintf(yyout,"SUB $+3\n");
    fprintf(yyout,"STORE $+1\n");
    fprintf(yyout,"LOAD $+2\n");
    fprintf(yyout,"STORE $+3\n");

    fprintf(yyout,"JUMP -15\n");

    fprintf(yyout,"LOAD $+4\n");
    fprintf(yyout,"JZERO 4\n");
    fprintf(yyout,"LOAD $+2\n");
    fprintf(yyout,"SUB $+1\n");
    fprintf(yyout,"STORE $+1\n");

    fprintf(yyout,"LOAD $+5\n");
    fprintf(yyout,"JPOS 3\n");
    fprintf(yyout,"LOAD $+1\n");
    fprintf(yyout,"JUMP 4\n");
    fprintf(yyout,"LOAD $+1\n");
    fprintf(yyout,"SUB $+1\n");
    fprintf(yyout,"SUB $+1\n");
}

void handle_compare(long long *x, long long *y, long long type){
    if (loop_type == 1){
        fprintf(yyout,"WHILESTART ");
    }
    else if (loop_type == 3){
        fprintf(yyout,"FORSTART ");
    }

    if (x[0]==1 && y[0] == 1){
        load_var(x[1]);
        sub_var(y[1]);
    }
    else if (x[0]==0 && y[0] == 0){
        fprintf(yyout,"SET %lld\n",x[1]-y[1]);
    }
    else if (x[0] == 0){
        fprintf(yyout,"SET %lld\n",x[1]);
        sub_var(y[1]);
    }
    else{
        fprintf(yyout,"SET %lld\n",-y[1]);
        add_var(x[1]);
    }

    if (type == 0){
        fprintf(yyout,"JZERO 2\n");
        fprintf(yyout,"JUMP ");
    }
    else if (type == 1){
        fprintf(yyout,"JNEG 2\n");
        fprintf(yyout,"JUMP ");
    }
    else if (type == 2){
        fprintf(yyout,"JPOS 2\n");
        fprintf(yyout,"JUMP ");
    }
    else if (type == 3){
        fprintf(yyout,"JZERO ");
    }
    else if (type == 4){
        fprintf(yyout,"JPOS ");
    }
    else if (type == 5){
        fprintf(yyout,"JNEG ");
    }

    if (loop_type == 0){
        fprintf(yyout,"IFEND\n");
    }
    else if (loop_type == 1){
        fprintf(yyout,"WHILEEND\n");
    }
    else if (loop_type == 2){
        fprintf(yyout,"UNTILSTART\n");
    }
    else if (loop_type == 3){
        fprintf(yyout,"FOREND\n");
    }
}

void start_for(long long *x, long long *y, long long i, long long type){
    if (x[0] == 0 && y[0] == 0){
        if (type == 0 && x[1]>y[1]){
            error_type = 13;
            yyerror("");
        }
        else if(type == 1 && x[1]<y[1]){
            error_type = 13;
            yyerror("");
        }
    }
    
    if (x[0] == 0){
        fprintf(yyout,"SET %lld\n",x[1]);
    }
    else{
        load_var(x[1]);
    }
    x[0] = 1;
    x[1] = i;
    fprintf(yyout,"STORE %lld\n",i);

    if (y[0] == 0){
        fprintf(yyout,"SET %lld\n",y[1]);
    }
    else{
        load_var(y[1]);
    }
    y[0] = 1;
    y[1] = i+1;
    fprintf(yyout,"STORE %lld\n",i+1);

    if (type == 0){
        handle_compare(x,y,4);
    }
    else{
        handle_compare(x,y,5);
    }
}

void end_for(long long *i){
    if (i[0] == 0){
        fprintf(yyout,"SET 1\n");
    }
    else{
        fprintf(yyout,"SET -1\n");
    }
    fprintf(yyout,"ADD %lld\n",i[1]);
    fprintf(yyout,"STORE %lld\n",i[1]);
    fprintf(yyout,"FOREND JUMP FORSTART\n");

    symbol *ptr;
    if (sym_table->num == i[1]+1){
        sym_table = sym_table->next->next;
    }
    else{
        for (ptr = sym_table; ptr->next->num != i[1]+1; ptr = (symbol *)ptr->next){}
        ptr->next = ptr->next->next->next;
    }
    if (sym_table != NULL){
        variable_count = sym_table->num;
    }
}

void add_argument(char *name){
    long long pos = sym_check(name);
    long long type = num_check(pos);
    if (type == 0){
        fprintf(yyout,"SET %lld\n",pos);
    }
    else{
        fprintf(yyout,"LOAD %lld\n",pos);
    }

    type = num_check(fun_loc+arg_count);
    if (type != 1 && type != 2){
        error_type = 10;
        yyerror(current_function);
    }
    if (type == 1){
        type_check(name,0);
    }
    if (type == 2){
        type_check(name,1);
    }

    fprintf(yyout,"STORE %lld\n",fun_loc+arg_count);
    arg_count+=1;
}

int yyerror(char *name){
    if (error_type == 1){
        printf("ERROR line %d: missing ;\n",linenum-1);
    }
    else if(error_type == 2){
        printf("ERROR line %d: %s is undeclared\n",linenum,name);
    }
    else if(error_type == 3){
        printf("ERROR line %d: multiple declarations of %s\n",linenum,name);
    }
    else if(error_type == 4){
        printf("ERROR line %d: array %s has invalid range\n",linenum,name);
    }
    else if(error_type == 5){
        printf("ERROR line %d: invalid use of array %s\n",linenum,name);
    }
    else if(error_type == 6){
        printf("ERROR line %d: %s is not an array\n",linenum,name);
    }
    else if(error_type == 7){
        printf("ERROR line %d: = can't be used for assignment\n",linenum);
    }
    else if(error_type == 8){
        printf("ERROR line %d: calling undeclared procedure %s\n",linenum,name);
    }
    else if(error_type == 9){
        printf("ERROR line %d: attempted recursion in %s\n",linenum,name);
    }
    else if(error_type == 10){
        printf("ERROR line %d: too many arguments for function %s\n",linenum,name);
    }
    else if(error_type == 11){
        printf("ERROR line %d: not enough arguments for function %s\n",linenum,name);
    }
    else if(error_type == 12){
        printf("ERROR line %d: incorrect type for function %s\n",linenum,name);
    }
    else if(error_type == 13){
        printf("ERROR line %d: incorrect for loop iterator bounds\n",linenum);
    }
    else if(error_type == 14){
        printf("ERROR line %d: attempting to access array %s out of bounds\n",linenum,name);
    }
    else if(error_type == 15){
        printf("ERROR line %d: %s is not initialised\n",linenum,name);
    }
    else if(error_type == 16){
        printf("ERROR line %d: attempting to modify for loop iterator %s\n",linenum,name);
    }
    exit(1);
}

long long main(int argc, char *argv[])
{
    yyout = fopen("temp1.mr","w");
    yyin = fopen(argv[1], "r");
    yyparse();
    fclose(yyin);
	fclose(yyout);
    return 0;
}