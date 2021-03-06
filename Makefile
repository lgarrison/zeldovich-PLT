# touch a FREEZE file to prevent the Makefile from doing anything
# Useful for mixed architecture platforms like Summit and Rhea
FREEZE := $(wildcard FREEZE)

ifneq (,$(FREEZE))
all:
else

# Load Abacus's make settings if available
ROOT_DIR := $(ABACUS)
-include $(ROOT_DIR)/common.mk

CXX ?= g++
# Set DISK if you want to run the big BlockArray explicitly out of core.
# Set -DDIRECTIO and -I../Convolution if you want to use lib_dio
CXXFLAGS ?= -O3 -g -fopenmp -march=native -std=c++11
CXXFLAGS += -Wall
PARSEHEADER_CPPFLAGS ?= -I ParseHeader
PARSEHEADER_LIBS ?= -L ParseHeader -lparseheader

GSL_LIBS ?= $(shell gsl-config --libs)
GSL_CPPFLAGS ?= $(shell gsl-config --cflags)

CPPFLAGS += $(THREAD_CPPFLAGS) $(PARSEHEADER_CPPFLAGS) $(GSL_CPPFLAGS) -DDISK

LIBS += $(PARSEHEADER_LIBS) -lfftw3 $(GSL_LIBS) -lstdc++

TARGETS := zeldovich zeldovich_part1 zeldovich_part2
OBJ := $(TARGETS:%=%.o)

all: zeldovich 

$(TARGETS) : % : %.o | ParseHeader
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $< -o $@ $(LIBS)

$(OBJ): % : zeldovich.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -MMD -c $< -o $@

twopart: zeldovich_part1 zeldovich_part2

zeldovich_part1: CPPFLAGS += -DPART1
zeldovich_part2: CPPFLAGS += -DPART2

-include zeldovich.d

.PHONY: all clean distclean default twopart
clean:
	$(MAKE) -C ParseHeader $@
	$(RM) $(OBJ) *.gch *~

distclean: clean
	$(MAKE) -C ParseHeader $@
	$(RM) $(TARGETS) *.d

ifndef HAVE_COMMON_MK
ParseHeader: ParseHeader/libparseheader.a
ParseHeader/libparseheader.a:
	$(MAKE) -C ParseHeader libparseheader.a
endif

endif  # freeze
