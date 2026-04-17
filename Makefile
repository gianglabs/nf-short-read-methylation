.PHONY: test-e2e clean lint

${HOME}/.pixi/bin/pixi:
	curl -sSL https://pixi.sh/install.sh | sh

# snapshot
# nf-test snapshot tests
test-e2e: test-bismark-snapshot test-rastair-snapshot
	echo "Execute entrypoint of test-fastq-snapshot"

test-rastair-snapshot:
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test \
		tests/rastair.nf.test \
		--verbose \
		--profile docker,rastair

test-rastair-update-snapshot:
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test \
		tests/rastair.nf.test \
		--verbose \
		--update-snapshot \
		--profile docker,rastair

# nf-test snapshot tests
test-bismark-snapshot: ${HOME}/.pixi/bin/pixi
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test \
			tests/bismark.nf.test \
			--verbose \
			--profile docker,bismark

# Update nf-test snapshots
test-bismark-update-snapshot: ${HOME}/.pixi/bin/pixi
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test \
			tests/bismark.nf.test \
			--verbose \
			--update-snapshot \
			--profile docker,bismark

test-bismark: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		-profile docker,bismark \
		-resume

test-rastair: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		-profile docker,rastair \
		-resume
# Lint
lint: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow lint $(shell find . -name "*.nf" \
		-not -path "./.pixi/*" \
		-not -path "./.nextflow/*" \
		-not -path "./work/*" \
		-not -path "./results/*") -format

# Clean
clean:
	rm -rf work results .nextflow* *.log
