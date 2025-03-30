Kompilator kompilujący język opisywany gramatyką z pliku grammar.txt na kod maszyny rejestrowej.  \

Dodatkowe wymagania języka:
- Tablice indeksowane są od dowolnych wartości  
- Ilość wykonań pętli jest ustalana przed pierwszym wykonaniem pętli  
- Kompilator przyjmuje dowolne 64-bitowe liczby całkowite  
- Podczas obliczeń mogą powstawać dowolnie duże liczby  
- Dzielenie jest całkowite i zaokrąglane w górę  
- Rekurencja nie jest dozwolona  
- Parametry funkcji są typu IN-OUT  

Kompilacja: make all

Użycie: python3 compiler.py <nazwa pliku wejściowego> <nazwa pliku wyjściowego>

Wymagane narzędzia:
- flex  
- bison

Pliki:
- parser.y - główny parser  
- lexer.l - główny lexer  
- label_parser.y - parser etykiet  
- label_lexer.l - lexer etykiet  
- compiler.py - program wywołujący elementy kompilatora