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

# ���ץ�������
opt = OptionParser.new
OPTS ={}
opt.on('--machine VAL', 'machine/dest') {|v| OPTS[:machine] = v}
opt.on('--keyword VAL', 'Add environment variable including the keyword') {|v| OPTS[:keyword] = v}
opt.on('--inidentifier VAL', 'Original .identifier file') {|v| OPTS[:inidentifier] = v}
opt.on('--invariable VAL', 'Original .variable file') {|v| OPTS[:invariable] = v}
opt.on('--outidentifier VAL', 'Output .identifier file') {|v| OPTS[:outidentifier] = v}
opt.on('--outvariable VAL', 'Output .variable file') {|v| OPTS[:outvariable] = v}
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

if OPTS[:outidentifier].nil?
	out_identifier = "./.identifier.all"
else
	out_identifier = OPTS[:outidentifier]
end

if OPTS[:outvariable].nil?
	out_variable = "./.variable.all"
else
	out_variable = OPTS[:outvariable]
end

# �񤭹�����.identifier, .variable�κ���
newidentifier_filepath = "./.identifier.all"
newvariable_filepath = "./.variable.all"

FileUtils.cp(in_identifier, out_identifier)
FileUtils.cp(in_variable, out_variable)

newidentifier = File.open(out_identifier, "a")
newvariable = File.open(out_variable, "a")

# .identifier���Ф������
all_variables = getGrepStrings(penvvar_filepath, "GPS_PENV_VAR_ID")
all_variables.each { |str|
	
	var_variable = getGpsPenvVariable(str)
	
	# keyword�����ƤϤޤ�ʤ��Ķ��ѿ������Ф�
	if !OPTS[:keyword].nil? && /#{OPTS[:keyword]}/ !~ var_variable
		next
	end
	
	search_result = getGrepStrings(in_identifier, var_variable+"\t")
	# .identifier��VAR��������ʤ���硢.identifier��.variable��VAR��VAL���ɲä��롣
	if search_result.size == 0
	
		var_value = getGpsPenvValue(penvvar_filepath, str)
		
		# .identifier��VAR���ɲ�	
		p var_variable
		newidentifier.write(var_variable + "\t" + var_value + "\n")			
		
		val_variables = Array.new
		val_values = Array.new
		/(GPS_PENV_VAR_ID_)(.+)/ =~ var_variable
		all_values = getGrepStrings(penvvar_filepath, "GPS_PENV_VAL_INT_"+$2+"_")

		if all_values.size == 0
			# .identifier�ؤ�VAL�ɲäʤ�
			# .variable�ؤ��ɲáʥ����פ�INT��
			newvariable.write(var_variable + "\t" + "INT" + "\t" + "0" + "\n")			
		else
			all_values.each { |str|
				val_variables.push(getGpsPenvVariable(str))
				val_values.push(getGpsPenvValue(penvvar_filepath, str))
			}
			# .identifier��VAL���ɲ�
			for i in 0..val_variables.size-1
				p val_variables[i] + "\t" + val_values[i] + "\n"
				newidentifier.write(val_variables[i] + "\t" + val_values[i] + "\n")
			end
			newidentifier.write("\n")
				
			# .variable���ɲáʥ����פ�ID��
			newvariable.write(var_variable + "\t" + "ID" + "\t" + val_variables.size.to_s)
			for i in 0..val_variables.size-1
				newvariable.write("\t" + val_variables[i])
			end
			newvariable.write("\n\n")
		end
	end
}

newidentifier.close()
newvariable.close()
