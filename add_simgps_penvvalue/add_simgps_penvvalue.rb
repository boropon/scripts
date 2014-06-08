#!/usr/bin/ruby

require 'fileutils'
require 'nkf'

def getGrepStrings(filename, searchstring)

	strings = Array.new

	open(filename, "r") { |f|
		while line = f.gets
			euc_line = NKF.nkf("-e", line)
			euc_line.chomp!
			if /#{searchstring}/ =~ euc_line
				strings.push(euc_line)
			end
		end
	}

	return strings
end

def getGpsPenvVariableAndValue(gpsdefstring)
	
	(dummy, variable, value) = gpsdefstring.split(/\s+/)
	
	hash = Hash.new()
	hash.store("variable", variable)
	hash.store("value", value)
	
	return hash
end

def integer_string?(str)
	Integer(str)
	true
rescue ArgumentError
	false
end

machine_and_dest = ARGV[0]
#penvvar_filepath = "/proj/lpux/products/" + ARGV[0] + "/base/gw_printer/p_gpslib/include/gps/penv_var.h"
penvvar_filepath = "./penv_var.h"

# .identifierに対する処理
all_variables = getGrepStrings(penvvar_filepath, "GPS_PENV_VAR_ID")
all_variables.each { |str|
	
	hash = getGpsPenvVariableAndValue(str)
	search_result = getGrepStrings("./.identifier", hash["variable"]+"\t")
	if search_result.size == 0
		# .identifierに定義を追加(VAR, VAL両方)
		
		
		# VAR, VAL共通の値取得処理
		while str.size != 0
			hash = getGpsPenvVariableAndValue(str)
			if integer_string?(hash["value"])
				envvalue = hash["value"]
				break
			else
				/(\()(.+)(\))/ =~ hash["value"]
				if !$2.nil? then
					envvalue = $2
					break
				else
					str = getGrepStrings(penvvar_filepath, hash["value"]+"\t").first
				end
			end
		end
	end

}

# .variableに対する処理
