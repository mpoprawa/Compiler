all: compiler label

compiler: parser.y lexer.l
	bison -o parser.c -d parser.y
	flex -o lexer.c lexer.l
	gcc -o compiler parser.c lexer.c

label: label_parser.y label_lexer.l
	bison -o label_parser.c -d label_parser.y
	flex -o label_lexer.c label_lexer.l
	gcc -o labels label_parser.c label_lexer.c

clean:
	rm -f *.c *.h compiler labels

clean_results:
	rm -f *.mr