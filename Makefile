NAME = sdk-webapp
PREFIX = /usr
BINDIR = $(PREFIX)/bin
TARGET = $(PREFIX)/lib/$(NAME)-bundle

SRC = config.ru sdk_helper.rb public views

all:
	@echo "No build needed"

install: 
	@echo "Installing...";
	mkdir -p $(DESTDIR)$(TARGET)
	cp -r $(SRC) $(DESTDIR)$(TARGET)

.PHONY: all install
