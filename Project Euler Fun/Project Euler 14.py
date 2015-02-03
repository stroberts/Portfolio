"""Samuel R, 2/3/15"""
"""Thoughts:
1. Make a quick, basic Collatz, just for fun, but
2. Once a better Collatz fn gets to a number whose sequence is already known, that can terminate
3. What's more, we only need or want the length of the sequence
Hence, what we'll do is set up a dict, with sequence lengths for numbers already obtained.
Then the better Collatz will first check that key of the dict, if it returns a length, then solved, else iterate then again"""
#from time import clock #when I was looking for the fastest isEven() approach - see bottom
from random import shuffle


def CollatzBasic(start,count=0,prev=''):
    "This is a basic recursive Callatz sequencer - it doesn't check if a thing's been done"
    if start%2==0:
        return CollatzBasic(start/2,count+1,prev+str(start)+',')
    elif start==1:
        return 1,count,prev+'1'
    else:
        return CollatzBasic(3*start+1,count+1,prev+str(start)+',')
    #return





#CollatzLengths=dict()
#CollatzLengths[1]=0
CollatzLengths={2**x: x for x in range(14)}

def Collatz(start,count=0):
    "This smarted Collatz sequence iterator allows a much faster evaluation, in concert with a dict"
    """try:
        CollatzLengths
    except NameError:
        global CollatzLengths
        CollatzLengths={2**x: x for x in range(14)}
    """
    #print(str(start)+', '+str(count))
    try:
        count = count+CollatzLengths[start]
    except KeyError:
        if start%2==0:
            count = Collatz(start/2,count)+1
        else:
            count = Collatz(3*start +1,count)+1
        #print(count)
        CollatzLengths[start] = count
    return count




def main():
    (l,h) = input("What range do you want to investigate (as low,high) ")    
    #r=range(3,1000000+1)
    r=range(l,h+1)
    shuffle(r)
    maxlen=0
    whomax=0
    for c in r:
        clen = Collatz(c)
        if clen>maxlen:
            maxlen,whomax = clen,c
    #print(str(maxlen)+', '+str(whomax))
    return maxlen,whomax


if __name__ == "__main__":
    print(main())




#Here I wanted to look for an easy/fastest 
"""for x in range(10000000000000000000000000000000000000000000000000000000000,10000000000000000000000000000000000000000000000000000000010):
    print(x)
    print(bin(x))
    print(bin(x)[-1])
    print(x & 1)

print("x & 1")
s = clock()
for x in range(10000000000000000000000000000000000000000000000000000000000,10000000000000000000000000000000000000000000000000000000010):
    x & 1
e=clock()-s
print(e)
#6.37203897977e-05

print("x%2")
s = clock()
for x in range(10000000000000000000000000000000000000000000000000000000000,10000000000000000000000000000000000000000000000000000000010):
    x%2
e=clock()-s
print(e)"""
#Conclusion is that mod is twice as fast
