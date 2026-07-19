.PHONY: build test app dmg clean

build:
	swift build

test:
	swift test

app:
	./scripts/build-app.sh

dmg:
	./scripts/package-dmg.sh

clean:
	swift package clean
	rm -rf dist
