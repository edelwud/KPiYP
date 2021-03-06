# INCOMING
FILENAMES=MAIN

WORK_FOLDER=D:\Dev\TASM
MAKEFILE_PATH=$(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_FOLDER=$(patsubst %/,%,$(dir $(MAKEFILE_PATH)))
DIST_FOLDER=dist
DATA_FOLDER=data
DEBUG_FOLDER=debug

INPUT_FILE=$(DATA_FOLDER)/INPUT.TXT
OUTPUT_FILE=$(DATA_FOLDER)/OUTPUT.TXT
STARTUP_FILE=$(DATA_FOLDER)/STARTUP.TXT

COMPILE_LOG_FILE=$(DEBUG_FOLDER)/COMPILE.TXT
LINK_LOG_FILE=$(DEBUG_FOLDER)/LINK.TXT

DISK_COMPILATOR_NAME=C
DISK_EXECUTABLE_NAME=D
CMD_INTERFACE=-c

# PARSING FILES
ASSEMBLY = $(foreach filename,$(FILENAMES),$(filename).ASM)
OBJECTS = $(foreach filename,$(FILENAMES),$(filename).OBJ)
EXECUTABLE = $(foreach filename,$(FILENAMES),$(filename).EXE)

# CMD INTERFACE
CMD = $(CMD_INTERFACE) $(1) 

MOVE_CMD = $(call CMD,"copy $(1) $(2)") \
$(call CMD, "del $(1)")

all: program build execute

program:
	dosbox \
	$(call CMD,"mount $(DISK_COMPILATOR_NAME) $(WORK_FOLDER)") \
	$(call CMD,"mount $(DISK_EXECUTABLE_NAME) $(CURRENT_FOLDER)") \
	$(call CMD,"$(DISK_EXECUTABLE_NAME):") \
	$(call CMD,"$(DISK_COMPILATOR_NAME):\TASM.EXE program.asm > $(DEBUG_FOLDER)/c_program.txt") \
	$(call CMD,"$(DISK_COMPILATOR_NAME):\TLINK.EXE program.obj > $(DEBUG_FOLDER)/l_program.txt") \
	$(call MOVE_CMD,program.obj,$(DIST_FOLDER)) \
	$(call MOVE_CMD,program.exe,$(DIST_FOLDER)) \
	$(call CMD,"exit")
	
build:
	dosbox \
	$(call CMD,"mount $(DISK_COMPILATOR_NAME) $(WORK_FOLDER)") \
	$(call CMD,"mount $(DISK_EXECUTABLE_NAME) $(CURRENT_FOLDER)") \
	$(call CMD,"$(DISK_EXECUTABLE_NAME):") \
	$(call CMD,"$(DISK_COMPILATOR_NAME):\TASM.EXE $(ASSEMBLY) > $(COMPILE_LOG_FILE)") \
	$(call CMD,"$(DISK_COMPILATOR_NAME):\TLINK.EXE $(OBJECTS) > $(LINK_LOG_FILE)") \
	$(call MOVE_CMD,$(OBJECTS),$(DIST_FOLDER)) \
	$(call MOVE_CMD,$(EXECUTABLE),$(DIST_FOLDER)) \
	$(call CMD,"exit")

execute:
	dosbox \
	$(call CMD,"mount $(DISK_EXECUTABLE_NAME) $(CURRENT_FOLDER)") \
	$(call CMD,"$(DISK_EXECUTABLE_NAME):") \
	$(call CMD,"cls") \
	$(call CMD,"$(DIST_FOLDER)\$(EXECUTABLE) n5")
	# $(call CMD,"exit")
	
deb: build
	dosbox \
	$(call CMD,"mount $(DISK_COMPILATOR_NAME) $(WORK_FOLDER)") \
	$(call CMD,"mount $(DISK_EXECUTABLE_NAME) $(CURRENT_FOLDER)") \
	$(call CMD,"$(DISK_EXECUTABLE_NAME):") \
	$(call CMD,"$(DISK_COMPILATOR_NAME):\td.EXE $(DIST_FOLDER)\$(EXECUTABLE) d:\file.txt")