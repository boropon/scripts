#!/usr/bin/ruby

require 'fileutils'
require 'nkf'
require 'fileutils'
require 'optparse'

###################################################################
#Function		:getGrepStrings
#Description	:filename�Υե����뤫��searchstring��ޤ�Ԥ�õ����
#				:String������Ȥ���return����
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
#Description	:penv_var.h��define���顢�ޥ���̾���ͤ�ȴ���Ф��ơ�
#				:hash�Ȥ���return����
#				:�ͤ��ޥ���Ǥ�����⤽�Τޤ�return����
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
#Description	:penv_var.h��define���顢�ޥ���̾��ȴ���Ф���return����
###################################################################
def getGpsPenvVariable(gpsdefstring)
	
	(dummy, variable, value) = gpsdefstring.split(/\s+/)
	
	return variable
end

###################################################################
#Function		:getGpsPenvValue
#Description	:penv_var.h��define���顢�ͤ�ȴ���Ф���return����
#				:�ͤ��ޥ���Ǥ����硢���ͤ��ͤȤʤ�褦�˲�褹�롣
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

	# penv_var.h�ʳ������������
	return "-99999999"
end

###################################################################
#Function		:integer_string?
#Description	:ʸ����������ɽ���Ƥ�����true��
#				:����ʳ��ξ���false��return����
###################################################################
def integer_string?(str)
	Integer(str)
	true
rescue ArgumentError
	false
end

###################################################################
#Function		:makePenvHash
#Description	:penv_var.h�δĶ��ѿ����ͤ�Hash��return����
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
		euc_line = NKF.nkf("-e", line)
		if /#{search_key}/ =~ euc_line
			(dummy, variable, tmp_value) = euc_line.split(/\s+/)
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
#Description	:penv_var.h��define���顢�ͤ�ȴ���Ф���return����
#				:�ͤ��ޥ���Ǥ����硢���ͤ��ͤȤʤ�褦�˲�褹��
###################################################################
def getPenvHashValue(penvhash, paperhash, variable)
	
	while !variable.nil?
		value = penvhash[variable]
		if value.nil?
			break
		elsif integer_string?(value)
			return value
		else
			variable = value
		end
	end
	
	# paperdef.h������������value��return
	if !paperhash[variable].nil?
		return paperhash[variable]
	end

	# penv_var.h�ʳ������������Τ������
	return "-99999999"
end

###################################################################
#Function		:makeIdentifierHash
#Description	:.identifier�δĶ��ѿ����ͤ�Hash��return����
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

###################################################################
#Function		:makePaperdefHash
#Description	:.identifier�δĶ��ѿ����ͤ�Hash��return����
###################################################################
def makePaperdefHash(filename)

	hash = Hash.new()

	is_enum = false
	is_define = false
	paper_code = 0
	f = open(filename)
	f.each_line {|line|
		euc_line = NKF.nkf("-e", line)
		if /#{"enum\tgps_p_sz"}/ =~ euc_line
			is_enum = true
		elsif /#{"};"}/ =~ euc_line
			is_enum = false
		elsif /^#define.+/ =~ euc_line
			is_define = true
		end

		if is_enum == true
			paper_codes = euc_line.scan(/GPS_CODE_(?:[A-Z]|[0-9]|[a-z]|_|x| |=)+/)
			paper_codes.each {|x|
				if x =~ /(GPS_CODE_(?:[A-Z]|[0-9]|[a-z]|_|x|)+) = ([0-9]+)/
					x = $1
					paper_code = $2.to_i
				end
				hash.store(x, paper_code.to_s)
				paper_code += 1
			}
		elsif is_define == true
			(dummy, variable, value) = euc_line.split(/\s+/)
			
			if !value.nil? && integer_string?(value)
				hash.store(variable, value)
			elsif !value.nil? && !hash[value].nil? && integer_string?(hash[value])
				hash.store(variable, hash[value])
			else
				#���Υ������ϥϥå�����ɲä��ʤ��Ƥ����Ϥ�
			end
			is_define = false
		end
	}
	f.close()
	return hash
end

# ���ץ�������
opt = OptionParser.new
OPTS ={}
opt.on('--machine VAL', 'machine/dest') {|v| OPTS[:machine] = v}
opt.on('--keyword VAL', 'Add environment variable including the keyword') {|v| OPTS[:keyword] = v}
opt.on('--inidentifier VAL', 'Original .identifier file(default .identifier)') {|v| OPTS[:inidentifier] = v}
opt.on('--invariable VAL', 'Original .variable file(default .variable)') {|v| OPTS[:invariable] = v}
opt.on('--outidentifier VAL', 'Output .identifier file(default .identifier.machinename)') {|v| OPTS[:outidentifier] = v}
opt.on('--outvariable VAL', 'Output .variable file(default .variable.machinename)') {|v| OPTS[:outvariable] = v}
opt.on('--progress', 'Display progress') {|v| OPTS[:progress] = v}
opt.parse!(ARGV)

penvvar_filepath = "/proj/lpux/products/" + OPTS[:machine] + "/base/gw_printer/p_gpslib/include/gps/penv_var.h"
#penvvar_filepath = "./penv_var.h"
paperdef_filepath = "/proj/lpux/products/" + OPTS[:machine] + "/base/gw_printer/p_gpslib/include/gps/paperdef.h"

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

FileUtils.cp(in_identifier, out_identifier)
FileUtils.cp(in_variable, out_variable)

newidentifier = File.open(out_identifier, "a")
newvariable = File.open(out_variable, "a")

# penv_var.h��.identifier��paperdef.h����ϥå�������
penvvar_hash = makePenvHash(penvvar_filepath, "variable")
penvval_hash = makePenvHash(penvvar_filepath, "value")
identifier_hash = makeIdentifierHash(in_identifier)
paperdef_hash = makePaperdefHash(paperdef_filepath)

if OPTS[:progress] == true
	eighty_percent = (penvvar_hash.size * 0.8).round
	sixty_percent = (penvvar_hash.size * 0.6).round
	forty_percent = (penvvar_hash.size * 0.4).round
	twenty_percent = (penvvar_hash.size * 0.2).round
end
roop_count = 0
penvvar_hash.each_key { |var_variable|
	
	if OPTS[:progress] == true
		if roop_count == eighty_percent
			p "80% finished!"
		elsif roop_count == sixty_percent
			p "60% finished!"
		elsif roop_count == forty_percent
			p "40% finished!"
		elsif roop_count == twenty_percent
			p "20% finished!"
		elsif roop_count == 0
			p "Make hash finished!"
		end
	end

	# keyword�����ƤϤޤ�ʤ��Ķ��ѿ������Ф�
	if !OPTS[:keyword].nil? && /#{OPTS[:keyword]}/ !~ var_variable
		next
	end

	# .identifier��̵���Ķ��ѿ���������ɲä��롣
	if !identifier_hash.key?(var_variable)
		newidentifier.write(var_variable + "\t" + getPenvHashValue(penvvar_hash, paperdef_hash, var_variable) + "\n")
		
		/(GPS_PENV_VAR_ID_)(.+)/ =~ var_variable
		select_key = $2 + "_"
		tmpval_hash = penvval_hash.select{|k| k =~ /#{select_key}/}
		if tmpval_hash.empty?
			# .identifier�ؤ�VAL�ɲäʤ�
			# .variable�ؤ��ɲáʥ����פ�INT��
			newvariable.write(var_variable + "\t" + "INT" + "\t" + "0" + "\n")
		else
			# .identifier��VAL���ɲ�
			tmpval_hash.each_key { |val_variable|
				newidentifier.write(val_variable + "\t" + getPenvHashValue(penvval_hash, paperdef_hash, val_variable) + "\n")
			}
			newidentifier.write("\n")
			
			# .variable��VAL���ɲ�
			newvariable.write(var_variable + "\t" + "ID" + "\t" + tmpval_hash.size.to_s)
			tmpval_hash.each_key { |val_variable|
				newvariable.write("\t" + val_variable)
			}
			newvariable.write("\n\n")
		end
	end

	roop_count += 1
}

newidentifier.close()
newvariable.close()
