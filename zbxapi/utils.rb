#License:: LGPL 2.1   http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
#Copyright:: Copyright (C) 2009,2010 Andrew Nelson nelsonab(at)red-tux(dot)net
#
#This library is free software; you can redistribute it and/or
#modify it under the terms of the GNU Lesser General Public
#License as published by the Free Software Foundation; either
#version 2.1 of the License, or (at your option) any later version.
#
#This library is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#Lesser General Public License for more details.
#
#You should have received a copy of the GNU Lesser General Public
#License along with this library; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

##########################################
# Subversion information
# $Id: utils.rb 337 2011-10-14 16:11:39Z nelsonab $
# $Revision: 337 $
##########################################


class Object
  #self.class_of?
  #Ruby's is_a? or kind_of? will only tell you the hierarchy of classes which
  #have been instantiated.
  def self.class_of?(obj)
    raise RuntimeError.new("Obj must be an uninstantiated class, often calling method \".class\" works") if obj.class!=Class
    return true if self==obj
    if self.superclass.respond_to?(:class_of?)
      self.superclass.class_of?(obj)
    else
      false
    end
  end
end
