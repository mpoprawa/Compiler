import sys
import os

def get_labels():
    labels = []
    arguments = []
    call = []
    calls = []
    last_called = ""
    last_line = 0

    for line in open("labels.txt",'r').readlines():
        split_line = line.split(" ")
        if split_line[1] == "RTRN":
            labels.append([split_line[0],split_line[2]])
        elif split_line[0] == "HALT":
            mx = int(split_line[1])
        elif split_line[0][0:3] == "FN$":
            func = []
            for i in split_line:
                if i != "[" and i != "]" and i != "\n":
                    func.append(i)
            arguments.append(func)
        elif split_line[1] == "STORE":
            name = split_line[2].strip()
            line = int(split_line[0])
            if last_called == "":
                call.append(name)
                call.append(line)
                last_called = name
                last_line = line
            elif name != last_called or line != last_line+2:
                calls.append(call)
                call = []
                call.append(name)
                call.append(line)
                last_called = name
                last_line = line
            else:
                last_line = line
                call.append(line)
        else:
            labels.append(split_line)

    if call:
        calls.append(call)
        for c in calls:
            for a in arguments:
                if c[0] == a[0]:
                    for i in range(1,len(c)):
                        labels.append([c[i],a[i]+"\n"])
                    break
    return labels,mx

def set_labels(labels,mx,source_file,result_file):
    for l in labels:
        l[0] = int(l[0])
    labels = sorted(labels, key=lambda x: x[0])

    for i in range(len(source_file)):
        if labels  and i == labels[0][0]:
            label = labels[0][1]
            if label[0:1] == "$":
                num = label[2:]
                num = int(num)+mx
                line = source_file[i].strip()+" "+str(num)+"\n"
            else:
                line = source_file[i].strip()+" "+label
            if i!=0 or line != "JUMP 1\n": 
                result_file.write(line)
            labels.pop(0)
        else:
            result_file.write(source_file[i])

os.system("./compiler "+sys.argv[1])
os.system("./labels")

source_file = open("temp2.mr",'r').readlines()
result_file = open(sys.argv[2],'w')

labels,mx = get_labels()
set_labels(labels,mx,source_file,result_file)

os.system("rm -f temp1.mr temp2.mr labels.txt")