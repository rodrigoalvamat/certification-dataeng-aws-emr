.PHONY : build clean deploy develop destroy doc

all:
	develop

clean:
	find ./src -name '*.py[co]' -exec rm {} \;
	find ./src -name '__pycache__' -exec rm -rf {} \;
	rm -rf dist

build: clean
	mkdir dist
	poetry build
	cp ./src/driver.py ./dist/

deploy: build
	terraform -chdir='./terraform' apply

doc:
	sphinx-build -M html ./docs/source ./docs/build

destroy:
	terraform -chdir='./terraform' destroy

develop: build
	docker-compose --project-directory='./docker' up --scale spark-worker=3 -d