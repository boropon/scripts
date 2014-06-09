#!/usr/bin/ruby

require 'fileutils'
require 'nkf'
require 'fileutils'
require 'optparse'

###################################################################
#Function		:getGrepStrings
#Description	:filenameのファイルからsearchstringを含む行を探し、
#				:Stringの配列としてreturnする
###################################################################
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

###################################################################
#Function		:getGpsPenvVariableAndValue
#Description	:penv_var.hのdefineから、マクロ名と値を抜き出して、
#				:hashとしてreturnする
#				:値がマクロである場合もそのままreturnする
###################################################################
def getGpsPenvVariableAndValue(gpsdefstring)
	
	(dummy, variable, value) = gpsdefstring.split(/\s+/)
	
	hash = Hash.new()
	hash.store("variable", variable)
	hash.store("value", value)
	
	return hash
end

###################################################################
#Function		:getGpsPenvVariable
#Description	:penv_var.hのdefineから、マクロ名を抜き出してreturnする
###################################################################
def getGpsPenvVariable(gpsdefstring)
	
	(dummy, variable, value) = gpsdefstring.split(/\s+/)
	
	return variable
end

###################################################################
#Function		:getGpsPenvValue
#Description	:penv_var.hのdefineから、値を抜き出してreturnする
#				:値がマクロである場合、数値の値となるように解決する。
###################################################################
def getGpsPenvValue(filename, gpsdefstring)
	
	while !gpsdefstring.nil?
		(dummy, variable, value) = gpsdefstring.split(/\s+/)
		if integer_string?(value)
			p "integer"
			return value
		else
			/(\()(.+)(\))/ =~ value
			if !$2.nil? then
				return $2
			else
				p "continue"
				gpsdefstring = getGrepStrings(filename, value+"\t").first
			end
		end
	end

	# penv_var.h以外に定義がある
	return "-99999999"
end

###################################################################
#Function		:integer_string?
#Description	:文字列が整数を表している場合trueを、
#				:それ以外の場合はfalseをreturnする
###################################################################
def integer_string?(str)
	Integer(str)
	true
rescue ArgumentError
	false
end

###################################################################
#Function		:makePenvHash
#Description	:penv_var.hの環境変数と値のHashをreturnする
###################################################################
def makePenvHash(filename, type)
	
	hash = Hash.new()
	
	if type == "variable"
		search_key = "GPS_PENV_VAR_ID"
	elsif type == "value"
		search_key = "GPS_PENV_VAL_INT_"
	else
		p "makePenvHash is wrong."
		exit
	end
	
	f = open(filename)
	f.each_line {|line|
		if /#{search_key}/ =~ line
			(dummy, variable, tmp_value) = line.split(/\s+/)
			if integer_string?(tmp_value)
				value = tmp_value
			else
				/(\()(.+)(\))/ =~ tmp_value
				if !$2.nil? then
					value = $2
				else
					value = tmp_value
				end
			end
			hash.store(variable, value)
		end
	}
	f.close()
	return hash
end

###################################################################
#Function		:makePenvHash
#Description	:penv_var.hのdefineから、値を抜き出してreturnする
#				:値がマクロである場合、数値の値となるように解決する
###################################################################
def getPenvHashValue(hash, variable)
	
	while !variable.nil?
		value = hash[variable]
		if value.nil?
			break
		elsif integer_string?(value)
			return value
		else
			variable = value
		end
	end
	
	# penv_var.h以外に定義があるので諦める
	return "-99999999"
end

###################################################################
#Function		:makeIdentifierHash
#Description	:.identifierの環境変数と値のHashをreturnする
###################################################################
def makeIdentifierHash(filename)
	
	hash = Hash.new()

	f = open(filename)
	f.each_line {|line|
		(variable, value) = line.split(/\s+/)
		hash.store(variable, value)
	}
	f.close()
	return hash
end

# オプション解析
opt = OptionParser.new
OPTS ={}
opt.on('--machine VAL', 'machine/dest') {|v| OPTS[:machine] = v}
opt.on('--keyword VAL', 'Add environment variable including the keyword') {|v| OPTS[:keyword] = v}
opt.on('--inidentifier VAL', 'Original .identifier file(default .identifier)') {|v| OPTS[:inidentifier] = v}
opt.on('--invariable VAL', 'Original .variable file(default .variable)') {|v| OPTS[:invariable] = v}
opt.on('--outidentifier VAL', 'Output .identifier file(default .identifier.machinename)') {|v| OPTS[:outidentifier] = v}
opt.on('--outvariable VAL', 'Output .variable file(default .variable.machinename)') {|v| OPTS[:outvariable] = v}
opt.parse!(ARGV)

#penvvar_filepath = "/proj/lpux/products/" + OPTS[:machine] + "/base/gw_printer/p_gpslib/include/gps/penv_var.h"
penvvar_filepath = "./penv_var.h"

if OPTS[:inidentifier].nil?
	in_identifier = "./.identifier"
else
	in_identifier = OPTS[:inidentifier]
end

if OPTS[:invariable].nil?
	in_variable = "./.variable"
else
	in_variable = OPTS[:invariable]
end

(machine, dest) = OPTS[:machine].split(/\//)
machine.downcase!
if OPTS[:outidentifier].nil?
	out_identifier = "./.identifier." + machine + "_" + dest
else
	out_identifier = OPTS[:outidentifier]
end

if OPTS[:outvariable].nil?
	out_variable = "./.variable." + machine + "_" + dest
else
	out_variable = OPTS[:outvariable]
end

# 書き込み用.identifier, .variableの作成
newidentifier_filepath = "./.identifier.all"
newvariable_filepath = "./.variable.all"

FileUtils.cp(in_identifier, out_identifier)
FileUtils.cp(in_variable, out_variable)

newidentifier = File.open(out_identifier, "a")
newvariable = File.open(out_variable, "a")

# penv_var.hと.identifierからハッシュを作成
penvvar_hash = makePenvHash(penvvar_filepath, "variable")
penvval_hash = makePenvHash(penvvar_filepath, "value")
identifier_hash = makeIdentifierHash(in_identifier)

penvvar_hash.each_key { |var_variable|
	
	# keywordに当てはまらない環境変数は飛ばす
	if !OPTS[:keyword].nil? && /#{OPTS[:keyword]}/ !~ var_variable
		next
	end

	# .identifierに無い環境変数の定義を追加する。
	if !identifier_hash.key?(var_variable)
		newidentifier.write(var_variable + "\t" + getPenvHashValue(penvvar_hash, var_variable) + "\n")
		
		/(GPS_PENV_VAR_ID_)(.+)/ =~ var_variable
		select_key = $2 + "_"
		tmpval_hash = penvval_hash.select{|k| k =~ /#{select_key}/}
		if tmpval_hash.empty?
			# .identifierへのVAL追加なし
			# .variableへの追加（タイプはINT）
			newvariable.write(var_variable + "\t" + "INT" + "\t" + "0" + "\n")
		else
			# .identifierにVALを追加
			tmpval_hash.each_key { |val_variable|
				newidentifier.write(val_variable+ "\t" + getPenvHashValue(penvval_hash, val_variable) + "\n")
			}
			newidentifier.write("\n")
			
			# .variableにVALを追加
			newvariable.write(var_variable + "\t" + "ID" + "\t" + tmpval_hash.size.to_s)
			tmpval_hash.each_key { |val_variable|
				newvariable.write("\t" + val_variable)
			}
			newvariable.write("\n\n")
		end
	end
}

newidentifier.close()
newvariable.close()
