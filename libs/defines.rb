#!/usr/bin/ruby

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

# Zabbix constants

# Sysmap elements (Create Element Type drop down menu):
ME_HOST=0
ME_MAP=1
ME_TRIGGER=2
ME_HOSTGROUP=3
ME_IMAGE=4

# Sysmap connection draw type
MC_DT_LINE=1
MC_DT_BOLD=2
MC_DT_DOT=3
MC_DT_DASHED=4

# Sysmap label location
ML_BOTTOM=0
ML_LEFT=1
ML_RIGHT=2
ML_TOP=3
