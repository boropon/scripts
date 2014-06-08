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

machine_and_dest = ARGV[0]
penvvar_filepath = "/proj/lpux/products/" + ARGV[0] + "/base/gw_printer/p_gpslib/include/gps/penv_var.h"

# .identifierに対する処理
all_variables = getGrepStrings(penvvar_filepath, "GPS_PENV_VAR_ID")
all_variables.each { |str|
	hash = getGpsPenvVariableAndValue(str)
	# valueが文字列なら再検索して数値に変換
	search_result = getGrepStrings("./.identifier", hash["variable"]+"\t")

	if search_result.size == 0
		# .identifierに定義を追加(variable, value両方)
	end
}

# .variableに対する処理
