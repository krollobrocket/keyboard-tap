build: keytap.m
	gcc -framework Foundation -framework CoreGraphics keytap.m -o keytap

clean:
	unlink keytap
