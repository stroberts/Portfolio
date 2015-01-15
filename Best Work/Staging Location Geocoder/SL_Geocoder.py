import geopy
import csv


addresses=[]
zips=set()
rd2=set() #this is where we'll keep track of what addresses we need to rerun
#This is a csv of the excel file containing addresses of interest
'''one=raw_input('Where is the file w/addresses and zips?\\\
(include full directory)-->')
#C:/Users/Samuel R/Desktop/SLs(nogeo).csv at present
with open(one,'rb') as f:''' #for interactive
with open('C:/Users/Samuel R/Desktop/10_2SLs.csv','rb') as f: #for non-interactive
	reader=csv.reader(f)
	for row in reader:
                #zips and addresses are in these respecitve locations
		addresses.append(row[0])
		#zips.add(row[3])
		rd2.add(row[0])
		'''
with open('C:/Users/Samuel R/Desktop/10_2SLs.csv','rb') as f: #for non-interactive
	reader=csv.reader(f)
	for line in reader:
                #zips and addresses are in these respecitve locations
		addresses.append(','.join(line))'''

#print addresses     

g=geopy.geocoders.GoogleV3() #since van seems to hook up with google maps,
#we'll use their geocoder
SLs=[] #our list of SL locations, either address or zip, followed by lat and lng
for i in range(len(addresses)):
    try:
        try:
                place, (lat,lng)=g.geocode(addresses[i])
                SLs.append([place,lat,lng,addresses[i]])#we keep the original to address match errors in excel
                #print place #to keep track
                rd2.discard(addresses[i])
        except GQueryError:
                pass
    except NameError:
            #print addresses[i] #to keep track
            pass
print "rd 1 addresses geocoded"
print rd2
p=list(rd2)
for i in p:
        try:
                try:
                        place, (lat,lng)=g.geocode(i)
                        SLs.append([place,lat,lng,i])#we keep the original to address match errors in excel
                        rd2.discard(i)
                        #print place
                except GQueryError:
                        pass
        except NameError:
                #print i #again to keep track
                pass

print "remainder of undone places is"
print rd2
#we also have the census list of zip codes and lat lng
'''two=raw_input('Where is the census zip to lat/lng table? \
              include full directory')
#(include full directory)--->')
#C:\Users\Samuel R\Downloads\Gaz_zcta_national\Gaz_zcta_national.txt at present
with open(two,'rb') as f:'''
'''with open('C:\Users\Samuel R\Downloads\Gaz_zcta_national\Gaz_zcta_national.txt','rb') as f:
        reader=csv.reader(f,'excel-tab')
        for row in reader:
                if row[0] in zips:
                        SLs.append([row[0],row[7],row[8]])
                        zips.remove(row[0])'''

'''p=list(zips)
print zips
for i in p:
        try:
                try:
                        place, (lat,lng)=g.geocode(i)
                        SLs.append([i,lat,lng,'non-census'])#we keep the original to address match errors in excel
                        zips.discard(i)
                        #print place
                except GQueryError:
                        pass
        except NameError:
                #print i #again to keep track
                pass

print 'zips imported'
print zips'''

'''three=raw_input('Where are we writing this thing?(include .csv)-->')
#SLsOut.csv at present              
with open(three,'wb') as b:'''
with open('C:\Users\Samuel R\Desktop\SLLocs10_2.csv','wb') as b:
        writer=csv.writer(b)
        for i in range(len(SLs)):
                #r=SLs[key].append(key)
                writer.writerow(SLs[i])

print "file written"

