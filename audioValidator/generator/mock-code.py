#############################################
#
#
# Source:
#  https://raw.githubusercontent.com/vxunderground/MalwareSourceCode/main/Java/Virus.Java.Cheshire.a/src/main/java/SelfExamine.java
# 
#############################################

# import modules


# Read data
with open("goat-java.txt", "r") as f:
    data = f.readlines()
f.close()

# N records = 70k
mockSignal = [ ]
for line in data:
    for char in line.replace('\n', ''):
        mockSignal.append(ord(char))

# Revert
chars = []
for i in mockSignal:
    chars.append(chr(int(i)))

# Join
''.join(chars)