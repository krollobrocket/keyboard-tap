build: keytap.m
	gcc -framework Cocoa -framework Foundation -framework CoreGraphics keytap.m -o keytap

clean:
	unlink keytap
