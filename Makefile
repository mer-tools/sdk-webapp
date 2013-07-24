NAME = sdk-webapp
PREFIX = /usr
BINDIR = $(PREFIX)/bin
TARGET = $(PREFIX)/lib/$(NAME)-bundle

APPLICATION = config.ru *.rb views/*.haml views/default.sass i18n/* public/css public/ttf public/*js
CUSTOMIZATION = views/index.sass public/images
all:
	@echo "No build needed"

install:
	@echo "Installing application...";
	mkdir -p $(DESTDIR)$(TARGET)
	cp -r --parents $(APPLICATION) $(DESTDIR)$(TARGET)
	cp -r --parents $(CUSTOMIZATION) $(DESTDIR)$(TARGET)
	mkdir -p $(DESTDIR)$(TARGET)/.sass-cache/
	mkdir -p $(DESTDIR)/etc/mersdk
	cp providers.json $(DESTDIR)/etc/mersdk/providers.json

.PHONY: all install
