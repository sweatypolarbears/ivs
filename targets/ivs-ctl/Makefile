################################################################
#
#        Copyright 2013, Big Switch Networks, Inc.
#
# Licensed under the Eclipse Public License, Version 1.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#        http://www.eclipse.org/legal/epl-v10.html
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the
# License.
#
################################################################
include ../../init.mk

ALLOW_DECLARATION_AFTER_STATEMENT = 1

MODULE := IVSCtl
include $(BUILDER)/standardinit.mk

LIBRARY := IVSCtlMain
$(LIBRARY)_SUBDIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(BUILDER)/lib.mk

DEPENDMODULES :=
include $(BUILDER)/dependmodules.mk

BINARY := ivs-ctl

$(BINARY)_LIBRARIES := $(LIBRARY_TARGETS)
include $(BUILDER)/bin.mk

include $(BUILDER)/targets.mk

GLOBAL_CFLAGS += -g
GLOBAL_CFLAGS += -I .
GLOBAL_CFLAGS += -I $(ROOT)/openvswitch
GLOBAL_CFLAGS += -O1

LIBNL_CFLAGS := $(shell pkg-config --cflags libnl-3.0)
LIBNL_CFLAGS += $(shell pkg-config --cflags --silence-errors libnl-genl-3.0)
LIBNL_LIBS := $(shell pkg-config --libs libnl-3.0)
LIBNL_LIBS += $(shell pkg-config --libs --silence-errors libnl-genl-3.0)
GLOBAL_CFLAGS += $(LIBNL_CFLAGS)
GLOBAL_LINK_LIBS += $(LIBNL_LIBS)
