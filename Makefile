.PHONY : build clean cluster deploy destroy doc run

all:
	deploy

clean:
	find ./src -name '*.py[co]' -exec rm {} \;
	find ./src -name '__pycache__' -exec rm -rf {} \;
	rm -rf dist
	rm -rf ./data/bronze
	rm -rf ./data/landing/log_data
	rm -rf ./data/landing/song_data
	rm -rf ./data/silver

unzip:
	unzip -qq ./data/landing/log_data.zip -d ./data/landing
	unzip -qq ./data/landing/song_data.zip -d ./data/landing

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

docker-compose: build
	docker-compose --project-directory='./docker' up --scale spark-worker=2 -d

run: clean unzip
	python -m src.driver main --local