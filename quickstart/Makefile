re: clean run

run: keys
	bash run.sh
	docker stop pcs
	bash launch-pcs.sh

keys:
	bash create-keys.sh

check:
	bash check.sh

test:
	bash test-request-on-smd.sh

clean: stop
	bash clean.sh

stop:
	bash stop.sh
