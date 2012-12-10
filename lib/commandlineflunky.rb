
if RUBY_VERSION.to_f < 1.9
	raise "Ruby version 1.9 or greater required (current version is #{RUBY_VERSION})"
end
module CommandLineFlunky
# 	$stderr.puts STARTUP_MESSAGE unless $has_put_startup_message

	COMMAND_FOLDER = Dir.pwd
  SCRIPT_FOLDER = File.dirname(File.expand_path(SCRIPT_FILE)) #i.e. where the script using command line flunky is
	SYS = (ENV['COMMAND_LINE_FLUNKY_SYSTEM'] or "genericlinux")
	@@sys = SYS
	def gets #No reading from the command line thank you very much!
		$stdin.gets
	end
	def self.gets
		$stdin.gets
	end
end
CommandLineFlunky::GLOBAL_BINDING = binding

# $stderr.print 'Loading libraries...' unless $has_put_startup_message
require 'getoptlong'
# $stderr.puts unless $has_put_startup_message
$has_put_startup_message = true

# Log.log_file = nil


module CommandLineFlunky
# 	CLF = COMMAND_LINE_FLAGS = []

	# This lists all the commands available on the command line. The first two items in each array indicate the long and short form of the command, and the third indicates the number of arguments the command takes. They are all implemented as Code Runner class methods (the method is named after the long form). The short form of the command is available as a global method in Code Runner interactive mode.

 	COMMANDS.push ['interactive_mode', 'im', 0]
	
	# A lookup hash which gives the appropriate short command option (copt) key for a given long command flag
	
	CLF_TO_SHORT_COPTS = COMMAND_LINE_FLAGS.inject({}) do |hash, arr|
		unless arr.size == 2 
			long, short, req = arr 
			letter = short[1,1]
			hash[long] = letter.to_sym 
		end
		hash
	end 
	
	# specifying flag sets a bool to be true

# 	CLF_BOOLS = [:H, :U, :u, :A, :a, :T, :N, :q, :z, :d] 
# 		CLF_BOOLS = [:s, :r, :D, :H, :U, :u, :L, :l, :A, :a, :T, :N,:V, :q, :z, :d] # 

	CLF_INVERSE_BOOLS = [] # specifying flag sets a bool to be false
           
	# a look up hash that converts the long form of the command options to the short form (NB command options e.g. use_large_cache have a different form from command line flags e.g. --use-large-cache)
	
	LONG_TO_SHORT = COMMAND_LINE_FLAGS.inject({}) do |hash, arr|
		unless arr.size == 2 #No short version
			long, short, req = arr 
			letter = short[1,1]
			hash[long[2, long.size].gsub(/\-/, '_').to_sym] = letter.to_sym 
		end
		hash
	end
	
	#Converts a command line flag opt with value arg to a command option which is stored in copts

	def self.process_command_line_option(opt, arg, copts)
		if CLF_BOOLS.include? CLF_TO_SHORT_COPTS[opt]
			copts[CLF_TO_SHORT_COPTS[opt]] = true
		elsif CLF_INVERSE_BOOLS.include? CLF_TO_SHORT_COPTS[opt]
			copts[CLF_TO_SHORT_COPTS[opt]] = false
		elsif CLF_TO_SHORT_COPTS[opt] # Applies to most options
			copts[CLF_TO_SHORT_COPTS[opt]] = arg
		else 
			copts[opt[2, opt.size].gsub(/\-/, '_').to_sym] = arg
		end	
		copts
	end

	# Default command options; they are usually determined by the command line flags, but can be set independently
	
	DEFAULT_COMMAND_OPTIONS = {} 

	def self.set_default_command_options_from_command_line
		opts = GetoptLong.new(*COMMAND_LINE_FLAGS)
		opts.each do |opt, arg|
		      process_command_line_option(opt, arg, DEFAULT_COMMAND_OPTIONS)
		end
		raise "\n\nCannot use large cache ('-U' or '-u' ) if submitting runs" if DEFAULT_COMMAND_OPTIONS[:U] and (DEFAULT_COMMAND_OPTIONS[:s] or DEFAULT_COMMAND_OPTIONS[:P])
	end
end

module CommandLineFlunky

	def self.read_default_command_options(copts)
		DEFAULT_COMMAND_OPTIONS.each do |key, value|
			copts[key] ||= value
		end
	end
# 	def self.process_command_options(copts)
# 		read_default_command_options(copts)
# 		copts.each do |key, value|
# 			copts[LONG_TO_SHORT[key]] = value if LONG_TO_SHORT[key]
# 		end
# 
# 		
# 		if copts[:j] # j can be a number '65' or list of numbers '65,43,382' 
# 			copts[:f]= "#{eval("[#{copts[:j]}]").inspect}.include? id"
# 		end
# 		if copts[:z]
# 			Log.log_file = Dir.pwd + '/.cr_logfile.txt'
# 			Log.clean_up
# 		else 
# 			Log.log_file = nil
# 		end
# 		copts[:F] = (copts[:F].class == Hash ? copts[:F] : (copts[:F].class == String and copts[:F] =~ /\A\{.*\}\Z/) ? eval(copts[:F]) : {})
# 		copts[:G]= [copts[:G]] if copts[:G].kind_of? String
# 		copts[:g]= [copts[:g]] if copts[:g].kind_of? String
# 		if copts[:Y] and copts[:Y] =~ /:/ 
# 			copts[:running_remotely] = true
# 		else
# 			copts[:Y].gsub!(/~/, ENV['HOME']) if copts[:Y]
# 			Dir.chdir((copts[:Y] or Dir.pwd)) do
# 				set_runner_defaults(copts)
# 			end
# 		end
# 		if copts[:p] and copts[:p].class == String # should be a hash or an inspected hash
# 			copts[:p] = eval(copts[:p])
# 		end
# # 		ep Log.log_file
# 	end
# 	
# 	# Retrieve the runner with the folder (and possibly server) given in copts[:Y]. If no runner has been loaded for that folder, load one.
# 	
# 	def self.fetch_runner(copts={})
# # 		ep copts
# 		process_command_options(copts)
# 		@runners ||= {}
# 		runner = nil
# 		if copts[:Y] and copts[:Y] =~ /:/ 
# 			copts_r = copts.dup
# 			host, folder = copts[:Y].split(':')
# 			copts_r[:Y] = nil
# 			copts[:Y] = nil
# 			unless @runners[[host, folder]]
# 				runner = @runners[[host, folder]] = RemoteCommandLineFlunky.new(host, folder, copts)
# 				(eputs 'Updating remote...'; runner.update) unless (copts[:g] and (copts[:g].kind_of? String or copts[:g].size > 0)) or copts[:no_update] 
# 			else 
# 				runner = @runners[[host, folder]]
# 			end
# 		else
# 		  
# 			copts[:Y] ||= Dir.pwd
# 		  	Dir.chdir((copts[:Y] or Dir.pwd)) do
# 				unless @runners[copts[:Y]]
# 					runner = @runners[copts[:Y]] = CommandLineFlunky.new(Dir.pwd, code: copts[:C], modlet: copts[:m], version: copts[:v], executable: copts[:X])
# 					runner.update unless copts[:no_update]
# 				else
# 					runner = @runners[copts[:Y]]
# 				end
# # 				p 'reading defaults', @r.conditions, DEFAULT_RUNNER_OPTIONS
# 				runner.read_defaults
# # 				p 'read defaults', @r.conditions
# 				
# 			end #Dir.chdir
# 		end
# 		return runner
# # 		@r.read_defaults
# 	end
# 	def self.update_runners
# 		@runners ||= {}
# 		@runners.each{|runner| runner.update}
# 	end


	INTERACTIVE_METHODS = <<EOF
CommandLineFlunky::COMMANDS.each do |command|
	eval("def #\{command[1]}(*args) 
		  CommandLineFlunky.send(#\{command[0].to_sym.inspect}, *args)
	      end")

EOF
        def self.runner
		@runner
	end

	def CommandLineFlunky.interactive_mode(copts={})
# 		process_command_options(copts)
	  			unless false and FileTest.exist? (ENV['HOME'] + "/.#{PROJECT_NAME}_interactive_options.rb")
				File.open(ENV['HOME'] + "/.#{PROJECT_NAME}_interactive_options.rb", 'w') do |file|
					file.puts <<EOF
	$has_put_startup_message = true #please leave!
	$command_line_flunky_interactive_mode = true #please leave!
	require 'yaml'

	def reset
	  Dispatcher.reset_application!
	end
	  
	IRB.conf[:AUTO_INDENT] = true
	IRB.conf[:USE_READLINE] = true
	IRB.conf[:LOAD_MODULES] = []  unless IRB.conf.key?(:LOAD_MODULES)
	unless IRB.conf[:LOAD_MODULES].include?('irb/completion')
	  IRB.conf[:LOAD_MODULES] << 'irb/completion'
	end      

				
	require 'irb/completion'
	require 'irb/ext/save-history'
	IRB.conf[:PROMPT_MODE] = :SIMPLE
	IRB.conf[:SAVE_HISTORY] = 100
	IRB.conf[:HISTORY_FILE] = "\#\{ENV['HOME']}/.#{PROJECT_NAME}_irb_save_history"
	IRB.conf[:INSPECT_MODE] = false


EOF
				end
			end
			File.open(".int.tmp.rb", 'w')do |file|
				file.puts "#{copts.inspect}.each do |key, val|
					CommandLineFlunky::DEFAULT_COMMAND_OPTIONS[key] = val
				end"
				file.puts CommandLineFlunky::INTERACTIVE_METHODS
			end
			exec %[#{Config::CONFIG['bindir']}/irb#{Config::CONFIG['ruby_install_name'].sub(/ruby/, '')} -f -I '#{SCRIPT_FOLDER}' -I '#{File.dirname(__FILE__)}' -I '#{Dir.pwd}' -I '#{ENV['HOME']}' -r '.#{PROJECT_NAME}_interactive_options' -r '#{File.basename(SCRIPT_FILE)}'  -r .int.tmp ]
	end

# # 	def self.setup
# # 	end
	
	def CommandLineFlunky.run_script
		CommandLineFlunky.setup(DEFAULT_COMMAND_OPTIONS)
		return if $command_line_flunky_interactive_mode
		command = COMMANDS.find{|com| com.slice(0..1).include? ARGV[0]}
		raise "Command #{ARGV[0]} not found" unless command
		send(command[0].to_sym, *ARGV.slice(1...(1+command[2])), DEFAULT_COMMAND_OPTIONS)
	end
end

CommandLineFlunky.set_default_command_options_from_command_line

####################
# CommandLineFlunky.run_script unles
###################


