ROOT       = $(CURDIR)
RTL_DIR    = ${ROOT}/Hardware_Implementation

FLAGS += -access +rwc
ifeq ($(GUI),1)
	FLAGS += -gui
endif


Top:
	cd ${ROOT}/Hardware_Implementation/work && \
	xrun -v2001 -v93 ${RTL_DIR}/modem_tb.sv $(FLAGS); \
