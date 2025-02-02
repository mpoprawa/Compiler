import os

for i in range(1,11):
    os.system("python3 compiler.py testy/example"+str(i)+".imp ex.mr")

    if i == 1:
        print("input: 20 33")
    elif i == 2:
        print("input: 0 1")
    elif i == 3:
        print("input: 1")
    elif i == 4:
        print("input: 20 9")
    elif i == 5:
        print("input: 1234567890 1234567890987654321 987654321")
    elif i == 6:
        print("input: 20")
    elif i == 7:
        print("input: 1 0 2")
    elif i == 8:
        input()
    elif i == 9:
        print("input: 20 9")
    elif i == 10:
        input()
    
    os.system("./maszyna_wirtualna/maszyna-wirtualna ex.mr")

    if i == 1:
        print("output: 5 3 1")
    elif i == 2:
        print("output: 46368 28657")
    elif i == 3:
        print("output: 121393")
    elif i == 4:
        print("output: 167960")
    elif i == 5:
        print("output: 674106858")
    elif i == 6:
        print("output: 2432902008176640000 6765")
    elif i == 7:
        print("output: 31001 40900 2222012")
    elif i == 8:
        print("output: 1:22")
    elif i == 9:
        print("output: 167960")
    elif i == 10:
        input()

for i in range(1,9):
    os.system("python3 compiler.py testy/error"+str(i)+".imp ex.mr")