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
	event = Time.now
	event = event.strftime("%m/%d/%Y at %I:%M")
	# Preparation of the string to write in log_file
	text_to_write = "@ "+event+" : "+message+"\n"
	# Open a log file defined statically here and after we open it in append mode we write on it.
	File.open(@local_dir+'/logs/history.log', 'a') { | file| file.write(text_to_write)}
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

# This function read the configuration file and bind the value to respective variable, return an hash
# 
def parse_prepare(in_file = @local_dir+'/config/config.json')
	json = File.read(in_file)
	dump = JSON.parse(json)
	opt ={}
	opt[:from]=dump["from"]
	opt[:from_alias]=dump["from_alias"]
	opt[:cc]=dump["cc"]
	opt[:team_name]=dump["team_name"]
	return opt
end

# This function generate the temp whois text to use to search abuse mail
def generate_parse_remove_mail(ip, temp_file)
	# bash command to write whois data in dump file
	`/usr/bin/whois #{ip} > /opt/r2ban/tmp/whois.dump`
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
    else
  		#This return in future will be encoded to launch new mail of non found whois
    	return "none"
    end
end
end

# This part use ERB to read the mail template and compose it with variables
def compose_body(ip, service, team_name, date)
	@ip = ip
	@service = service
	@team_name = team_name
	@date = date
	@banner = bann_parse()
	template_file = File.open( @local_dir+'/config/r2ban.erb', 'r').read
	erb = ERB.new(template_file)
	body = erb.result(binding)
#puts body
return body
end

# This function take in input the hash opt and generate and send the mail
def send_mail(opt)
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
		mail.deliver!
		logger("ok mail sent")
	else
		logger("Error your banner.json file was hacked.Please if you want remove banner write me at alexitconsulting@gmail")
	end
end

if __FILE__ == $0

	@local_dir = File.dirname(__FILE__)
	date = Time.now
	date = date.strftime("%m/%d/%Y at %I:%M")
	ip = ARGV[0]
	servic = ARGV[1]
	temp_file = @local_dir+'/tmp/whois.dump'
	ban_file = @local_dir+'banner.json'
	opt = parse_prepare()
	abuse = generate_parse_remove_mail(ip, temp_file)
	body = compose_body(ip, servic, opt[:team_name], date)
	local_opt = {
		:subject => "Abuse on: "+servic+" from: "+ip+" at: "+date,
		:body => body,
		:content_type => 'text/html; charset=UTF-8',
		:to => opt[:to],
		:date => date,
	}
	logger("executed on: "+date)
	opt.merge!(local_opt)
	send_mail(opt)
end
