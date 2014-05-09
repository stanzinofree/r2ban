#!/usr/local/rvm/wrappers/ruby-2.1.1@r2ban/ruby
# encoding: utf-8

require 'net/smtp'
require 'json'
require 'mail'
require 'digest/md5'
require 'erb'

# This Script was made to help me in the reporting operation to the abuse team of the ip that try to force my system.
# To obtain this result I prefere use Ruby instead Python to use  mail gem with sendmail
# This function give a logging function to the script
#
# Author:: Middei Alessandro (mailto::alexitconsulting@gmail.com)
# Copyright:: Copyright (c) 2014 Stanzinofree.net
# License:: GPLv3
# 

# This function create a simpler logger function that take in input a text message and attach it a date
#
def logger(message)
	# Calculate the time of the event
	event = time_stamp()
	# Preparation of the string to write in log_file
	text_to_write = "@ "+event+" : "+message+"\n"
	# Open a log file defined statically here and after we open it in append mode we write on it.
	File.open(@local_dir+'/logs/history.log', 'a') { | file| file.write(text_to_write)}
end

# This function generate a time_stamp to use in loggin and generate mail
def time_stamp()
	# Start with now function to take actual time in utc
	date = Time.now.utc
	date_n = date.strftime("%m/%d/%Y at %I:%M")
	return date_n
end

# This function parse the banner file in wich I put the credits for r2ban and my data.
# I hope you can left it to help me to talk about my work
# 
def bann_parse(in_file = @local_dir+'/config/banner.txt')
	# Open in read mode the banner file and return it
	bann_sign = File.open( in_file, 'r').read
	return bann_sign
end

# Function to check if the banner is present, if you want modify it you had to recalculate the hash, if
# you want remove the banner you have to remove the check_verifiy function in the flow of the software
def sent_by()
	# check_sum is variable with the digest in MD5 of the banner file
	check_sum = Digest::MD5.hexdigest File.read(@local_dir+'/config/banner.json')
	# Test if the digest value is equal to this
	if check_sum == "50b4cf74582148389a94fba75bef0cf5"
		return true
	else
		return false
	end
end	

# This function read the mail configuration file and bind the value to respective variable, return an hash
# 
def parse_prepare(in_file = @local_dir+'/config/mail_config.json')
	json = File.read(in_file)
	dump = JSON.parse(json)
	opt ={}
	opt[:from]=dump["from"]
	opt[:from_alias]=dump["from_alias"]
	opt[:cc]=dump["cc"]
	opt[:team_name]=dump["team_name"]
	return opt
end

#This function read the configuration file and bind the value to respective variables, return an hash
#
def parse_config(in_file = @local_dir+'/config/config.json')
	json = File.read(in_file)
	dump = JSON.parse(json)
	config ={}
	config[:prod]=dump["prod"]
	config[:noise]=dump["noise"]
	config[:template]=dump["template"]
	return config
end

# This function generate the temp whois text to use to search abuse mail
def generate_parse_remove_mail(ip, temp_file)
	# bash command to write whois data in dump file
	`/usr/bin/whois #{ip} > #{temp_file}`
	abuse = parse_text(temp_file)
	return abuse
end

#This function execute the parse of whois dump to search for abuse mail address
def parse_text(temp_file)
	out_file = File.open( temp_file, 'r' )
	IO.foreach(out_file) do |line|
	#first search for abuse
    if line =~ /(abuse)/i
    	#regex to find mail address if in the line there is abuse contact
    	abuse = line.match(/([\w\d\.]+)@([\w\d]+)[\.]([\w\d\.]+)/)
    	return abuse
    end
	end
end

# This part use ERB to read the mail template and compose it with variables
def compose_body(ip, service, team_name, date, template)
	@ip = ip
	@service = service
	@team_name = team_name
	@date = date
	@banner = bann_parse()
	template_file = File.open( @local_dir+'/template/'+template+'.erb', 'r').read
	erb = ERB.new(template_file)
	body = erb.result(binding)
#puts body
return body
end

# This function take in input the hash opt and generate and send the mail
def send_mail(opt, conf_system)
	
	#puts conf_system
	if sent_by()
		mail = Mail.new do
		from opt[:from]
		to opt[:to]
		cc opt[:cc]
		subject opt[:subject]
		#add_file opt[:filename]
		content_type opt[:content_type]
		body opt[:body]
		end
		if conf_system[:prod]
			mail.deliver!
			logger("ok mail sent")
		else
			puts "test"
			logger("ok mail sent")
		end
	else
		logger("Error your banner.json file was hacked.Please if you want remove banner write me at alexitconsulting@gmail")
	end
end

if __FILE__ == $0

	#Start with the creation of public varaible local_dir to make the script as portable as possible
	@local_dir = File.dirname(__FILE__)
	#Take a time_stamp of script invocation
	date = time_stamp()
	logger("executed on: "+date)
	# we take the argv and map to ip - service
	ip = ARGV[0]
	servic = ARGV[1]
	#Create variable for system file
	temp_file = @local_dir+'/tmp/whois.dump'
	ban_file = @local_dir+'banner.json'
	#Create opt and conf_system with value read from mail_config_file and config
	opt = parse_prepare()
	conf_system=parse_config()
	#retrieve abuse mail address if exist and test it
	abuse = generate_parse_remove_mail(ip, temp_file)
	#if exist abuse use it else use cc as to address
	if abuse
		abuse_mail = abuse
		logger("the address is: "+abuse_mail.to_s)
	else
    	logger("Address not found so I use your cc address")
    	abuse_mail = opt[:cc]
    end
    #Create the body of mail
	body = compose_body(ip, servic, opt[:team_name], date, conf_system[:template])
	#create local_opt to use in mail
	local_opt = {
		:subject => "Abuse on: "+servic+" from: "+ip+" at: "+date,
		:body => body,
		:content_type => 'text/html; charset=UTF-8',
		:to => abuse,
		:date => date,
	}
	opt.merge!(local_opt)
	send_mail(opt, conf_system)
end
