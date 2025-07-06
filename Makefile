# Variables
PLASMOID_ID := com.github.omarluq.kgithub
PACKAGE_TOOL := kpackagetool6
APPLET_TYPE := Plasma/Applet
QML_FILES := ./contents/**/**/*.qml

.PHONY: lint format clean install-hooks test run package install update uninstall restart-plasma

# Helper functions
define check_command
	@if ! command -v $(1) >/dev/null 2>&1; then \
		echo "❌ $(1) not found. $(2)"; \
		exit 1; \
	fi
endef

define is_installed
	$(PACKAGE_TOOL) --type $(APPLET_TYPE) --show $(PLASMOID_ID) >/dev/null 2>&1
endef

define restart_plasma_prompt
	@read -p "🔄 Would you like to restart Plasma Shell $(1)? (y/N): " answer; \
	if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
		echo "🔄 Restarting Plasma Shell..."; \
		systemctl --user restart plasma-plasmashell.service && \
		echo "✅ Plasma Shell restarted successfully!$(2)"; \
	else \
		echo "ℹ️  $(3)"; \
	fi
endef

# Code Quality
lint:
	@echo "Running qmllint on QML files..."
	@qmllint $(QML_FILES)
	@echo "✅ All QML files pass linting!"

format:
	@echo "Formatting QML files..."
	@qmlformat $(QML_FILES) -i
	@echo "✅ All QML files formatted!"

clean:
	@echo "Cleaning whitespace from files..."
	@find . -name "*.qml" -o -name "*.js" -o -name "*.json" -o -name "*.md" | xargs sed -i 's/[[:space:]]\+$$//'
	@echo "✅ Whitespace cleaned!"

install-hooks:
	@echo "Installing pre-commit hooks..."
	$(call check_command,pre-commit,Install with: pip install pre-commit)
	@pre-commit install
	@echo "✅ Pre-commit hooks installed!"

pre-commit:
	@echo "Running pre-commit on all files..."
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "❌ pre-commit not found. Running manual checks..."; \
		$(MAKE) format lint clean; \
	fi

# Development
test run:
	@echo "$(if $(filter test,$@),Testing,Running) plasmoid..."
	@plasmoidviewer -a . --formfactor desktop

# Packaging
package:
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ VERSION is required. Usage: make package VERSION=1.0.0-alpha"; \
		exit 1; \
	fi
	@echo "📦 Creating plasmoid package v$(VERSION)..."
	@zip -r kgithub-plasmoid-v$(VERSION).plasmoid \
		contents/ metadata.json LICENSE README.md screenshots/ \
		-x "*.git*" "*/.claude/*" "*/node_modules/*" "*/Makefile" "*/package.json" >/dev/null 2>&1
	@echo "✅ Package created: kgithub-plasmoid-v$(VERSION).plasmoid"
	@ls -lh kgithub-plasmoid-v$(VERSION).plasmoid

# Installation Management
install:
	@echo "📦 Installing KGitHub plasmoid..."
	$(call check_command,$(PACKAGE_TOOL),Please install KDE Plasma 6 development tools)
	@if $(call is_installed); then \
		echo "⚠️  Plasmoid already installed. Use 'make update' to upgrade."; \
		echo "💡 Or use 'make uninstall' then 'make install' to reinstall."; \
		exit 1; \
	fi
	@$(PACKAGE_TOOL) --type $(APPLET_TYPE) --install .
	@echo "✅ KGitHub plasmoid installed successfully!"
	@echo ""
	@echo "🎯 Next steps:"
	@echo "  1. Right-click on your desktop or panel"
	@echo "  2. Select 'Add Widgets...'"
	@echo "  3. Search for 'KGitHub'"
	@echo "  4. Drag the widget to your desired location"
	@echo "  5. Configure your GitHub token and username"
	@echo ""
	$(call restart_plasma_prompt,now, ,You can restart Plasma Shell later with: make restart-plasma)

update:
	@echo "🔄 Updating KGitHub plasmoid..."
	$(call check_command,$(PACKAGE_TOOL),Please install KDE Plasma 6 development tools)
	@if ! $(call is_installed); then \
		echo "❌ Plasmoid not currently installed. Use 'make install' first."; \
		exit 1; \
	fi
	@$(PACKAGE_TOOL) --type $(APPLET_TYPE) --upgrade .
	@echo "✅ KGitHub plasmoid updated successfully!"
	@echo ""
	$(call restart_plasma_prompt,to load the new version, The widget will automatically refresh., The widget will refresh automatically\, or restart later with: make restart-plasma)

uninstall:
	@echo "🗑️  Uninstalling KGitHub plasmoid..."
	$(call check_command,$(PACKAGE_TOOL),Please install KDE Plasma 6 development tools)
	@if $(call is_installed); then \
		$(PACKAGE_TOOL) --type $(APPLET_TYPE) --remove $(PLASMOID_ID); \
		echo "✅ KGitHub plasmoid uninstalled successfully!"; \
	else \
		echo "ℹ️  Plasmoid is not currently installed."; \
	fi

restart-plasma:
	@echo "🔄 Restarting Plasma Shell..."
	@systemctl --user restart plasma-plasmashell.service && \
		echo "✅ Plasma Shell restarted successfully!" || \
		echo "❌ Failed to restart Plasma Shell. You may need to log out and back in."

# Development setup
setup: install-hooks
	@echo "🚀 Development environment ready!"
	@echo "Available commands: lint format clean pre-commit test run install update uninstall restart-plasma package"
	@echo "Run 'make help' for detailed descriptions."

help:
	@echo "KGitHub Plasmoid Development Commands:"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint       - Run qmllint on all QML files"
	@echo "  make format     - Format QML files with qmlformat"
	@echo "  make clean      - Remove trailing whitespace and extra spaces"
	@echo "  make pre-commit - Run all pre-commit checks"
	@echo ""
	@echo "Development:"
	@echo "  make test       - Test plasmoid with plasmoidviewer"
	@echo "  make run        - Run plasmoid with plasmoidviewer"
	@echo "  make setup      - Set up development environment"
	@echo ""
	@echo "Installation:"
	@echo "  make install    - Install plasmoid to KDE Plasma 6"
	@echo "  make update     - Update existing plasmoid installation"
	@echo "  make uninstall  - Remove plasmoid from KDE Plasma 6"
	@echo "  make restart-plasma - Restart Plasma Shell"
	@echo ""
	@echo "Packaging:"
	@echo "  make package    - Create plasmoid package (Usage: make package VERSION=1.0.0)"
	@echo ""
	@echo "Other:"
	@echo "  make help       - Show this help message"
