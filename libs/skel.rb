#License:: GPL 2.0  http://www.gnu.org/licenses/gpl-2.0.html
#Copyright:: Copyright (C) 2009,2010 Andrew Nelson nelsonab(at)red-tux(dot)net
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
# $Id: $
# $Revision: $
##########################################

#
#Remove this note section when using in a normal file
#
# This is a skeleton file, use this file to create any new files.
# This file has the default GNU header and copyright, SVN tags
# and default lib file path creation helper.
#
# To use copy this file to the desired new file name
# Add the file to svn (svn add <filename>
# Set the properties for svn:
#  svn propset svn:keywords Id <filename>
#  svn propset svn:keywords Revision <filename>
#
#Remove this note section when using in a normal file
#


#setup our search path or libraries
path=File.expand_path(File.dirname(__FILE__) + "/../libs")+"/"

require path+"zdebug"
