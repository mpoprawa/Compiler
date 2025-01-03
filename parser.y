%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
int yylex();
int yyerror(char*);
extern FILE *yyin;
extern FILE *yyout;

int variable_count = 1;
int max_count = 1;
int loop_type; /*0-IF 1-WHILE 2-UNTIL 3=FOR*/
char* current_scope = "main";
char* current_function = "main";
struct symbol
{
    int num;
    int end;
    int type;
    char *name;
    char *scope;
    struct symbol *next;
};
typedef struct symbol symbol;
symbol *sym_table = NULL;

void  insert_sym(char *sym_name, int type, int start, int end){
    int len = end-start;
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
    ptr->end = variable_count-1;
    ptr->type = type;
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
void declare(char *sym_name, int type){ /*0-zmienna 1-argument*/
    symbol *s;
    s =  get_sym(sym_name);
    if (s == NULL || sym_name == "for_limit" || sym_name == "array_adr")
        insert_sym(sym_name, type, 0, 0);
    else {
        printf( "%s is already defined\n", sym_name );
    }
}
void declare_array(char *sym_name, int type, int start, int end){
    symbol *s;
    s =  get_sym(sym_name);
    if (s == NULL || sym_name == "for_limit")
        insert_sym(sym_name, type, start, end);
    else {
        printf( "%s is already defined\n", sym_name );
    }
}
int sym_check(char *sym_name){
    symbol *sym =  get_sym(sym_name);
    if (sym == NULL){
        printf( "%s is an undeclared identifier\n", sym_name );
        return 0;
    }
    else{
        return sym->num;
    }
}
int num_check(int i){
    symbol *ptr;
    for (ptr = sym_table; ptr != NULL; ptr = (symbol *)ptr->next){
        if (ptr->num == i){
            return ptr->type;
        }
    }
}
void print_sym_table(){
    symbol *ptr;
    for (ptr = sym_table; ptr != NULL; ptr = (symbol *)ptr->next){
        printf("%s %d type %d starts at %d ends at %d in %s\n",ptr->name,ptr->num,ptr->type,ptr->num,ptr->end,ptr->scope);
    }
}

void load_var(int);
void store_var(int);
void add_var(int);
void sub_var(int);
void write_var(int*);
void handle_addition(int*,int*);
void handle_subtraction(int*,int*);
void handle_multiplication(int*,int*);
void handle_division(int*,int*);
void handle_modulo(int*,int*);
void handle_compare(int*,int*,int);
void start_for(int*,int*,int,int);
void end_for(int*);
void add_argument(char*);
%}

%union {
        int pair[2];
        int num;
        char* str;
    }
%token PROCEDURE PROGRAM IS BEGIN_T END
%token WRITE READ IF THEN ELSE ENDIF WHILE ENDWHILE REPEAT UNTIL FOR FROM TO DOWNTO DO ENDFOR
%token ASSIGN N_EQUAL L_EQUAL G_EQUAL
%token <num> number
%token <str> pidentifier

%left '+' '-'
%left '*' '/' '%'

%type <num> identifier val
%type <str> prefunc
%type <pair> value for 

%%
program_all : procedures main {printf("done 1\n"); fprintf(yyout,"HALT %d",max_count);}

procedures  : procedures PROCEDURE proc_head IS declarations BEGIN_T commands END   {fprintf(yyout,"RTRN %d\n",sym_check("return")); variable_count = max_count;}
            | procedures PROCEDURE proc_head IS BEGIN_T commands END                {fprintf(yyout,"RTRN %d\n",sym_check("return")); variable_count = max_count;}
            |

proc_head   : fidentifier '(' args_decl ')'                                         {fprintf(yyout,"] ");}

fidentifier : pidentifier                                                           {fprintf(yyout,"FUN$_%s_$FUN FN$_%s_$FN [ ",$1,$1); current_scope = $1; declare("return",0);}                                         

args_decl   : args_decl ',' pidentifier                                             {declare($3,1); fprintf(yyout,"%d ",sym_check($3));}
            | pidentifier                                                           {declare($1,1); fprintf(yyout,"%d ",sym_check($1));}
            | args_decl ',' 'T' pidentifier                                         {declare($4,1); fprintf(yyout,"%d ",sym_check($4));}
            | 'T' pidentifier                                                       {declare($2,1); fprintf(yyout,"%d ",sym_check($2));}
            |

main        : premain PROGRAM IS declarations temp BEGIN_T commands END
            | premain PROGRAM IS BEGIN_T commands END

temp        : {print_sym_table();}

declarations: declarations ',' pidentifier                              {declare($3,0);}
            | pidentifier                                               {declare($1,0);}
            | declarations ',' pidentifier '[' val ':' val ']'          {declare_array($3,0,$5,$7); int pos = sym_check($3);
                                                                        fprintf(yyout,"SET %d\n",pos-$5+1); fprintf(yyout,"STORE %d\n",pos);}
            | pidentifier '[' val ':' val ']'                           {declare_array($1,0,$3,$5); int pos = sym_check($1);
                                                                        fprintf(yyout,"SET %d\n",pos-$3+1); fprintf(yyout,"STORE %d\n",pos);}

commands    : commands command
            | command

command     : identifier ASSIGN expression ';'                          {store_var($1);}
            | if IF condition THEN commands ENDIF                       {fprintf(yyout,"IFEND ");}
            | if IF condition THEN commands else ELSE commands ENDIF    {fprintf(yyout,"IFEND ");}
            | while WHILE condition DO commands ENDWHILE                {fprintf(yyout,"WHILEEND JUMP WHILESTART\n");}
            | repeat1 REPEAT commands repeat2 UNTIL condition ';'
            | FOR for commands ENDFOR                                   {end_for($2);}
            | proc_call ';'
            | WRITE value ';'                                           {write_var($2);}
            | READ identifier ';'                                       {fprintf(yyout,"GET %d\n",$2);}

premain     :                                                           {fprintf(yyout,"MAIN "); current_scope = "main";}
if          :                                                           {loop_type = 0;}
else        :                                                           {fprintf(yyout,"IFELSE "); fprintf(yyout,"JUMP IFEND\n");}
while       :                                                           {loop_type = 1;}
repeat1     :                                                           {fprintf(yyout,"UNTILSTART ");}
repeat2     :                                                           {loop_type = 2;}

for         : pidentifier FROM value TO value DO        {loop_type=3; declare($1,0); declare("for_limit",0); $$[0]=0; $$[1]=sym_check($1);
                                                        start_for($3,$5,$$[1],$$[0]);}
            | pidentifier FROM value DOWNTO value DO    {loop_type=3; declare($1,0); declare("for_limit",0); $$[0]=1; $$[1]=sym_check($1);
                                                        start_for($3,$5,$$[1],$$[0]);}

expression  : value                 {if ($1[0]==0){
                                        fprintf(yyout,"SET %d\n",$1[1]);}
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

identifier  : pidentifier                       {$$ = sym_check($1);}
            | pidentifier '[' val ']'           {int pos = sym_check($1); fprintf(yyout,"SET %d\n",$3); add_var(pos);
                                                 declare("array_adr",1  ); $$ = sym_check("array_adr"); fprintf(yyout,"STORE %d\n",$$);}
            | pidentifier '[' pidentifier ']'   {int pos = sym_check($1); load_var(sym_check($3)); add_var(pos);
                                                 declare("array_adr",1  ); $$ = sym_check("array_adr"); fprintf(yyout,"STORE %d\n",$$);}

proc_call   : prefunc '(' args ')'      {fprintf(yyout,"SET RETURN\n");
                                         fprintf(yyout,"STORE \n");
                                         fprintf(yyout,"JUMP FUN$_%s_$FUN\n",$1);}

args        : args ',' pidentifier      {add_argument($3);}
            | pidentifier               {add_argument($1);}

prefunc     : pidentifier               {current_function = $1;}

%%

void load_var(int n){
    int type = num_check(n);
    if (type == 0){
        fprintf(yyout,"LOAD %d\n",n);
    }
    else if (type == 1){
        fprintf(yyout,"LOADI %d\n",n);
    }
}

void store_var(int n){
    int type = num_check(n);
    if (type == 0){
        fprintf(yyout,"STORE %d\n",n);
    }
    else if (type == 1){
        fprintf(yyout,"STOREI %d\n",n);
    }
}

void add_var(int n){
    int type = num_check(n);
    if (type == 0){
        fprintf(yyout,"ADD %d\n",n);
    }
    else if (type == 1){
        fprintf(yyout,"ADDI %d\n",n);
    }
}

void sub_var(int n){
    int type = num_check(n);
    if (type == 0){
        fprintf(yyout,"SUB %d\n",n);
    }
    else if (type == 1){
        fprintf(yyout,"SUBI %d\n",n);
    }
}

void write_var(int *x){
    if (x[0]==0){
        fprintf(yyout,"SET %d\n",x[1]);
        fprintf(yyout,"PUT 0\n");
    }
    else{
        int type = num_check(x[1]);
        if (type == 0){
            fprintf(yyout,"PUT %d\n",x[1]);
        }
        else{
            fprintf(yyout,"LOADI %d\n",x[1]);
            fprintf(yyout,"PUT 0\n");
        }
    }
}

void handle_addition(int *x, int *y){
    if (x[0]==1 && y[0] == 1){
        load_var(x[1]);
        add_var(y[1]);
    }
    else if (x[0]==0 && y[0] == 0){
        fprintf(yyout,"SET %d\n",x[1]+y[1]);
    }
    else if (x[0] == 0){
        fprintf(yyout,"SET %d\n",x[1]);
        add_var(y[1]);
    }
    else{
        fprintf(yyout,"SET %d\n",y[1]);
        add_var(x[1]);
    }
}

void handle_subtraction(int *x, int *y){
    if (x[0]==1 && y[0] == 1){
        load_var(x[1]);
        sub_var(y[1]);
    }
    else if (x[0]==0 && y[0] == 0){
        fprintf(yyout,"SET %d\n",x[1]-y[1]);
    }
    else if (x[0] == 0){
        fprintf(yyout,"SET %d\n",x[1]);
        //fprintf(yyout,"SUB %d\n",y[1]);
        sub_var(y[1]);
    }
    else{
        fprintf(yyout,"SET %d\n",-y[1]);
        //fprintf(yyout,"ADD %d\n", x[1]);
        add_var(x[1]);
    }
}

void handle_multiplication(int *x, int *y){
    if (x[0]==0 && y[0] == 0){
        fprintf(yyout,"SET %d\n",x[1]*y[1]);
        return;
    }

    if (x[0] == 0){
        fprintf(yyout,"SET %d\n",x[1]);}
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
        fprintf(yyout,"SET %d\n",y[1]);}
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

    fprintf(yyout,"LOAD %d\n",y[1]);
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

void handle_division(int *x, int *y){
    if(y[1] == 0){
        fprintf(yyout,"SET 0\n");
        return;
    }
    if (x[0]==0 && y[0] == 0){
        fprintf(yyout,"SET %d\n",x[1]/y[1]);
        return;
    } 

    if (x[0] == 0){
        fprintf(yyout,"SET %d\n",x[1]);}
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
        fprintf(yyout,"SET %d\n",y[1]);}
    else {
        load_var(y[1]);}
    y[1] = variable_count+2;
    fprintf(yyout,"JZERO 47\n");
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
    fprintf(yyout,"JZERO 4\n");
    fprintf(yyout,"SET 0\n");
    fprintf(yyout,"SUB $+3\n");
    fprintf(yyout,"JUMP 2\n");
    fprintf(yyout,"LOAD $+3\n");
}

void handle_modulo(int *x, int *y){
    if(y[1] == 0){
        fprintf(yyout,"SET 0\n");
        return;
    }
    if (x[0]==0 && y[0] == 0){
        int res = x[1]%y[1];
        if (x[1]*y[1]<0){
            res += y[1];
        }
        fprintf(yyout,"SET %d\n",res);
        return;
    } 

    int a = variable_count+3;
    int flag = variable_count+4;
    int flag2 = variable_count+5;
    if (x[0] == 0){
        fprintf(yyout,"SET %d\n",x[1]);}
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
        fprintf(yyout,"SET %d\n",y[1]);}
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

void handle_compare(int *x, int *y, int type){
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
        fprintf(yyout,"SET %d\n",x[1]-y[1]);
    }
    else if (x[0] == 0){
        fprintf(yyout,"SET %d\n",x[1]);
        sub_var(y[1]);
    }
    else{
        fprintf(yyout,"SET %d\n",-y[1]);
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

void start_for(int *x, int *y, int i, int type){
    if (x[0] == 0){
        fprintf(yyout,"SET %d\n",x[1]);
    }
    else{
        load_var(x[1]);
        //fprintf(yyout,"LOAD %d\n",x[1]);
    }
    x[0] = 1;
    x[1] = i;
    fprintf(yyout,"STORE %d\n",i);

    if (y[0] == 0){
        fprintf(yyout,"SET %d\n",y[1]);
    }
    else{
        load_var(y[1]);
    }
    y[0] = 1;
    y[1] = i+1;
    fprintf(yyout,"STORE %d\n",i+1);

    if (type == 0){
        handle_compare(x,y,4);
    }
    else{
        handle_compare(x,y,5);
    }
}

void end_for(int *i){
    if (i[0] == 0){
        fprintf(yyout,"SET 1\n");
    }
    else{
        fprintf(yyout,"SET -1\n");
    }
    fprintf(yyout,"ADD %d\n",i[1]);
    fprintf(yyout,"STORE %d\n",i[1]);
    fprintf(yyout,"FOREND JUMP FORSTART\n");

    symbol *ptr;
    if (sym_table->num == i[1]+1){
        sym_table = sym_table->next->next;
    }
    else{
        for (ptr = sym_table; ptr->next->num != i[1]+1; ptr = (symbol *)ptr->next){}
        ptr->next = ptr->next->next->next;
    }

    /*for (ptr = sym_table; ptr != NULL; ptr = (symbol *)ptr->next){
        printf("%s %d\n",ptr->name,ptr->num);
    }*/
    variable_count = sym_table->num;
}

void add_argument(char *name){
    int pos = sym_check(name);
    int type = num_check(pos);
    if (type == 0){
        fprintf(yyout,"SET %d\n",pos);
    }
    else{
        fprintf(yyout,"LOAD %d\n",pos);
    }
    fprintf(yyout,"STORE FN$_%s_$FN\n",current_function);
}

int yyerror(char *s)
{
    return 0;
}

int main(int argc, char *argv[])
{
    yyout = fopen("temp1.mr","w");
    yyin = fopen(argv[1], "r");
    yyparse();
    fclose(yyin);
	fclose(yyout);
    return 0;
}