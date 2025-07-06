.PHONY: lint clean install-hooks test

# QML linting
lint:
	@echo "Running qmllint on all QML files..."
	@find . -name "*.qml" -exec qmllint {} \;
	@echo "✅ All QML files pass linting!"

# Clean whitespace and extra spaces
clean:
	@echo "Cleaning whitespace from files..."
	@find . -name "*.qml" -o -name "*.js" -o -name "*.json" -o -name "*.md" | xargs sed -i 's/[[:space:]]\+$$//'
	@echo "✅ Whitespace cleaned!"

# Install git hooks
install-hooks:
	@echo "Installing pre-commit hooks..."
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit install; \
		echo "✅ Pre-commit hooks installed!"; \
	else \
		echo "❌ pre-commit not found. Install with: pip install pre-commit"; \
	fi

# Run pre-commit on all files
pre-commit:
	@echo "Running pre-commit on all files..."
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "❌ pre-commit not found. Running manual checks..."; \
		make lint; \
		make clean; \
	fi

# Test the plasmoid
test:
	@echo "Testing plasmoid..."
	@plasmoidviewer -a . --formfactor desktop

# Development setup
setup: install-hooks
	@echo "🚀 Development environment ready!"
	@echo "Available commands:"
	@echo "  make lint       - Run qmllint"
	@echo "  make clean      - Clean whitespace"
	@echo "  make pre-commit - Run all checks"
	@echo "  make test       - Test plasmoid"

help:
	@echo "KGitHub Plasmoid Development Commands:"
	@echo ""
	@echo "  make lint       - Run qmllint on all QML files"
	@echo "  make clean      - Remove trailing whitespace and extra spaces"
	@echo "  make pre-commit - Run all pre-commit checks"
	@echo "  make test       - Test plasmoid with plasmoidviewer"
	@echo "  make setup      - Set up development environment"
	@echo "  make help       - Show this help message"
