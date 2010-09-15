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

#if __FILE__ == $0  #if we're executing the file we're in the same directory'
#  dir=''
#else
#  dir='libs/'
#end

#setup our search path or libraries
path=File.expand_path(File.dirname(__FILE__) + "/../libs")+"/"

require path+'zdebug'
require path+'zabcon_exceptions'

class Parser

  include ZDebug

  attr_reader :commands

  def initialize(default_argument_processor)
    @commands=CommandTree.new("",nil,0,nil,nil,nil,nil)
    @default_argument_processor=default_argument_processor
  end

  def strip_comments(str)
    str.lstrip!
    str.chomp!
    if str =~ /^ ## .*/ then
      str = ""
    elsif str =~ /(.+) ## .*/ then
      str = Regexp.last_match(1)
    else
      str
    end
  end

  def search(str)
    debug(7,str,"Searching")

    str=strip_comments(str)

    nodes = [""]+str.split

    cmd_node=@commands.search(nodes)  # a side effect of the function is that it also manipulates nodes
    debug(7,cmd_node,"search result")
    args=nodes.join(" ")

    return cmd_node,args

  end


  # Returns nil if the command is incomplete or unknown
  # If the command is known the associated argument processor is also called and it's results are returned as part
  # of the return hash
  # the return hash consists of:
  # :proc - the name of the procedure which will execute the associated command
  # :api_params - parameters to pass to the API call
  # :show_params - parameters to pass to the print routines
  # :helpproc - help procedure associated with the command
  # The argument processor function is passed a string of the arguments after the command, along with the
  # array of valid arguments and the help function associated with the command.
  # If the argument processor has an error it should call the help function and return nil.  In which case this function
  # will return nil
  def parse(str,user_vars=nil)
    debug(7,str,"Parsing")
#    options=
    debug(7,user_vars,"User Variables")
    cmd_node,args=search(str)

    if cmd_node.commandproc.nil? then
      raise ParseError.new("Parse error, incomplete/unknown command: #{str}",:retry=>true)
    else
      # The call here to the argument process requires one argument as it's a lambda block which is setup when the
      # command node is created
      debug(6,args,"calling argument processor")
      args=cmd_node.argument_processor.call(args,user_vars)
      debug(6,args,"received from argument processor")
      retval = args.nil? ? nil : {:proc=>cmd_node.commandproc, :helpproc=>cmd_node.helpproc, :options=>cmd_node.options}.merge(args)
      return retval
    end
  end

  def complete(str,loggedin=false)
    nodes = str.split
    cmd_node=@commands
    i=0
    while i<nodes.length
      tmp=cmd_node.search(nodes[i])
      break if tmp.nil?
      cmd_node=tmp
      i+=1
    end

    if cmd_node.commandproc.nil? then
      # roll up the list of available commands.
      commands = cmd_node.children.collect {|node| node.command}

      # don't include the current node if the command is empty
      if cmd_node.command!="" then commands += [cmd_node.command] end
      return commands
    else
      puts "complete"
      return nil
    end
  end

  def insert(insert_path,command,commandproc,arguments=[],helpproc=nil,argument_processor=nil,*options)
    debug(10,{"insert_path"=>insert_path, "command"=>command, "commandproc"=>commandproc, "arguments"=> arguments, "helpproc"=>helpproc, "argument_processor"=>argument_processor, "options"=>options})
   insert_path_arr=[""]+insert_path.split   # we must pre-load our array with a blank node at the front
#    p insert_path_arr

    # If the parameter "argument_processor" is nil use the default argument processor
    arg_processor = argument_processor.nil? ? @default_argument_processor : argument_processor
    @commands.insert(insert_path_arr,command,commandproc,arguments,helpproc,arg_processor,options)
  end

end


class CommandTree

  include ZDebug

  attr_reader :command, :commandproc, :children, :arguments, :helpproc, :depth, :argument_processor, :options

  # Arguments hash takes the form of {"name"=>{:type=>Class, :optional=>true/false}}
  # If type is nil then the argument takes no options
  def initialize(command,commandproc,depth,arguments,helpproc,argument_processor,options)
    debug(10,{"command"=>command, "commandproc"=>commandproc, "arguments"=> arguments,"helpproc"=>helpproc,
              "verify_func"=>argument_processor, "depth"=>depth, "options"=>options})
    @command=command
    @commandproc=commandproc
    @children=[]
    @arguments=arguments
    @helpproc=helpproc
    @depth=depth
    # verify functions are special.
    # We pass them the list of valid arguments first and then the parameters which need to be verified
    # This will allow for either unique or generalized verification functions
    # The verify function can safely be called with objects with no verify function as nil checking is performed in the
    # lambda
    # If no verify function was setup we return true
    @argument_processor=lambda do |params,user_vars|
      if argument_processor.nil?
        nil
      else
        argument_processor.call(@helpproc,@arguments,params,user_vars,options)  # We pass the list of valid arguments to
      end
    end
    if options.nil?
      @options=nil
    else
      @options = Hash[*options.collect { |v|
        [v, true]
      }.flatten]
    end
    debug(10,self.inspect,"Initialization complete")
  end

  def inspect
    r_str ="#<#{self.class.to_s}:0x#{self.object_id.to_s(16)} @command=#{@command.inspect}, @commandproc=#{@commandproc.inspect}, "
    r_str+="@helpproc=#{@helpproc.inspect}, @argument_processor=#{@argument_processor.inspect}, @arguments=#{@arguments.inspect}, "
    r_str+="@options=#{@options.inspect}, "
    r_str+="@depth=#{@depth}, @children="
    if @children.empty?
      r_str+= "[]"
    else
      children=@children.map {|child| child.command }
      r_str+= children.inspect
    end
    r_str+=">"
    r_str
  end

  # search will search check to see if the parameter command is found in the current node
  # or the immediate children nodes.  It does not search the tree beyond one level.
  # The loggedin argument is used to differentiate searching for commands which require a valid
  # login or not.  If loggedin is false it will return commands which do not require a valid login.
  def search(search_path)
    debug(10,search_path,"search_path")
    debug(10,self,"self",300)

    return nil if search_path.nil?
    return nil if search_path.empty?

    retval=nil

    retval=self if search_path[0]==@command


    search_path.shift
    debug(10,search_path, "shifted search path")

    return retval if search_path.length==0

#    p search_path
#    p @children.map {|child| child.command}
    debug(10,@children.map{|child| child.command},"Current children")

    results=@children.map {|child| child.command==search_path[0] ? child : nil }
    results.compact!
    debug(10,results,"Children search results",200)
    return retval if results.empty?  # no more children to search, return retval which may be self or nil, see logic above
    debug(10)

    return results[0].search(search_path)
    debug(10,"Not digging deeper")

    return self if search_path[0]==@command

  end

  def insert(insert_path,command,commandproc,arguments,helpproc,argument_processor,options)
    do_insert(insert_path,command,commandproc,arguments,helpproc,argument_processor,options,0)
  end

  # Insert path is the path to insert the item into the tree
  # Insert path is passed in as an array of names which associate with pre-existing nodes
  # The function will recursively insert the command and will remove the top of the input path stack at each level until it
  # finds the appropraite level.  If the appropriate level is never found an exception is raised.
  def do_insert(insert_path,command,commandproc,arguments,helpproc,argument_processor,options,depth)
    debug(11,{"insert_path"=>insert_path, "command"=>command, "commandproc"=>commandproc, "arguments"=> arguments,
              "helpproc"=>helpproc, "verify_func"=>argument_processor, "depth"=>depth})
    debug(11,@command,"self.command")
#    debug(11,@children.map {|child| child.command},"children")

    if insert_path[0]==@command then
      debug(11,"Found node")
      if insert_path.length==1 then
        debug(11,command,"inserting")
        @children << CommandTree.new(command,commandproc,depth+1,arguments,helpproc,argument_processor,options)
      else
        debug(11,"Not found walking tree")
        insert_path.shift
        if !@children.empty? then
          @children.each { |node| node.do_insert(insert_path,command,commandproc,arguments,helpproc,argument_processor,options,depth+1)}
        else
          raise Command_Tree_Exception "Unable to find insert point in Command Tree"
        end
      end
    end
  end

end


if __FILE__ == $0

  require 'pp'
  require 'argument_processor'

  arg_processor=ArgumentProcessor.new()
  commands=Parser.new(arg_processoor.method(:default))
  commands.set_debug_level(6)


  def test_parse(cmd)
    puts "\ntesting \"#{cmd}\""
    retval=commands.parse(cmd)
    puts "result:"
    return retval
  end
  commands.set_debug_level(0)
  commands.insert "", "help", lambda { puts "This  is a generic help stub" }
  puts
  commands.insert "", "get", nil
  puts
  commands.insert "get", "host", :gethost, {"show"=>{:type=>nil,:optional=>true}}
  commands.set_debug_level(0)
  puts
  commands.insert "get", "user", :getuser
  puts
  commands.insert "get user", "group", :getusergroup
  puts

  pp commands

  commands.set_debug_level(0)

  test_parse("get user")
  test_parse("get user show=all arg1 arg2")
  test_parse("get user show=\"id, one, two, three\" arg1 arg2")
  test_parse("get user group show=all arg1")
  test_parse("set value")
  test_parse("help")[:proc].call


  p commands.complete("hel")
  p commands.complete("help")
  p commands.complete("get user all")

end
