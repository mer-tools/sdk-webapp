NAME = sdk-webapp
PREFIX = /usr
BINDIR = $(PREFIX)/bin
TARGET = $(PREFIX)/lib/$(NAME)-bundle

APPLICATION = config.ru sdk_helper.rb shell_process.rb views/index.haml views/targets.haml views/toolchains.haml views/default.sass views/layout.haml views/packages.haml i18n/* public/css public/ttf
CUSTOMIZATION = target_servers.rb views/index.sass public/images
all:
	@echo "No build needed"

install:
	@echo "Installing application...";
	mkdir -p $(DESTDIR)$(TARGET)
	cp -r --parents $(APPLICATION) $(DESTDIR)$(TARGET)
	cp -r --parents $(CUSTOMIZATION) $(DESTDIR)$(TARGET)

.PHONY: all install
