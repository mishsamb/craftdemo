#------------------------------- *.*-------------------------------
#
# => This program reconciles two csv files
# => Input taken from workday and oic
# => 	Steps to check:
# => 	1. Count of records from workday and oic
# => 	2. Duplicates (based on name/email id from wd/oic)
# => 	3. Incorrect/inconsistent data
# =>  	4. Join with name/email id
# =>    5. Build master data
#
#-------------------------------------------------------

require 'csv'

wdFile = "workday.csv"
ocFile = "oic.csv"

wdCsv = CSV.read(wdFile)
ocCsv = CSV.read(ocFile)

# puts wdCsv.inspect
# puts ocCsv.inspect

# generate names from email - e.g: Carissa Lyons from Carissa_Lyons@intuit.com
def generateNamesFromOc(fname, col)
	arr = []
	fname.each_with_index do |row,i|
		arr[i] = row[col-1].chomp.split('@')[0].to_s.gsub('_', ' ')
	end
	return arr
end

def generateNamesFromWd(fname, col)
	arr = []
	fname.each_with_index do |row, i|
		arr[i] = row[col-1].chomp
	end
	return arr
end


def getRecordCount(cname)
	# puts cname.inspect
	return cname.length.to_i

end


# find duplicates in array
def findDuplicates(arr)
	hsh = Hash.new{0}
	# iterate over the array, count duplicates
	arr.each do |v|
		hsh[v] += 1
	end
	hsh.each do |v, n|
		puts "#{v} appears #{n} times" if n > 1
	end
	# get uniq elements
	arr.uniq!

	return arr
end

def generateMasterRecord(wd, oc, fname)

	# generate name records from email
	nameArrOc = generateNamesFromOc(oc, 2)
	nameArrWd = generateNamesFromWd(wd, 2)

	puts "Processing workday..."
	nameUniqWd = findDuplicates(nameArrWd)
	puts "Number of unique records in workday: #{nameUniqWd.length}"

	puts "Processing oic..."
	nameUniqOc = findDuplicates(nameArrOc)
	puts "Number of unique records in OIC: #{nameUniqOc.length}"

	# create hash workday
    hshWd = Hash.new{0}
    nameArrWd.each_with_index do |val, i|
    	a = []
    	a.push wd[i][0]
    	a.push wd[i][2]
    	hshWd[val] = a
    end

	# create hash oic
	hshOc = Hash.new{0}
	nameArrOc.each_with_index do |val, i|
		hshOc[val] = oc[i]
	end

	# merge two name arrays remove duplicates
	newNameArr = (nameArrOc + nameArrWd).uniq!

	newNameHsh = Hash.new{0}
	newNameArr.each do |val|
		a = []
		val1 = val.gsub(/\d+/,'')
		a << val1 << hshWd[val]
		a.push 0 if hshWd[val] == 0
		a << hshOc[val]
		a.push 0 if hshOc[val] == 0
		a.flatten!
		newNameHsh[val] = a
	end

	# sort the name hash
	newNameHsh = newNameHsh.sort.to_h

	# creating master record based on org id and names
	begin # begin exception handling block for csv file
	CSV.open(fname, "w") do |csv|
		newNameHsh.each do |x, y|
			a = []
			a << y
			a.flatten!
			csv << a
		end
	end
	rescue
		puts "Unable to open file! File already open?"
	end # end rescue block

end


def generateReport(mwd, moc)
	puts "Missing Workday records: #{mwd.length}"
	mwd.each_with_index do |val, i|
		if i < mwd.length - 1
			print val[0] + ", "
		else
			puts val[0]
		end
	end
	puts "Missing OIC records: #{moc.length}"
	moc.each_with_index do |val, i|
		if i < moc.length - 1
			print val[0] + ", "
		else
			puts val[0]
		end
	end
end


def reconcile(wd, oc, fname)
	generateMasterRecord(wd, oc, fname)
	masterFile = CSV.read(fname)
	missingRecordWd = Hash.new{}
	missingRecordOc = Hash.new{}
	masterFile.each do |line|
		if (line[1] == "0" || line[2] == "0")
			# wd record missing
			missingRecordWd[line[0]] = line
		elsif (line[3] == "0" || line[4] == "0")
			# oic record missing
			missingRecordOc[line[0]] = line
		end
	end
	generateReport(missingRecordWd, missingRecordOc)
end

recWd = getRecordCount(wdCsv)
recOc = getRecordCount(ocCsv)

if recWd != recOc
	puts "Record count doesn't match!"
end

puts "Number of records for workday: #{recWd}"
puts "Number of records for oic: #{recOc}"

reconcile(wdCsv, ocCsv, "cats.csv")
