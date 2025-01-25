import sys
import os

def get_labels():
    labels = []

    for line in open("labels.txt",'r').readlines():
        split_line = line.split(" ")
        if split_line[0] == "HALT":
            mx = int(split_line[1])
        else:
            labels.append(split_line)

    return labels,mx

def set_labels(labels,mx,source_file,result_file):
    for l in labels:
        l[0] = int(l[0])
    labels = sorted(labels, key=lambda x: x[0])

    for i in range(len(source_file)):
        if labels  and i == labels[0][0]:
            label = labels[0][1]
            if label[0] == "$":
                num = label[2]
                num = int(num)+mx
                line = source_file[i].strip()+" "+str(num)+"\n"
            else:
                line = source_file[i].strip()+" "+label
            if i!=0 or line != "JUMP 1\n": 
                result_file.write(line)
            labels.pop(0)
        else:
            result_file.write(source_file[i])

def check_errors(output):
    if output == "done\n":
        return
    else:
        print(output,end="")
        os.system("rm -f temp1.mr temp2.mr labels.txt")
        sys.exit(0)

parser_output_1 = os.popen("./compiler "+sys.argv[1]).read()
check_errors(parser_output_1)

parser_output_2 = os.popen("./labels").read()
check_errors(parser_output_2)

source_file = open("temp2.mr",'r').readlines()
result_file = open(sys.argv[2],'w')

labels,mx = get_labels()
set_labels(labels,mx,source_file,result_file)

os.system("rm -f temp1.mr temp2.mr labels.txt")
print("Compilation Succesful")