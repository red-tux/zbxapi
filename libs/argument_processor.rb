#GPL 2.0  http://www.gnu.org/licenses/gpl-2.0.html
#Zabbix CLI Tool and associated files
#Copyright (C) 2009,2010 Andrew Nelson nelsonab(at)red-tux(dot)net
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

##########################################
# Subversion information
# $Id$
# $Revision$
##########################################

#setup our search path or libraries
path=File.expand_path(File.dirname(__FILE__) + "/../libs")+"/"

require path+'zdebug'
require path+'exceptions'
require path+'zabcon_exceptions'
require path+'zabcon_globals'

# ArgumentProcessor  This class contains the functions for processing the arguments passed to each command
# The functions will return two hashes.
# :api_params - parameters to pass to the API call
# :show_params - parameters to pass to the print routines
# The args parameter is a hash of the

# All functions for argument processing are in alphabetical order except for default functions which are placed first

class ArgumentProcessor

  include ZDebug

  attr_reader :help, :default, :default_get

  def initialize
    @help=self.method(:help_processor)
    @default=self.method(:default_processor)
    @default_get=self.method(:default_get_processor)
  end


  def strip_comments(str)
    str.lstrip!
    str.chomp!

    tmp=""
    escaped=false
    quoted=false
    endquote=''

p str.methods.sort
    str.each_char{|char|
      if quoted
        if char==endquote
          quoted=false
          tmp+=char
        else
          tmp+=char
        end
      elsif escaped
        escaped=false
        tmp+=char
      elsif char=='\\'
        escaped=true
       tmp+=char
      elsif char=='"' or char=="'"
        quoted=true
        case char
          when "'"       # single quote
            endquote="'"
          when '"'       # double quote
            endquote='"'
        end
        tmp+=char
      elsif char=='#'
        break
      else
        tmp+=char
      end
    }

    tmp.chomp
  end

  # converts item to the appropriate data type if need be
  # otherwise it returns item
  def convert_or_parse(item)
    return item if item.class==Fixnum
    if item.to_i.to_s==item
      return item.to_i
    elsif item =~ /^"(.*?)"$/
      text=Regexp.last_match(1)
      return text
    elsif item =~ /^\[(.*?)\]$/
      array_s=Regexp.last_match(1)
      array=safe_split(array_s,',')
      results=array.collect do |i|
        i.lstrip!
        i.rstrip!
        convert_or_parse(i)
      end
      return results
    elsif item.downcase=="true" || item.downcase=="false"
      return true if item.downcase=="true"
      return false
    else
      array=safe_split(item,',')
      if array.length<=1
        return item
      else
        return array
      end
    end
  end

  #splits a line at boundaries defined by boundary.
  def safe_split(line,boundary=nil)
    debug(9,line,"line")
    debug(9,boundary,"boundary")

    return line if line.class!=String

    items=[]
   item=""
    quoted=false
    qchar=''
    splitchar= boundary.nil? ? /\s/ : /#{boundary}/
    escaped=false  #used for when the escape character "\" is found
    line.each_char do |char|  # split up incoming line and account for item="stuff n stuff"
#      p char
      add_char=true  # are we going to add this character?

      if char=="\\" and !escaped
        escaped=true  # We've found an escape character which means add the next char'
        next
      end

      # puts "char->#{char}, quoted->#{quoted}, qchar->#{qchar}, item->#{item}"
      if (char !~ splitchar) && (!escaped || !quoted) # add the space if we're in a quoted string and not escaped
        if !quoted  # This block will group text found inside "" or []
          if char=='"'    # is the character a quote?
#            puts "quote found"
            qchar='"'     # set our end quote character
            quoted=true  # set our mode to be quoted
#            add_char=false  # do not add this character
#          elsif char=='('
#            qchar=')'
#            quoted=true
          elsif char=='['  # is the character a open bracket?
            qchar=']'      # set our end quote character
            quoted=true   # enable quoted mode
          end
        else   #quoted == false
          if char==qchar  # we have found our quote boundary
#            puts "found quote"
            quoted=false
#            add_char=false if char=='"' # do not add the character if it is a quote character
          end
        end  # end !quoted block

        item<<char if add_char
#        p item

      elsif escaped || quoted  # add the character since we're escaped'
        item<<char
      else  # we have found our split boundary, add the item
        items<<item if item.length>0
        item=""
      end  # end  (char!~splitchar or quoted) && !escaped

      escaped=false  # when we set escape to true we use next to skip the rest of the block
    end
    items<<item if item.length>0  # be sure not to forget the last element from the block

    raise ParseError.new("Closing #{qchar} not found!") if quoted

    items
  end

  # Params to hash breaks up an incoming line into individual elements.
  # It's kinda messy, and could probably one day use some cleaning up
  # The basic concept is it will return a hash based on what it finds.
  # If it finds an = character it will make a hash out of the left and right
  # if items are found inside quotes they will be treated as one unit
  # If items are found individually (not quoted) it will be put in a hash as the
  # left side with a value of true
  def params_to_hash(line)
    debug(6,line,"line")
    params=safe_split(line)
    debug(6,params,"After safe_split")

    retval = {}
    params.each do |item|
      debug(9,item,"parsing")
      item.lstrip!
      item.chomp!
      if item =~ /^(.*?)=("(.+)"|([^"]+))/ then
        lside=Regexp.last_match(1)
        rside=convert_or_parse(Regexp.last_match(2))

        if lside =~ /^"(.*?)"$/
          lside=Regexp.last_match(1)
        end

        retval.merge!(lside=>rside)
      elsif item =~ /(.*?)=""/ then
        lside=Regexp.last_match(1)
        rside=""
        retval.merge!(lside=>rside)
      else
         if item =~ /^"(.*?)"$/
           item=Regexp.last_match(1)
         end
        retval.merge!(item=>true)
      end
      debug(9,retval,"parsed")
    end
    retval
  end

    #substitute_vars
  #This function will substitute the variable tokens in the string args for the values in the global object
  #GlobalVars
  def substitute_vars(args)

    #split breaks a string into an array  of component pieces which makes it easier to perform substitutions
    #in the present situation the component pieces are variables and non-variables.
    #whitespace is preserved in this split process
    def split(str)
      return [] if str.nil? or str.empty?
      #The function originally would split out quoted strings which would not be scanned
#      if result=/\\["']/.match(str)  # split out escaped quotes
#        return split(result.pre_match) + [result[0]] + split(result.post_match)
#      end
#      if result=/((["'])[^"']+\2)/.match(str)  #split out legitimately quoted strings
#        return split(result.pre_match) + [result[0]] + split(result.post_match)
#      end
#      if result=/["']/.match(str)  #split out dangling quotes
#        return split(result.pre_match) + [result[0]] + split(result.post_match)
#      end
#      if result=/\s+/.match(str)  #split on whitespace (this way we can preserve it)
#        return split(result.pre_match) + [result[0]] + split(result.post_match)
#      end
      if result=/[\\]?\$[A-Za-z]\w*/.match(str)  #split on variables
        return split(result.pre_match) + [result[0]] + split(result.post_match)
      end
      return [str]  #return what's left
    end

    # A variable is something that starts with a $ character followed by a letter then followed zero or more letters or
    # numbers
    # Variable substitution comes from the global singleton GlobalVars
    def substitute(args)
      args.map { |val|
        if result=/^\$([A-Za-z]\w*)/.match(val)
          GlobalVars.instance[result[1]]
        else
          val
        end
      }
    end

    #Removes the escaping on the $ character which is used to prevent variable substitution
    def unescape(args)
      args.gsub(/\\\$/, '$')
    end

    debug(2,args,"Pre substitution")
    args=unescape(substitute(split(args)).join)
    debug(2,args,"Post Substitution")

    return args
  end

  def call_help(help_func)
    help_func.call if !help_func.nil?
  end

  # The help processor just passes the args back in the api_params key
  # Note, this is the only processor which does not process for variables.
  def help_processor(help_func,valid_args,args,user_vars,*options)
    args=substitute_vars(args)
    {:api_params=>args, :show_params=>{}}
  end

  alias raw_processor help_processor

  # The default helper process the "show=*" argument
  # If there is a show argument "extendoutput" is sent to the API and the show argument is passed to the print routines
  def default_helper(args)
    debug(7,args,"default helper")
     api_params = args
    show_params = {}
    if !args["show"].nil?
       show_params={:show=>args["show"]}
       api_params.delete("show")
       api_params.merge({"extendoutput"=>true})
    end

    {:api_params=>api_params, :show_params=>show_params}
  end

  # This is the default Parameter processor.  This is passed to the Command Tree object when it is instantiated
  # The default processor also checks the incoming parameters against the a list of valid arguments, and merges
  # the user variables with the inbound arguments with the inbound arguments taking precedence, raises an
  # exception if there is an error
  def default_processor(help_func,valid_args,args,user_vars,*options)
    debug(7,args,"default argument processor")

    args=substitute_vars(args)
    args=params_to_hash(args)
    if !(invalid=check_parameters(args, valid_args)).empty?
      msg="Invalid parameters:\n"
      msg+=invalid.join(", ")
      raise ParameterError_Invalid.new(msg,:retry=>true, :help_func=>help_func)
    end

    valid_user_vars = {}

    if !valid_args.nil?
      valid_args.each {|item|
        valid_user_vars[item]=user_vars[item] if !user_vars[item].nil?
      }
    end
    args = valid_user_vars.merge(args)
    
    default_helper(args)

  end

  # This processor does not do anything fancy.  All items passed in via args are passed back in api_params
  def simple_processor(help_func,valid_args,args,user_vars,*options)
    debug(7,args,"default argument processor")

    args=substitute_vars(args)
    args=params_to_hash(args)

    {:api_params=>args, :show_params=>{}}
  end

  # This is the default processor for get commands.  It adds "limit" and "extendoutput" as needed
  def default_get_processor(help_func, valid_args, args, user_vars, *options)
    debug(7,args,"default get helper")

    # let the default processor set things up
    retval=default_processor(help_func,valid_args,args,user_vars,options)

    if retval[:api_params]["limit"].nil?
      retval[:api_params]["limit"]=100
    end
    if retval[:api_params]["show"].nil?
      retval[:api_params]["extendoutput"]=true
    end

      retval
  end

  #Helper function to ensure the proper hash is returned
  def return_helper(parameters,show_parameters=nil)
    {:api_params=>parameters, :show_params=>show_parameters}
  end

  # Helper function the check for required parameters.
  # Parameters is the hash of parameters from the user
  # required_parameters is an array of parameters which are required
  # returns an array of missing required items
  # if the returned array is empty all required items found
  def check_required(parameters,required_parameters)
    r_params=required_parameters.clone    # Arrays are pass by reference
    parameters.keys.each{|key| r_params.delete(key)}
    r_params
  end

  # Helper function to check the validity of the parameters from the user
  # Parameters is the hash of parameters from the user
  # valid_parameters is an array of parameters which are valid
  # returns an array of invalid parameters
  # if the returned array is empty all parameters are valid
  def check_parameters(parameters,valid_parameters)
    if !valid_parameters.nil?
      keys=parameters.keys
      valid_parameters.each {|key| keys.delete(key)}
      return keys
    else
      return []
    end
  end

  # hash_processor is a helper function which takes the incoming arguments
  # and chunks them into a hash of pairs
  # example:
  # input:  one two three four
  # result:  "one"=>"two", "three"=>"four"
  # Exception will be raised when error found
  # processor does not do variable substitution
  # TODO: Consider removing function as it appears not be used
  def hash_processor(help_func,valid_args,args,user_vars,*options)
    debug(6,args,"Args")
    debug(6,options,"Options")
    items=safe_split(args)
    if items.count % 2 == 0
      rethash={}
      while items.count!=0
        rethash[items[0]]=items[1]
        items.delete_at(0)
        items.delete_at(0)   #make sure we delete the first two items
      end
      return_helper(rethash)
    else
      msg="Invalid input\n"
      msg+="Odd number of arguments found"
      raise ParameterError.new(msg,:retry=>true)
    end
  end

  # array_process is a helper function which takes the incoming arguments
  # and puts them into an array and returns that result.
  # empty input results in an empty array
  # does not perform variable substitution
  def array_processor(help_func,valid_args,args,user_vars,*options)

    return_helper(safe_split(args))
  end

  ##############################################################################################
  # End of default and helper functions
  ##############################################################################################

  def add_user(help_func,valid_args,args, user_vars, *options)
    debug(4,args,"args")

    if args.empty?
      call_help(help_func)
      raise ParameterError.new("No arguments",:retry=>true, :help_func=>help_func)
    end

    valid_parameters=['name', 'surname', 'alias', 'passwd', 'url', 'autologin',
                      'autologout', 'lang', 'theme', 'refresh', 'rows_per_page', 'type']
    default_processor(help_func,valid_parameters,args,user_vars,options)
  end

  def add_host(help_func,valid_args,args,user_vars,*options)
    debug(4,args,"args")
    debug(4,options,"options")

    if args.empty?
      call_help(help_func)
      return nil
    end

    #TODO, add the ability for both groups and groupids

    valid_parameters=['host', 'groupids', 'port', 'status', 'useip', 'dns', 'ip',
                       'proxy_hostid', 'useipmi', 'ipmi_ip', 'ipmi_port', 'ipmi_authtype',
                       'ipmi_privilege', 'ipmi_username', 'ipmi_password']

    parameters=default_processor(help_func,valid_parameters,args,user_vars,options)[:api_params]

    required_parameters=[ 'host', 'groupids' ]

#    p required_parameters
#    p parameters

#    if !parameters["dns"].nil? and !required_parameters.find("ip")
#      required_parameters.delete("ip")
#    elsif !parameters["ip"].nil? and !required_parameters["dns"]
#      required_parameters.delete("dns")
#    end

    if !(missing=check_required(parameters,required_parameters)).empty?
#      if !required_parameters["ip"].nil? and !required_parameters["dns"].nil?
#        puts "Missing parameter dns and/or ip"
#        required_parameters["ip"].delete
#        required_parameters["dns"].delete
#      end
      msg = "Required parameters missing\n"
      msg += missing.join(", ")

      raise ParameterError_Missing.new(msg,:retry=>true, :help_func=>help_func)
    end

    groups=convert_or_parse(parameters['groupids'])
    if groups.class==Fixnum
      parameters['groups']=[{"groupid"=>groups}]
    end

    return_helper(parameters)
  end

  def add_item_active(help_func,parameters,*options)
    valid_parameters = ['hostid','description','key','delta','history','multiplier','value_type', 'data_type',
                         'units','delay','trends','status','valuemapid','applications']
    required_parameters = ['hostid','description','key']
  end

  def add_item(help_func,valid_args,args,user_vars,*options)
    debug(4,args,"args")
    debug(4,options,"options")
    debug(4,user_vars,"User Variables")

    if args.empty?
      call_help(help_func)
      return nil
    end

    #  Item types
    #  0 Zabbix agent                  - Passive
    #  1 SNMPv1 agent                - SNMP
    #  2 Zabbix trapper                - Trapper
    #  3 Simple check                   - Simple
    #  4 SNMPv2 agent                - SNMP2
    #  5 Zabbix internal               - Internal
    #  6 SNMPv3 agent                - SNMP3
    #  7 Zabbix agent (active)    - Active
    #  8 Zabbix aggregate          - Aggregate
    # 10 External check               - External
    # 11 Database monitor         - Database
    # 12 IPMI agent                     - IPMI
    # 13 SSH agent                      - SSH
    # 14 TELNET agent                - Telnet
    # 15 Calculated                      - Calculated

    #value types
    # 0 Numeric (float)
    # 1 Character
    # 2 Log
    # 3 Numeric (unsigned)
    # 4 Text

    # Data Types
    # 0 Decimal
    # 1 Octal
    # 2 Hexadecimal

    # Status Types
    # 0 Active
    # 1 Disabled
    # 2 Not Supported

    # Delta Types
    # 0 As is
    # 1 Delta (Speed per second)
    # 2 Delta (simple change)


    valid_parameters= ['hostid', 'snmpv3_securitylevel','snmp_community', 'publickey', 'delta', 'history', 'key_',
                        'key', 'snmp_oid', 'delay_flex', 'multiplier', 'delay', 'mtime', 'username', 'authtype',
                        'data_type', 'ipmi_sensor','snmpv3_authpassphrase', 'prevorgvalue', 'units', 'trends',
                        'snmp_port', 'formula', 'type', 'params', 'logtimefmt', 'snmpv3_securityname',
                        'trapper_hosts', 'description', 'password', 'snmpv3_privpassphrase',
                        'status', 'privatekey', 'valuemapid', 'templateid', 'value_type', 'groups']

    parameters=default_processor(help_func,valid_parameters,args,user_vars,options)[:api_params]

#    valid_user_vars = {}
#
#    valid_parameters.each {|item|
#      valid_user_vars[item]=user_vars[item] if !user_vars[item].nil?
#    }
#    p parameters
#    p valid_user_vars
#    parameters = valid_user_vars.merge(parameters)
#    p parameters
    
    required_parameters=[ 'type' ]

    if parameters["type"].nil?
      puts "Missing required parameter 'type'"
      return nil
    end

    if !(invalid=check_parameters(parameters,valid_parameters)).empty?
      puts "Invalid items"
      puts invalid.join(", ")
      return nil
    end

    case parameters["type"].downcase
      when "passive"
        parameters["type"]=0
        required_parameters = ['hostid','description','key']
      when "active"
        parameters["type"]=7
        required_parameters = ['hostid','description','key']
      when "trapper"
        parameters["type"]=2
        required_parameters = ['hostid','description','key']
    end

    if !(missing=check_required(parameters,required_parameters)).empty?
      puts "Required parameters missing"

      puts missing.join(", ")

      return nil
    end

    # perform some translations

    parameters["key_"]=parameters["key"]
    parameters.delete("key")

    return_helper(parameters)
 end


  def delete_host(help_func,valid_args,args,user_vars,*options)
    debug(6,args,"args")

    args=default_processor(help_func,valid_args,args,user_vars,options)[:api_params]

    if args["id"].nil?
      puts "Missing parameter \"id\""
      call_help(help_func)
      return nil
    end

    return_helper(args["id"])
  end

  def delete_user(help_func,valid_args,args,user_vars,*options)
    debug(6,args,"args")
    if (args.split(" ").length>1) or (args.length==0)
      raise ParameterError("Incorrect number of parameters",:retry=>true, :help_func=>help_func)
    end

    args=default_processor(help_func,valid_args,args,user_vars)[:api_params]

    if !args["id"].nil?
      return return_helper(args) if args["id"].class==Fixnum
      puts "\"id\" must be a number"
      call_help(help_func)
      return nil
    end

    puts "Invalid arguments"
    call_help(help_func)
    return nil

  end

  #TODO: Document why this function does not use the default processor
  def get_group_id(help_func,valid_args,args,user_vars,*options)
    debug(4,valid_args,"valid_args")
    debug(4,args,"args")

    args=substitute_vars(args)
    args=params_to_hash(args)

    {:api_params=>args.keys, :show_params=>nil}
  end

  def get_user(help_func,valid_args,args,user_vars,*options)
    debug(4,valid_args,"valid_args")
    debug(4,args, "args")

    retval=default_get_processor(help_func,valid_args,args,user_vars)
    error=false
    msg=''

    if !retval[:show_params][:show].nil?
      show_options=retval[:show_params][:show]
      if !show_options.include?("all")
        valid_show_options=['name','attempt_clock','theme','autologout','autologin','url','rows_per_page','attempt_ip',
                            'refresh','attempt_failed','type','userid','lang','alias','surname','passwd']

        invalid_show_options=show_options-valid_show_options

        if invalid_show_options.length!=0
          error=true
          msg = "Invalid show options: #{invalid_show_options}"
        end
      elsif show_options.length!=1
        error=true
        msg = "Show header option \"all\" cannot be included with other headers"
      end
    end
#    raise ParameterError(msg,help_func) if error

    return retval
  end

  #TODO: Use helper functions to make login more robust
  def login(help_func,valid_args,args,user_vars,*options)
    debug(4,args, "args")
    args=args.split
    if args.length!=3
      call_help(help_func)
      return nil
    end
    params={}
    params[:server]=args[0]
    params[:username]=args[1]
    params[:password]=args[2]
    return {:api_params=>params}
  end

  def raw_api(help_func,valid_args,args,user_vars,*options)
    debug(7,args,"raw_api argument processor")

    args=substitute_vars(args)

    items=safe_split(args)
    method=items[0]
    items.delete_at(0)
    args=items.join(" ")
    args=params_to_hash(args)
    args=nil if args=={}

    {:api_params=>{:method=>method, :params=>args}, :show_params=>{}}
  end

end


if __FILE__ == $0
  include ZDebug
  set_debug_level(1)
  arg_processor=ArgumentProcessor.new
  p arg="This is an argument"
  p arg_processor.params_to_hash(arg)

  p arg='"this is another argument" and some words'
  p arg_processor.params_to_hash(arg)

  p arg='"this is a quote \" now we close it" closed'
  p arg_processor.params_to_hash(arg)
  
  p arg='item=2 second=item third="this is a short sentence"'
  p arg_processor.params_to_hash(arg)

  p arg='blank=""'
  p arg_processor.params_to_hash(arg)
end







